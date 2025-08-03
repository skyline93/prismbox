package api

import (
	"server/auth"
	"server/core"
	"server/handlers"
	"server/routing"
	"server/urlsigner"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	_ "server/docs"

	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

func SetupRouter(db *gorm.DB, cfg *core.Config) *gin.Engine {
	r := gin.Default()

	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	authHandler := &auth.AuthHandler{
		DB:                    db,
		JWTSecret:             cfg.JWTSecret,
		AccessTokenExpiresIn:  cfg.AccessTokenExpiresIn,
		RefreshTokenExpiresIn: cfg.RefreshTokenExpiresIn,
	}
	urlSigner := urlsigner.NewSigner(cfg.URLSignerSecret)
	urlBuilder := routing.NewURLBuilder(cfg.PublicBaseURL)

	photoHandler := &handlers.PhotoHandler{DB: db, UploadDir: cfg.UploadDir}
	albumHandler := &handlers.AlbumHandler{DB: db}

	shareHandler := &handlers.ShareHandler{
		DB:            db,
		PublicBaseURL: cfg.PublicBaseURL,
		URLSigner:     urlSigner,
		URLBuilder:    urlBuilder,
	}
	publicHandler := &handlers.PublicHandler{
		DB:               db,
		URLSigner:        urlSigner,
		SignedURLLoadTTL: cfg.SignedURLLoadTTL,
		URLBuilder:       urlBuilder,
	}

	r.GET("/ping", func(ctx *gin.Context) { ctx.JSON(200, "pong") })

	r.GET("/s/:share_token", publicHandler.GetSharedResource)

	apiV1 := r.Group("/api/v1")
	{
		// 公共路由：认证
		authRoutes := apiV1.Group("/auth")
		{
			authRoutes.POST("/register", authHandler.Register)
			authRoutes.POST("/login", authHandler.Login)
			authRoutes.POST("/refresh", authHandler.RefreshToken)
			authRoutes.POST("/logout", authHandler.Logout)
		}

		// 受保护的路由组
		protected := apiV1.Group("/")
		protected.Use(auth.Middleware(cfg.JWTSecret)) // 中间件保持不变
		{
			// 照片相关路由
			photoRoutes := protected.Group("/photos")
			{
				photoRoutes.POST("/upload", photoHandler.Upload)
				photoRoutes.GET("", photoHandler.GetPhotos)
				photoRoutes.DELETE("/:uuid", photoHandler.Delete)
			}

			// 相册相关路由
			albumRoutes := protected.Group("/albums")
			{
				albumRoutes.POST("", albumHandler.CreateAlbum)
				albumRoutes.GET("", albumHandler.GetAlbums)
				albumRoutes.GET("/:uuid", albumHandler.GetAlbum)
				albumRoutes.POST("/:uuid/items", albumHandler.AddItemsToAlbum)
				albumRoutes.DELETE("/:uuid", albumHandler.DeleteAlbum)
			}

			shareRoutes := protected.Group("/shares")
			{
				shareRoutes.POST("", shareHandler.CreateShare)
				shareRoutes.GET("/with-me", shareHandler.ListSharedWithMe)
				// 其他管理路由，如撤销、列出自己的分享等，可以加在这里
			}
		}

		downloadRoutes := apiV1.Group("/")
		downloadRoutes.Use(auth.FlexibleAuthMiddleware(cfg.JWTSecret, urlSigner))
		{
			downloadRoutes.GET("/photos/:uuid/download/original", photoHandler.DownloadOriginal)
			downloadRoutes.GET("/photos/:uuid/download/preview", photoHandler.DownloadPreview)
			downloadRoutes.GET("/photos/:uuid/download/thumbnail", photoHandler.DownloadThumbnail)
		}

		publicApiRoutes := apiV1.Group("/")
		{
			publicApiRoutes.GET("/shares/:share_token/meta", shareHandler.GetShareMetadata)
		}
	}
	return r
}
