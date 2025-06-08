// ****************************************************************************
//
// @file       validator.go
// @brief      验证层，如分页参数验证
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package middleware

import (
	"lightnovel/pkg/errors"
	"lightnovel/pkg/response"
	"strconv"

	"github.com/gin-gonic/gin"
)

// ValidatePagination 验证分页参数
func ValidatePagination() gin.HandlerFunc {
	return func(c *gin.Context) {
		page, err := strconv.Atoi(c.DefaultQuery("page", "1"))
		if err != nil || page < 1 {
			response.Error(c, errors.NewError(errors.ErrInvalidParameter))
			c.Abort()
			return
		}

		size, err := strconv.Atoi(c.DefaultQuery("size", "1000"))
		if err != nil || size < 1 || size > 1000 {
			response.Error(c, errors.NewError(errors.ErrInvalidParameter))
			c.Abort()
			return
		}

		c.Set("page", page)
		c.Set("size", size)
		c.Next()
	}
}

// ValidateLimit 验证限制参数
func ValidateLimit(defaultLimit, maxLimit int) gin.HandlerFunc {
	return func(c *gin.Context) {
		limit, err := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(defaultLimit)))
		if err != nil || limit < 1 || limit > maxLimit {
			response.Error(c, errors.NewError(errors.ErrInvalidParameter))
			c.Abort()
			return
		}

		c.Set("limit", limit)
		c.Next()
	}
}
