// core/response.go
package core

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type ApiResponse struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

func Success(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, ApiResponse{
		Code:    0,
		Message: message,
		Data:    data,
	})
}

// 失败响应的辅助函数
func Error(c *gin.Context, message string) {
	c.JSON(http.StatusBadRequest, ApiResponse{
		Code:    1,
		Message: message,
		Data:    nil,
	})
}

func ErrorAuth(c *gin.Context, message string) {
	c.JSON(http.StatusUnauthorized, ApiResponse{
		Code:    1,
		Message: message,
		Data:    nil,
	})
}

func Created(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusCreated, ApiResponse{
		Code:    0,
		Message: message,
		Data:    data,
	})
}

// ErrorWithStatus 是一个新的、更灵活的失败响应函数。
// 它允许你传入一个明确的 HTTP 状态码。
// @param httpStatusCode - e.g., http.StatusNotFound, http.StatusInternalServerError
// @param message - 错误信息
func ErrorWithStatus(c *gin.Context, httpStatusCode int, message string) {
	c.AbortWithStatusJSON(httpStatusCode, ApiResponse{
		Code:    1,
		Message: message,
		Data:    nil,
	})
}

// NoContent 用于返回 204 No Content 响应。
// 这是分片上传成功时的最佳实践。
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}
