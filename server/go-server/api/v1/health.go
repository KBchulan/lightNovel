package v1

import (
	"net/http"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
)

// HealthHandler 处理健康检查相关的请求
type HealthHandler struct {
	startTime time.Time
}

// NewHealthHandler 创建健康检查处理器
func NewHealthHandler() *HealthHandler {
	return &HealthHandler{
		startTime: time.Now(),
	}
}

// Check 健康检查端点
func (h *HealthHandler) Check(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":    "ok",
		"timestamp": time.Now(),
		"uptime":    time.Since(h.startTime).String(),
	})
}

// Metrics 监控指标端点
func (h *HealthHandler) Metrics(c *gin.Context) {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	c.JSON(http.StatusOK, gin.H{
		"memory": gin.H{
			"alloc":      m.Alloc,
			"totalAlloc": m.TotalAlloc,
			"sys":        m.Sys,
			"numGC":      m.NumGC,
		},
		"goroutines": runtime.NumGoroutine(),
		"uptime":     time.Since(h.startTime).String(),
	})
}
