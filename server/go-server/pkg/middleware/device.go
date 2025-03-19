package middleware

import (
	"lightnovel/internal/models"
	"lightnovel/internal/service"
	"lightnovel/pkg/response"

	"github.com/gin-gonic/gin"
)

// DeviceMiddleware 处理设备ID的中间件
func DeviceMiddleware(novelService *service.NovelService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. 首先尝试从请求头获取设备ID
		deviceID := c.GetHeader("X-Device-ID")
		clientIP := c.ClientIP()
		userAgent := c.Request.UserAgent()

		var device *models.Device
		var err error

		if deviceID != "" {
			// 2. 如果请求头中有设备ID，使用该ID获取或创建设备信息
			device, err = novelService.GetOrCreateDevice(c.Request.Context(), deviceID, clientIP, userAgent)
		} else {
			// 3. 如果请求头中没有设备ID，先尝试通过IP查找已存在的设备
			device, err = novelService.FindDeviceByIP(c.Request.Context(), clientIP)
			if err != nil || device == nil {
				// 4. 如果通过IP找不到设备，创建新的设备（使用UUID）
				device, err = novelService.CreateNewDevice(c.Request.Context(), clientIP, userAgent)
			}
		}

		if err != nil {
			response.Error(c, err)
			c.Abort()
			return
		}

		// 将设备信息存储到上下文中
		c.Set("deviceID", device.ID)
		c.Set("device", device)

		// 在响应头中返回设备ID，确保客户端知道其设备ID
		c.Header("X-Device-ID", device.ID)

		c.Next()
	}
}
