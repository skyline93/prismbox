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
		// 上传接口需要设备信息（用于统计上传来源设备）
		uploadGroup := protected.Group("")
		uploadGroup.Use(middleware.DeviceMiddleware())
		{
			uploadGroup.POST("/upload-stream", handler.UploadMedia)
			uploadGroup.HEAD("/upload-stream", handler.ValidateUploadEndpoint)
		}

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
		download.HEAD("/:uuid/download/original", handler.DownloadOriginal)
		download.GET("/:uuid/download/preview", handler.DownloadPreview)
		download.HEAD("/:uuid/download/preview", handler.DownloadPreview)
		download.GET("/:uuid/download/thumbnail", handler.DownloadThumbnail)
	}

	// 统一API路径：/api/v1/assets/:uuid/thumbnail
	assets := rg.Group("/assets")
	assets.Use(middleware.FlexibleAuthMiddleware(app.AuthService, app.URLSigner))
	{
		assets.GET("/:uuid/thumbnail", handler.DownloadThumbnail)
	}
}
