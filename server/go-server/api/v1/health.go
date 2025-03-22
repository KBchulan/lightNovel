// @title Light Novel API
// @version 1.0
// @description 轻小说阅读API服务
// @BasePath /api/v1
// @schemes http https
// @contact.name API Support
// @contact.email support@example.com
// @license.name MIT
// @license.url https://opensource.org/licenses/MIT

// @tag.name system
// @tag.description 系统相关接口

// ****************************************************************************
//
// @file       health.go
// @brief      健康检查API
//
// @author     KBchulan
// @date       2025/03/20
// @history
// ****************************************************************************

package v1

import (
	"net/http"
	"runtime"
	"time"

	"github.com/gin-gonic/gin"
)

// HealthResponse 健康检查响应
type HealthResponse struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Uptime    string    `json:"uptime"`
}

// MetricsResponse 系统指标响应
type MetricsResponse struct {
	Memory struct {
		Alloc      uint64 `json:"alloc"`
		TotalAlloc uint64 `json:"totalAlloc"`
		Sys        uint64 `json:"sys"`
		NumGC      uint32 `json:"numGC"`
	} `json:"memory"`
	Goroutines int    `json:"goroutines"`
	Uptime     string `json:"uptime"`
}

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

// @Summary 获取系统健康状态
// @Description 获取系统运行状态，包括启动时间、运行时长等信息
// @Tags system
// @Accept json
// @Produce json
// @Success 200 {object} response.Response{data=HealthResponse} "成功"
// @Router /api/v1/health [get]
func (h *HealthHandler) Check(c *gin.Context) {
	c.JSON(http.StatusOK, HealthResponse{
		Status:    "ok",
		Timestamp: time.Now(),
		Uptime:    time.Since(h.startTime).String(),
	})
}

// @Summary 获取系统性能指标
// @Description 获取系统详细的性能指标，包括内存使用、goroutine数量等
// @Tags system
// @Accept json
// @Produce json
// @Success 200 {object} response.Response{data=MetricsResponse} "成功"
// @Router /api/v1/metrics [get]
func (h *HealthHandler) Metrics(c *gin.Context) {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	response := MetricsResponse{}
	response.Memory.Alloc = m.Alloc
	response.Memory.TotalAlloc = m.TotalAlloc
	response.Memory.Sys = m.Sys
	response.Memory.NumGC = m.NumGC
	response.Goroutines = runtime.NumGoroutine()
	response.Uptime = time.Since(h.startTime).String()

	c.JSON(http.StatusOK, response)
}
