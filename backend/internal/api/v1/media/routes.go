package media

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册媒体路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.MediaService == nil {
		return
	}

	handler := NewHandler(app.MediaService, app)

	protected := rg.Group("/media")
	if app.AuthService != nil {
		protected.Use(middleware.AuthMiddleware(app.AuthService))
	}
	{
		protected.POST("/upload-stream", handler.UploadMedia)
		protected.GET("", handler.GetMedias)
		protected.POST("/check_hashes", handler.CheckHashes)
		protected.GET("/changes", handler.GetChanges)
		protected.GET("/:uuid", handler.GetMediaDetail)
		protected.DELETE("/:uuid", handler.Delete)
		protected.POST("/:uuid/restore", handler.Restore)
		protected.DELETE("/:uuid/purge", handler.Purge)
	}

	download := rg.Group("/media")
	download.Use(middleware.FlexibleAuthMiddleware(app.AuthService, app.URLSigner))
	{
		download.GET("/:uuid/download/original", handler.DownloadOriginal)
		download.GET("/:uuid/download/preview", handler.DownloadPreview)
		download.GET("/:uuid/download/thumbnail", handler.DownloadThumbnail)
	}
}
