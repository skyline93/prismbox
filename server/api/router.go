// api/router.go
package api

import (
	"server/auth"
	"server/core"
	"server/handlers"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func SetupRouter(db *gorm.DB, cfg *core.Config) *gin.Engine {
	r := gin.Default()

	// 初始化所有处理器
	authHandler := &auth.AuthHandler{DB: db, JWTSecret: cfg.JWTSecret}
	photoHandler := &handlers.PhotoHandler{DB: db}
	albumHandler := &handlers.AlbumHandler{DB: db}

	apiV1 := r.Group("/api/v1")
	{
		// 公共路由：认证
		authRoutes := apiV1.Group("/auth")
		{
			authRoutes.POST("/register", authHandler.Register)
			authRoutes.POST("/login", authHandler.Login)
		}

		// 受保护的路由组
		protected := apiV1.Group("/")
		protected.Use(auth.Middleware(cfg.JWTSecret))
		{
			protected.POST("/upload", photoHandler.Upload)
			protected.GET("/photos", photoHandler.GetPhotos)
			protected.GET("/download/:uuid", photoHandler.DownloadOriginal)
			protected.GET("/preview/:uuid", photoHandler.DownloadPreview)
			protected.GET("/thumbnail/:uuid", photoHandler.DownloadThumbnail)
			protected.DELETE("/photos/:uuid", photoHandler.Delete)

			albumRoutes := protected.Group("/albums")
			{
				albumRoutes.POST("", albumHandler.CreateAlbum)
				albumRoutes.GET("", albumHandler.GetAlbums)
				albumRoutes.GET("/:uuid", albumHandler.GetAlbum)
				albumRoutes.POST("/:uuid/items", albumHandler.AddItemsToAlbum)
				albumRoutes.DELETE("/:uuid", albumHandler.DeleteAlbum)
			}
		}
	}
	return r
}
