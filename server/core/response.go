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

func ErrorWithStatus(c *gin.Context, httpStatusCode int, message string) {
	c.AbortWithStatusJSON(httpStatusCode, ApiResponse{
		Code:    1,
		Message: message,
		Data:    nil,
	})
}

func NoContent(c *gin.Context) {
	c.Status(http.StatusNoContent)
}
