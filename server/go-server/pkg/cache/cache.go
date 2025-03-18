package cache

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"time"

	"lightnovel/pkg/concurrency"

	"github.com/allegro/bigcache/v3"
	"github.com/redis/go-redis/v9"
)

// Cache 接口定义缓存操作
type Cache interface {
	Get(ctx context.Context, key string, value interface{}) error
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	Delete(ctx context.Context, key string) error
	DeleteByPattern(ctx context.Context, pattern string) error
	MultiGet(ctx context.Context, keys []string, values []interface{}) error
	MultiSet(ctx context.Context, items map[string]interface{}, expiration time.Duration) error
	Close() error
}

type MultiLevelCache struct {
	local  *bigcache.BigCache
	redis  *redis.Client
	prefix string
}

func NewMultiLevelCache(redisAddr, password string, db int, prefix string) (*MultiLevelCache, error) {
	// 初始化本地缓存
	localCache, err := bigcache.NewBigCache(bigcache.DefaultConfig(10 * time.Minute))
	if err != nil {
		return nil, err
	}

	// 初始化 Redis 客户端
	redisClient := redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: password,
		DB:       db,
	})

	return &MultiLevelCache{
		local:  localCache,
		redis:  redisClient,
		prefix: prefix,
	}, nil
}

func (c *MultiLevelCache) Get(ctx context.Context, key string, value interface{}) error {
	// 先从本地缓存获取
	if data, err := c.local.Get(c.prefix + key); err == nil {
		return json.Unmarshal(data, value)
	}

	// 本地缓存未命中，从 Redis 获取
	data, err := c.redis.Get(ctx, c.prefix+key).Bytes()
	if err != nil {
		return err
	}

	// 写入本地缓存
	jsonData, err := json.Marshal(value)
	if err != nil {
		return err
	}
	if err := c.local.Set(c.prefix+key, jsonData); err != nil {
		return err
	}

	return json.Unmarshal(data, value)
}

func (c *MultiLevelCache) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	// 序列化数据
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}

	// 写入本地缓存
	if err := c.local.Set(c.prefix+key, data); err != nil {
		return err
	}

	// 写入 Redis
	return c.redis.Set(ctx, c.prefix+key, data, expiration).Err()
}

func (c *MultiLevelCache) Delete(ctx context.Context, key string) error {
	// 删除本地缓存
	c.local.Delete(c.prefix + key)

	// 删除 Redis 缓存
	return c.redis.Del(ctx, c.prefix+key).Err()
}

// MultiGet 批量获取缓存
func (c *MultiLevelCache) MultiGet(ctx context.Context, keys []string, values []interface{}) error {
	if len(keys) != len(values) {
		return errors.New("keys and values length mismatch")
	}

	// 创建工作池
	pool := concurrency.NewWorkerPool(10)
	pool.Start(ctx)

	// 提交获取任务
	type getResult struct {
		index int
		data  []byte
		err   error
	}
	results := make(chan getResult, len(keys))

	for i, key := range keys {
		i, key := i, key // 创建副本
		pool.Submit(&cacheTask{
			fn: func(ctx context.Context) error {
				// 先查本地缓存
				if data, err := c.local.Get(c.prefix + key); err == nil {
					results <- getResult{index: i, data: data}
					return nil
				}

				// 查Redis
				data, err := c.redis.Get(ctx, c.prefix+key).Bytes()
				if err != nil && err != redis.Nil {
					results <- getResult{index: i, err: err}
					return nil
				}

				if err == nil {
					// 写入本地缓存
					if err := c.local.Set(c.prefix+key, data); err != nil {
						results <- getResult{index: i, err: err}
						return nil
					}
					results <- getResult{index: i, data: data}
				}
				return nil
			},
		})
	}

	// 收集结果
	go func() {
		pool.Stop()
		close(results)
	}()

	for result := range results {
		if result.err != nil {
			return result.err
		}
		if result.data != nil {
			if err := json.Unmarshal(result.data, values[result.index]); err != nil {
				return err
			}
		}
	}

	return nil
}

// MultiSet 批量设置缓存
func (c *MultiLevelCache) MultiSet(ctx context.Context, items map[string]interface{}, expiration time.Duration) error {
	// 创建工作池
	pool := concurrency.NewWorkerPool(10)
	pool.Start(ctx)

	// 提交设置任务
	errChan := make(chan error, len(items))

	for key, value := range items {
		key, value := key, value // 创建副本
		pool.Submit(&cacheTask{
			fn: func(ctx context.Context) error {
				data, err := json.Marshal(value)
				if err != nil {
					errChan <- err
					return nil
				}

				// 写入本地缓存
				if err := c.local.Set(c.prefix+key, data); err != nil {
					errChan <- err
					return nil
				}

				// 写入 Redis
				if err := c.redis.Set(ctx, c.prefix+key, data, expiration).Err(); err != nil {
					errChan <- err
					return nil
				}
				return nil
			},
		})
	}

	// 等待所有任务完成
	go func() {
		pool.Stop()
		close(errChan)
	}()

	// 检查错误
	for err := range errChan {
		if err != nil {
			return err
		}
	}

	return nil
}

// MultiDelete 批量删除缓存
func (c *MultiLevelCache) MultiDelete(ctx context.Context, keys []string) error {
	prefixedKeys := make([]string, len(keys))

	// 批量删除本地缓存
	for i, key := range keys {
		prefixedKeys[i] = c.prefix + key
		c.local.Delete(c.prefix + key)
	}

	// 批量删除 Redis 缓存
	return c.redis.Del(ctx, prefixedKeys...).Err()
}

// DeleteByPattern 根据模式删除缓存
func (c *MultiLevelCache) DeleteByPattern(ctx context.Context, pattern string) error {
	// 从 Redis 获取匹配的键
	iter := c.redis.Scan(ctx, 0, c.prefix+pattern, 0).Iterator()
	var keys []string

	for iter.Next(ctx) {
		keys = append(keys, iter.Val())
		// 删除本地缓存
		localKey := strings.TrimPrefix(iter.Val(), c.prefix)
		c.local.Delete(c.prefix + localKey)
	}

	if err := iter.Err(); err != nil {
		return err
	}

	// 如果有匹配的键，批量删除
	if len(keys) > 0 {
		return c.redis.Del(ctx, keys...).Err()
	}

	return nil
}

func (c *MultiLevelCache) Close() error {
	if err := c.local.Close(); err != nil {
		return err
	}
	return c.redis.Close()
}

// cacheTask 缓存任务
type cacheTask struct {
	fn func(context.Context) error
}

func (t *cacheTask) Execute(ctx context.Context) error {
	return t.fn(ctx)
}
