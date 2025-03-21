// ****************************************************************************
//
// @file       redis.go
// @brief      与Redis相关的缓存操作
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package cache

import (
	"context"
	"encoding/json"
	"time"

	"github.com/go-redis/redis/v8"
)

const (
	// 缓存键前缀
	NovelListKey      = "novel:list"      // 小说列表
	NovelDetailKey    = "novel:detail:"   // 小说详情
	VolumeListKey     = "novel:volumes:"  // 卷列表
	ChapterListKey    = "novel:chapters:" // 章节列表
	ChapterKey        = "novel:chapter:"  // 章节内容
	SearchKey         = "novel:search:"   // 搜索结果
	LatestNovelsKey   = "novel:latest"    // 最新小说
	PopularNovelsKey  = "novel:popular"   // 热门小说
	ReadingHistoryKey = "user:history:"   // 阅读历史
	DeviceKey         = "device:info:"    // 设备信息
	BookmarkKey       = "user:bookmark:"  // 用户书签
	FavoriteKey       = "user:favorite:"  // 用户收藏
	ReadRecordKey     = "user:record:"    // 阅读记录
	ReadChapterKey    = "user:chapter:"   // 已读章节
	ReadingStatKey    = "user:stat:"      // 阅读统计
)

// RedisCache Redis缓存服务
type RedisCache struct {
	client *redis.Client
}

// NewRedisCache 创建Redis缓存服务
func NewRedisCache(addr, password string, db int) *RedisCache {
	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	})

	return &RedisCache{
		client: client,
	}
}

// Set 设置缓存
func (c *RedisCache) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	return c.client.Set(ctx, key, data, expiration).Err()
}

// Get 获取缓存
func (c *RedisCache) Get(ctx context.Context, key string, dest interface{}) error {
	data, err := c.client.Get(ctx, key).Bytes()
	if err != nil {
		if err == redis.Nil {
			return nil
		}
		return err
	}
	return json.Unmarshal(data, dest)
}

// Delete 删除缓存
func (c *RedisCache) Delete(ctx context.Context, key string) error {
	return c.client.Del(ctx, key).Err()
}

// DeleteByPattern 根据模式删除缓存
func (c *RedisCache) DeleteByPattern(ctx context.Context, pattern string) error {
	iter := c.client.Scan(ctx, 0, pattern, 0).Iterator()
	for iter.Next(ctx) {
		err := c.client.Del(ctx, iter.Val()).Err()
		if err != nil {
			return err
		}
	}
	return iter.Err()
}

// Close 关闭Redis连接
func (c *RedisCache) Close() error {
	return c.client.Close()
}
