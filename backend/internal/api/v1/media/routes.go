package media

import (
	mediaservice "github.com/album/backend/internal/service/media"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册媒体路由
func RegisterRoutes(rg *gin.RouterGroup, mediaService mediaservice.Service) {
	handler := NewHandler(mediaService)

	// TODO: 添加认证中间件
	// protected := rg.Group("/media")
	// protected.Use(middleware.AuthMiddleware(...))
	// {
	//     protected.POST("/upload-stream", handler.UploadMedia)
	//     ...
	// }

	// 目前先不添加认证中间件，直接注册路由
	mediaGroup := rg.Group("/media")
	{
		mediaGroup.POST("/upload-stream", handler.UploadMedia)
		mediaGroup.GET("/", handler.GetMedias)
		mediaGroup.GET("/:uuid", handler.GetMedia)
		mediaGroup.DELETE("/:uuid", handler.DeleteMedia)
	}
}
