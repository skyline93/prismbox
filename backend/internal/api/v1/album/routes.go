package album

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	albumencryption "github.com/album/backend/internal/service/album_encryption"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册相册路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.AlbumEncryptionService == nil || app.AlbumRepo == nil || app.MediaRepo == nil || app.DB == nil {
		return
	}

	// 类型断言
	albumEncryptionService, ok := app.AlbumEncryptionService.(albumencryption.Service)
	if !ok {
		return
	}

	handler := NewHandler(albumEncryptionService, app.AlbumRepo, app.MediaRepo, app.DB)

	// 需要用户认证的路由
	protected := rg.Group("/albums")
	protected.Use(middleware.AuthMiddleware(app.AuthService))
	{
		// 获取或创建加密空间相册
		protected.GET("/encrypted-space", handler.GetOrCreateEncryptedSpace)

		// 密码管理（不需要会话令牌）
		protected.POST("/:albumId/password", handler.SetPassword)
		protected.POST("/:albumId/password/change", handler.ChangePassword)
		protected.POST("/:albumId/verify-password", handler.VerifyPassword)
		protected.DELETE("/:albumId/sessions", handler.RevokeAllSessions)

		// 资产管理（需要会话令牌）
		// 使用 AlbumSessionMiddleware 验证会话令牌
		assetsGroup := protected.Group("/:albumId")
		assetsGroup.Use(middleware.AlbumSessionMiddleware(albumEncryptionService))
		{
			assetsGroup.GET("/assets", handler.GetAssets)
			assetsGroup.POST("/assets", handler.AddAssets)
			assetsGroup.DELETE("/assets", handler.RemoveAssets)
		}
	}
}
