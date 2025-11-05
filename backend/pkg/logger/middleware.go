package logger

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// GinMiddleware Gin中间件，自动记录请求日志
func GinMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 生成请求ID
		requestID := uuid.New().String()
		c.Set("request_id", requestID)
		c.Header("X-Request-ID", requestID)

		// 创建日志记录器
		log := New("http").WithFields(RequestID(requestID))

		// 将logger存入上下文
		c.Set("logger", log)

		// 记录请求开始
		start := c.Request.Method
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery
		if query != "" {
			path += "?" + query
		}

		log.Info("Request started",
			String("method", start),
			String("path", path),
			String("remote_addr", c.ClientIP()),
		)

		// 处理请求
		c.Next()

		// 记录请求结束
		status := c.Writer.Status()
		latency := c.GetDuration("latency")
		if latency == 0 {
			// 如果没有设置延迟，使用默认值
			latency = 0
		}

		fields := []Field{
			Int("status", status),
			String("method", start),
			String("path", path),
		}

		if latency > 0 {
			fields = append(fields, Duration("latency", latency))
		}

		// 根据状态码选择日志级别
		if status >= 500 {
			log.Error("Request failed", fields...)
		} else if status >= 400 {
			log.Warn("Request error", fields...)
		} else {
			log.Info("Request completed", fields...)
		}
	}
}
