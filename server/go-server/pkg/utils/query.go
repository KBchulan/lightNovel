// ****************************************************************************
//
// @file       query.go
// @brief      查询层，如获取查询参数
//
// @author     KBchulan
// @date       2025/03/21
// @history
// ****************************************************************************

package utils

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

// GetIntQuery 从请求中获取整数查询参数
func GetIntQuery(c *gin.Context, key string, defaultValue int) int {
	value := c.Query(key)
	if value == "" {
		return defaultValue
	}

	intValue, err := strconv.Atoi(value)
	if err != nil {
		return defaultValue
	}

	return intValue
}
