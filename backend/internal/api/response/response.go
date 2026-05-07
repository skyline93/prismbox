package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// ApiResponse is the standard JSON envelope for API responses.
type ApiResponse struct {
	Code    int         `json:"code"`           // 0 success, non-zero failure
	Message string      `json:"message"`        // Human-readable message
	Data    interface{} `json:"data,omitempty"` // Optional payload
}

// Success 成功响应
func Success(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusOK, ApiResponse{
		Code:    0,
		Message: message,
		Data:    data,
	})
}

// Error 错误响应
func Error(c *gin.Context, message string) {
	c.JSON(http.StatusBadRequest, ApiResponse{
		Code:    1,
		Message: message,
		Data:    nil,
	})
}

// ErrorAuth 认证错误响应
func ErrorAuth(c *gin.Context, message string) {
	c.JSON(http.StatusUnauthorized, ApiResponse{
		Code:    1,
		Message: message,
		Data:    nil,
	})
}

// Created 创建成功响应
func Created(c *gin.Context, message string, data interface{}) {
	c.JSON(http.StatusCreated, ApiResponse{
		Code:    0,
		Message: message,
		Data:    data,
	})
}

// NoContent 无内容响应
func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}

// ErrorNotFound 404 错误响应
func ErrorNotFound(c *gin.Context, message string) {
	c.JSON(http.StatusNotFound, ApiResponse{
		Code:    1,
		Message: message,
		Data:    nil,
	})
}

// ErrorWithStatus 指定状态码的错误响应
func ErrorWithStatus(c *gin.Context, statusCode int, message string) {
	c.JSON(statusCode, ApiResponse{
		Code:    1,
		Message: message,
		Data:    nil,
	})
}
