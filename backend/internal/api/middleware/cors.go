package middleware

import (
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

// CORSMiddleware 创建CORS中间件
// 注意：在生产环境中，如果使用Nginx处理CORS，可以禁用此中间件
// 通过设置环境变量 ENABLE_APP_CORS=false 来禁用
func CORSMiddleware() gin.HandlerFunc {
	// 允许的源（从环境变量读取，默认允许所有）
	allowOrigins := []string{"*"}
	if origins := os.Getenv("ALBUM_CORS_ALLOW_ORIGINS"); origins != "" {
		allowOrigins = []string{origins} // 可以扩展为支持多个源
	}

	config := cors.Config{
		AllowOrigins: allowOrigins,
		AllowMethods: []string{"GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"},
		AllowHeaders: []string{
			"Origin",
			"Content-Type",
			"Accept",
			"Authorization",
			"X-Requested-With",
			"X-File-Name",
			"X-File-Path",
			"X-File-Hash",
			"X-File-Size",
			"X-Chunk-Size",
			"X-File-SHA256",
			"X-Chunk-Hash",
			"X-Album-ID",
		},
		ExposeHeaders:    []string{"Content-Length", "Content-Type", "Content-Disposition"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}

	return cors.New(config)
}
