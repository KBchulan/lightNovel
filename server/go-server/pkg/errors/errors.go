// ****************************************************************************
// @file       errors.go
// @brief      错误处理
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package errors

import "fmt"

// ErrorCode 错误码类型
type ErrorCode int

const (
	// 系统级错误码
	Success ErrorCode = iota
	ErrInternalServer
	ErrBadRequest
	ErrNotFound
	ErrTimeout
	ErrTooManyRequests
	ErrAlreadyExists

	// 业务错误码 (1000+)
	ErrNovelNotFound ErrorCode = iota + 1000
	ErrVolumeNotFound
	ErrChapterNotFound
	ErrInvalidParameter
	ErrCacheOperationFailed
	ErrDatabaseOperationFailed

	// 阅读记录相关错误码
	ErrReadRecordNotFound
	ErrReadRecordExists
	ErrInvalidReadDuration

	// 已读章节相关错误码
	ErrReadChapterNotFound
	ErrReadChapterExists
	ErrInvalidReadCount

	// 阅读统计相关错误码
	ErrReadingStatNotFound
	ErrInvalidDateRange
)

// 错误码对应的消息
var errorMessages = map[ErrorCode]string{
	Success:                    "成功",
	ErrInternalServer:          "服务器内部错误",
	ErrBadRequest:              "请求参数错误",
	ErrNotFound:                "资源不存在",
	ErrTimeout:                 "请求超时",
	ErrTooManyRequests:         "请求过于频繁",
	ErrAlreadyExists:           "资源已存在",
	ErrNovelNotFound:           "小说不存在",
	ErrVolumeNotFound:          "卷不存在",
	ErrChapterNotFound:         "章节不存在",
	ErrInvalidParameter:        "无效的参数",
	ErrCacheOperationFailed:    "缓存操作失败",
	ErrDatabaseOperationFailed: "数据库操作失败",
	ErrReadRecordNotFound:      "阅读记录不存在",
	ErrReadRecordExists:        "阅读记录已存在",
	ErrInvalidReadDuration:     "无效的阅读时长",
	ErrReadChapterNotFound:     "已读章节记录不存在",
	ErrReadChapterExists:       "已读章节记录已存在",
	ErrInvalidReadCount:        "无效的阅读次数",
	ErrReadingStatNotFound:     "阅读统计不存在",
	ErrInvalidDateRange:        "无效的日期范围",
}

// BusinessError 业务错误类型
type BusinessError struct {
	Code    ErrorCode
	Message string
}

// Error 实现error接口
func (e *BusinessError) Error() string {
	return fmt.Sprintf("错误码: %d, 信息: %s", e.Code, e.Message)
}

// NewError 创建新的业务错误
func NewError(code ErrorCode) *BusinessError {
	return &BusinessError{
		Code:    code,
		Message: errorMessages[code],
	}
}

// NewErrorWithMessage 创建带自定义消息的业务错误
func NewErrorWithMessage(code ErrorCode, message string) *BusinessError {
	return &BusinessError{
		Code:    code,
		Message: message,
	}
}

// GetErrorMessage 获取错误码对应的消息
func GetErrorMessage(code ErrorCode) string {
	return errorMessages[code]
}
