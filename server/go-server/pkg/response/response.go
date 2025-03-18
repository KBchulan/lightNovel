package response

import (
	"lightnovel/pkg/errors"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Response 统一API响应格式
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data"`
}

// PageResponse 分页响应格式
type PageResponse struct {
	Total   int64       `json:"total"`
	Page    int         `json:"page"`
	Size    int         `json:"size"`
	HasNext bool        `json:"hasNext"`
	Data    interface{} `json:"data"`
}

// ReadingHistoryResponse 阅读历史响应
type ReadingHistoryResponse struct {
	NovelInfo    interface{} `json:"novelInfo"`    // 小说基本信息
	LastProgress interface{} `json:"lastProgress"` // 最后阅读进度
	LastReadTime string      `json:"lastReadTime"` // 最后阅读时间
}

// DeviceInfoResponse 设备信息响应
type DeviceInfoResponse struct {
	ID         string    `json:"id"`
	DeviceType string    `json:"deviceType"`
	FirstSeen  time.Time `json:"firstSeen"`
	LastSeen   time.Time `json:"lastSeen"`
}

// Success 成功响应
func Success(c *gin.Context, data interface{}) {
	c.JSON(http.StatusOK, Response{
		Code:    int(errors.Success),
		Message: errors.GetErrorMessage(errors.Success),
		Data:    data,
	})
}

// SuccessWithPage 成功分页响应
func SuccessWithPage(c *gin.Context, total int64, page, size int, data interface{}) {
	hasNext := (page * size) < int(total)
	pageResponse := PageResponse{
		Total:   total,
		Page:    page,
		Size:    size,
		HasNext: hasNext,
		Data:    data,
	}
	Success(c, pageResponse)
}

// SuccessWithHistory 成功的阅读历史响应
func SuccessWithHistory(c *gin.Context, history []ReadingHistoryResponse) {
	Success(c, gin.H{
		"history": history,
		"total":   len(history),
	})
}

// Error 错误响应
func Error(c *gin.Context, err error) {
	if bizErr, ok := err.(*errors.BusinessError); ok {
		c.JSON(http.StatusOK, Response{
			Code:    int(bizErr.Code),
			Message: bizErr.Message,
			Data:    nil,
		})
		return
	}

	// 未知错误作为内部服务器错误处理
	c.JSON(http.StatusInternalServerError, Response{
		Code:    int(errors.ErrInternalServer),
		Message: err.Error(),
		Data:    nil,
	})
}
