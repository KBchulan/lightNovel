package middleware

import (
	"lightnovel/internal/service"
	"lightnovel/pkg/response"

	"github.com/gin-gonic/gin"
)

// DeviceMiddleware 处理设备ID的中间件
func DeviceMiddleware(novelService *service.NovelService) gin.HandlerFunc {
	return func(c *gin.Context) {
		deviceID := c.GetHeader("X-Device-ID")
		if deviceID == "" {
			deviceID = c.ClientIP()
		}

		// 获取或创建设备信息
		device, err := novelService.GetOrCreateDevice(c.Request.Context(), deviceID, c.ClientIP(), c.Request.UserAgent())
		if err != nil {
			response.Error(c, err)
			c.Abort()
			return
		}

		// 将设备信息存储到上下文中
		c.Set("deviceID", device.ID)
		c.Next()
	}
}
