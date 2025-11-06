package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// ApiResponse 统一 API 响应格式（与旧架构一致）
type ApiResponse struct {
	Code    int         `json:"code"`           // 0=成功, 1=失败
	Message string      `json:"message"`        // 响应消息
	Data    interface{} `json:"data,omitempty"` // 响应数据
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
