// server/core/pagination.go
package core

import (
	"strconv"

	"github.com/gin-gonic/gin"
)

// GetPaginationParams 从 Gin 上下文中解析分页参数
// 返回 page, limit 和 offset
func GetPaginationParams(c *gin.Context) (int, int, int) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))

	if page < 1 {
		page = 1
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 { // 防止一次请求过多数据
		limit = 100
	}

	offset := (page - 1) * limit
	return page, limit, offset
}
