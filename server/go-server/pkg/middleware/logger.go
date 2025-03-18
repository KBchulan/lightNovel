package middleware

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
)

// Logger 返回一个日志中间件
func Logger() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 只记录非健康检查的请求
		path := c.Request.URL.Path
		if path == "/api/v1/health" {
			c.Next()
			return
		}

		// 开始时间
		start := time.Now()
		raw := c.Request.URL.RawQuery

		// 处理请求
		c.Next()

		// 只记录错误或较慢的请求
		latency := time.Since(start)
		if c.Writer.Status() >= 400 || latency > 200*time.Millisecond {
			if raw != "" {
				path = fmt.Sprintf("%s?%s", path, raw)
			}

			// 日志格式
			fmt.Printf("[GIN] %v | %3d | %13v | %15s | %-7s %s\n",
				time.Now().Format("2006/01/02 - 15:04:05"),
				c.Writer.Status(),
				latency,
				c.ClientIP(),
				c.Request.Method,
				path,
			)
		}
	}
}
