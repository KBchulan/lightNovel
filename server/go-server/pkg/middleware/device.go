// ****************************************************************************
//
// @file       device.go
// @brief      设备中间件
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

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
		deviceID := c.GetHeader("X-Device-ID")
		clientIP := c.ClientIP()
		userAgent := c.Request.UserAgent()

		var device *models.Device
		var err error

		if deviceID != "" {
			device, err = novelService.GetOrCreateDevice(c.Request.Context(), deviceID, clientIP, userAgent)
		} else {
			device, err = novelService.FindDeviceByIP(c.Request.Context(), clientIP)
			if err != nil || device == nil {
				device, err = novelService.CreateNewDevice(c.Request.Context(), clientIP, userAgent)
			}
		}

		if err != nil {
			response.Error(c, err)
			c.Abort()
			return
		}

		c.Set("deviceID", device.ID)
		c.Set("device", device)

		c.Header("X-Device-ID", device.ID)

		c.Next()
	}
}
