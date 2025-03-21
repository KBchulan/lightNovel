// ****************************************************************************
//
// @file       response.go
// @brief      响应层，定义响应格式和错误处理
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

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

// ReadingStatResponse 阅读统计响应
type ReadingStatResponse struct {
	NovelInfo     interface{} `json:"novelInfo"`     // 小说基本信息
	TotalReadTime int64       `json:"totalReadTime"` // 总阅读时长（秒）
	ChapterRead   int         `json:"chapterRead"`   // 已读章节数
	ReadProgress  float64     `json:"readProgress"`  // 阅读进度（百分比）
	ReadDays      int         `json:"readDays"`      // 阅读天数
	CompleteCount int         `json:"completeCount"` // 完整阅读章节数
	LastActiveAt  time.Time   `json:"lastActiveAt"`  // 最后活跃时间
}

// ReadChapterResponse 已读章节响应
type ReadChapterResponse struct {
	ChapterInfo  interface{} `json:"chapterInfo"`  // 章节基本信息
	ReadCount    int         `json:"readCount"`    // 阅读次数
	IsComplete   bool        `json:"isComplete"`   // 是否读完
	LastPosition int         `json:"lastPosition"` // 最后阅读位置
	LastReadAt   time.Time   `json:"lastReadAt"`   // 最后阅读时间
}

// ReadRecordResponse 阅读记录响应
type ReadRecordResponse struct {
	ID            string      `json:"id"`
	ChapterInfo   interface{} `json:"chapterInfo"`   // 章节信息
	ReadDuration  int64       `json:"readDuration"`  // 阅读时长（秒）
	StartPosition int         `json:"startPosition"` // 开始位置
	EndPosition   int         `json:"endPosition"`   // 结束位置
	IsComplete    bool        `json:"isComplete"`    // 是否读完
	Source        string      `json:"source"`        // 阅读来源
	ReadAt        time.Time   `json:"readAt"`        // 阅读时间
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
