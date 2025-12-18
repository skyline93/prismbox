package middleware

import (
	"github.com/album/backend/internal/api/response"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
)

const (
	deviceIDKey   = "deviceID"
	deviceTypeKey = "deviceType"
)

// DeviceMiddleware 设备信息中间件（强制要求）
// 从请求头提取 x-device-id 和 x-device-type，并存储到 context 中
// 如果设备信息缺失，则返回 400 错误并中断请求
func DeviceMiddleware() gin.HandlerFunc {
	log := logger.New("api.middleware.device")

	return func(c *gin.Context) {
		// 提取设备ID（必需）
		deviceID := c.GetHeader("x-device-id")
		if deviceID == "" {
			log.Warn("Device ID is missing",
				logger.String("path", c.Request.URL.Path),
				logger.String("method", c.Request.Method),
				logger.String("remote_addr", c.ClientIP()),
			)
			response.Error(c, "Device ID is required. Please provide 'x-device-id' header")
			c.Abort()
			return
		}

		// 提取设备类型（必需）
		deviceType := c.GetHeader("x-device-type")
		if deviceType == "" {
			log.Warn("Device type is missing",
				logger.String("path", c.Request.URL.Path),
				logger.String("method", c.Request.Method),
				logger.String("remote_addr", c.ClientIP()),
				logger.String("device_id", deviceID),
			)
			response.Error(c, "Device type is required. Please provide 'x-device-type' header")
			c.Abort()
			return
		}

		// 验证设备ID格式（基本验证：非空且长度合理）
		if len(deviceID) < 8 || len(deviceID) > 128 {
			log.Warn("Invalid device ID format",
				logger.String("path", c.Request.URL.Path),
				logger.String("method", c.Request.Method),
				logger.String("device_id_length", string(rune(len(deviceID)))),
			)
			response.Error(c, "Invalid device ID format. Device ID must be between 8 and 128 characters")
			c.Abort()
			return
		}

		// 存储到 context，供后续 handler 使用
		c.Set(deviceIDKey, deviceID)
		c.Set(deviceTypeKey, deviceType)

		log.Debug("Device information extracted",
			logger.String("path", c.Request.URL.Path),
			logger.String("method", c.Request.Method),
			logger.String("device_id", deviceID),
			logger.String("device_type", deviceType),
		)

		c.Next()
	}
}

// GetDeviceID 从上下文获取设备ID（如果存在）
func GetDeviceID(c *gin.Context) string {
	if v, exists := c.Get(deviceIDKey); exists {
		if id, ok := v.(string); ok {
			return id
		}
	}
	return ""
}

// GetDeviceType 从上下文获取设备类型（如果存在）
func GetDeviceType(c *gin.Context) string {
	if v, exists := c.Get(deviceTypeKey); exists {
		if deviceType, ok := v.(string); ok {
			return deviceType
		}
	}
	return ""
}

// MustGetDeviceID 从上下文获取设备ID
// 注意：如果使用了 DeviceMiddleware，此方法应该总是返回非空值
func MustGetDeviceID(c *gin.Context) string {
	return GetDeviceID(c)
}

// MustGetDeviceType 从上下文获取设备类型
// 注意：如果使用了 DeviceMiddleware，此方法应该总是返回非空值
func MustGetDeviceType(c *gin.Context) string {
	return GetDeviceType(c)
}
