package middleware

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
	"golang.org/x/time/rate"
)

// RateLimiter 实现请求频率限制
type RateLimiter struct {
	ips    map[string]*rate.Limiter
	mu     *sync.RWMutex
	r      rate.Limit
	b      int
	redis  *redis.Client
	prefix string

	// 清理相关
	cleanup     time.Duration
	lastCleanup time.Time
}

// RateLimiterOption 配置选项
type RateLimiterOption func(*RateLimiter)

// WithRedis 添加Redis支持
func WithRedis(client *redis.Client, prefix string) RateLimiterOption {
	return func(rl *RateLimiter) {
		rl.redis = client
		rl.prefix = prefix
	}
}

// WithCleanup 设置清理时间
func WithCleanup(d time.Duration) RateLimiterOption {
	return func(rl *RateLimiter) {
		rl.cleanup = d
	}
}

// NewRateLimiter 创建新的限流器
func NewRateLimiter(r rate.Limit, b int, opts ...RateLimiterOption) *RateLimiter {
	rl := &RateLimiter{
		ips:         make(map[string]*rate.Limiter),
		mu:          &sync.RWMutex{},
		r:           r,
		b:           b,
		cleanup:     5 * time.Minute, // 默认5分钟清理一次
		lastCleanup: time.Now(),
	}

	for _, opt := range opts {
		opt(rl)
	}

	return rl
}

// RateLimit 限流中间件
func (rl *RateLimiter) RateLimit() gin.HandlerFunc {
	return func(c *gin.Context) {
		ip := c.ClientIP()

		// 如果配置了Redis，优先使用Redis进行限流
		if rl.redis != nil {
			allowed, err := rl.checkRedisLimit(c.Request.Context(), ip)
			if err != nil {
				// Redis出错时降级到本地限流
				if !rl.checkLocalLimit(ip) {
					c.JSON(429, gin.H{
						"code":    429,
						"message": "Too Many Requests",
					})
					c.Abort()
					return
				}
			} else if !allowed {
				c.JSON(429, gin.H{
					"code":    429,
					"message": "Too Many Requests",
				})
				c.Abort()
				return
			}
		} else {
			// 使用本地限流
			if !rl.checkLocalLimit(ip) {
				c.JSON(429, gin.H{
					"code":    429,
					"message": "Too Many Requests",
				})
				c.Abort()
				return
			}
		}

		c.Next()
	}
}

// checkRedisLimit 使用Redis进行限流检查
func (rl *RateLimiter) checkRedisLimit(ctx context.Context, key string) (bool, error) {
	key = fmt.Sprintf("%s:%s", rl.prefix, key)

	// 使用Redis的令牌桶算法实现
	exists, err := rl.redis.Exists(ctx, key).Result()
	if err != nil {
		return false, err
	}

	if exists == 0 {
		// 初始化令牌桶
		pipe := rl.redis.Pipeline()
		pipe.HSet(ctx, key, "tokens", rl.b, "last_update", time.Now().Unix())
		pipe.Expire(ctx, key, time.Hour) // 设置过期时间
		_, err = pipe.Exec(ctx)
		if err != nil {
			return false, err
		}
		return true, nil
	}

	// 获取当前令牌数和上次更新时间
	pipe := rl.redis.Pipeline()
	tokensCmd := pipe.HGet(ctx, key, "tokens")
	lastUpdateCmd := pipe.HGet(ctx, key, "last_update")
	_, err = pipe.Exec(ctx)
	if err != nil {
		return false, err
	}

	tokens, _ := tokensCmd.Float64()
	lastUpdate, _ := lastUpdateCmd.Int64()
	now := time.Now().Unix()

	// 计算需要恢复的令牌数
	elapsed := float64(now - lastUpdate)
	tokens = min(float64(rl.b), tokens+elapsed*float64(rl.r))

	if tokens < 1 {
		return false, nil
	}

	// 更新令牌数
	pipe = rl.redis.Pipeline()
	pipe.HSet(ctx, key, "tokens", tokens-1, "last_update", now)
	pipe.Expire(ctx, key, time.Hour) // 刷新过期时间
	_, err = pipe.Exec(ctx)

	return err == nil, err
}

// checkLocalLimit 使用本地限流器进行检查
func (rl *RateLimiter) checkLocalLimit(ip string) bool {
	rl.mu.Lock()
	defer rl.mu.Unlock()

	// 检查是否需要清理
	if time.Since(rl.lastCleanup) >= rl.cleanup {
		rl.cleanupLimiters()
	}

	limiter, exists := rl.ips[ip]
	if !exists {
		limiter = rate.NewLimiter(rl.r, rl.b)
		rl.ips[ip] = limiter
	}

	return limiter.Allow()
}

// cleanupLimiters 清理过期的限流器
func (rl *RateLimiter) cleanupLimiters() {
	now := time.Now()
	rl.lastCleanup = now

	for ip, limiter := range rl.ips {
		// 如果限流器一段时间内没有被使用，则删除
		if limiter.Tokens() >= float64(rl.b) {
			delete(rl.ips, ip)
		}
	}
}

func min(a, b float64) float64 {
	if a < b {
		return a
	}
	return b
}

// SecurityHeaders 安全头中间件
func SecurityHeaders() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 添加基本的安全响应头
		c.Header("X-Content-Type-Options", "nosniff")
		c.Header("X-Frame-Options", "DENY")
		c.Header("X-XSS-Protection", "1; mode=block")
		c.Header("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
		c.Next()
	}
}

// CORS 跨域中间件
func CORS() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 在生产环境中使用具体的域名
		if gin.Mode() == gin.ReleaseMode {
			c.Header("Access-Control-Allow-Origin", "https://your-domain.com")
		} else {
			c.Header("Access-Control-Allow-Origin", "*")
		}

		// 限制允许的方法
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")

		// 限制允许的请求头
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Content-Length, Accept-Encoding, X-CSRF-Token, Authorization")

		// 允许携带凭证
		c.Header("Access-Control-Allow-Credentials", "true")

		// 预检请求缓存时间
		c.Header("Access-Control-Max-Age", "86400") // 24小时

		// 处理预检请求
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}

		c.Next()
	}
}
