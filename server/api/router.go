// api/router.go

package api

import (
	"server/auth"
	"server/core"
	"server/handlers"
	"server/handlers/group"
	"server/routing"
	"server/urlsigner"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"

	_ "server/docs"

	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
)

func SetupRouter(db *gorm.DB, cfg *core.Config) *gin.Engine {
	r := gin.Default()

	corsConfig := cors.Config{
		AllowOrigins: []string{"*"},
		AllowMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"},
		AllowHeaders: []string{
			"Origin", "Content-Type", "Accept", "Authorization", "X-Requested-With",
			// 添加分片上传需要的自定义请求头
			"X-File-Name", "X-File-Path", "X-File-Hash", "X-File-Size", "X-Chunk-Size",
			"X-File-SHA256", "X-Chunk-Hash", "X-Album-ID",
		},
		ExposeHeaders:    []string{"Content-Length", "Content-Type"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}
	r.Use(cors.New(corsConfig))

	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	authHandler := &auth.AuthHandler{
		DB:                    db,
		AvatarBaseURL:         cfg.PublicBaseURL + "/static/avatars/",
		JWTSecret:             cfg.JWTSecret,
		AccessTokenExpiresIn:  cfg.AccessTokenExpiresIn,
		RefreshTokenExpiresIn: cfg.RefreshTokenExpiresIn,
	}
	urlSigner := urlsigner.NewSigner(cfg.URLSignerSecret)
	urlBuilder := routing.NewURLBuilder(cfg.PublicBaseURL)

	mediaHandler := &handlers.MediaHandler{
		DB:               db,
		UploadDir:        cfg.UploadDir,
		URLSigner:        urlSigner,
		URLBuilder:       urlBuilder,
		SignedURLLoadTTL: cfg.SignedURLLoadTTL,
	}
	albumHandler := &handlers.AlbumHandler{DB: db}

	shareHandler := &handlers.ShareHandler{
		DB:               db,
		URLSigner:        urlSigner,
		SignedURLLoadTTL: cfg.SignedURLLoadTTL,
		URLBuilder:       urlBuilder,
	}
	publicHandler := &handlers.PublicHandler{
		DB:               db,
		URLSigner:        urlSigner,
		SignedURLLoadTTL: cfg.SignedURLLoadTTL,
		URLBuilder:       urlBuilder,
	}

	groupHandler := &group.GroupHandler{
		DB:            db,
		UploadDir:     cfg.UploadDir,
		AvatarBaseURL: cfg.PublicBaseURL + "/static/avatars/",
		URLBuilder:    urlBuilder,
	}

	r.GET("/ping", func(ctx *gin.Context) { ctx.JSON(200, "pong") })
	r.Static("/static", "./public")

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
			protected.GET("/auth/profile", authHandler.GetProfile)
			protected.POST("/auth/avatar", authHandler.UploadAvatar)

			// 媒体相关路由
			mediaRoutes := protected.Group("/media")
			{
				mediaRoutes.POST("/upload", mediaHandler.Upload)
				mediaRoutes.POST("/upload-stream", mediaHandler.UploadStream)
				// 分片上传路由
				mediaRoutes.POST("/upload/initiate", mediaHandler.InitiateUpload)
				mediaRoutes.POST("/upload/chunk", mediaHandler.UploadChunk)
				mediaRoutes.POST("/upload/complete", mediaHandler.CompleteUpload)

				mediaRoutes.GET("", mediaHandler.GetMedias)
				mediaRoutes.POST("/check_hashes", mediaHandler.CheckHashes)
				mediaRoutes.GET("/changes", mediaHandler.GetChanges)
				mediaRoutes.GET("/:uuid", mediaHandler.GetMediaDetail)
				mediaRoutes.DELETE("/:uuid", mediaHandler.Delete)
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

			groupRoutes := protected.Group("/groups")
			{
				groupRoutes.POST("", groupHandler.CreateGroup)
				groupRoutes.GET("", groupHandler.GetMyGroups)

				groupRoutes.POST("/join", groupHandler.JoinGroup)
				groupRoutes.POST("/:uuid/leave", groupHandler.LeaveGroup)

				groupRoutes.GET("/:uuid", groupHandler.GetGroupDetails)
				groupRoutes.PUT("/:uuid", groupHandler.UpdateGroup)

				groupRoutes.POST("/:uuid/posts", groupHandler.CreatePost)
				groupRoutes.GET("/:uuid/feed", groupHandler.GetGroupFeed)
				groupRoutes.GET("/:uuid/media/:media_uuid/thumbnail", groupHandler.GetGroupMediaThumbnail)
				groupRoutes.GET("/:uuid/media/:media_uuid/preview", groupHandler.GetGroupMediaPreview)

				groupRoutes.GET("/:uuid/members", groupHandler.GetGroupMembers)
				groupRoutes.POST("/:uuid/members/invite", groupHandler.CreateInvite)
				groupRoutes.DELETE("/:uuid/members/:userId", groupHandler.RemoveMember)
			}

			postRoutes := protected.Group("/posts")
			{
				postRoutes.POST("/:postId/comments", groupHandler.AddComment)
				postRoutes.GET("/:postId/comments", groupHandler.GetComments)
			}

			commentRoutes := protected.Group("/comments")
			{
				commentRoutes.DELETE("/:commentId", groupHandler.DeleteComment)
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
			downloadRoutes.GET("/media/:uuid/download/original", mediaHandler.DownloadOriginal)
			downloadRoutes.GET("/media/:uuid/download/preview", mediaHandler.DownloadPreview)
			downloadRoutes.GET("/media/:uuid/download/thumbnail", mediaHandler.DownloadThumbnail)
		}

		publicApiRoutes := apiV1.Group("/")
		{
			publicApiRoutes.GET("/shares/:share_token/meta", shareHandler.GetShareMetadata)
		}
	}
	return r
}
