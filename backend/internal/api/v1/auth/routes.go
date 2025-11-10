package auth

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册认证相关路由。
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.AuthService == nil {
		return
	}

	handler := NewHandler(app.AuthService)

	authRoutes := rg.Group("/auth")
	{
		authRoutes.POST("/register", handler.Register)
		authRoutes.POST("/login", handler.Login)
		authRoutes.POST("/refresh", handler.RefreshToken)
		authRoutes.POST("/logout", handler.Logout)
		authRoutes.POST("/apple/login", handler.AppleLogin)
	}

	protected := rg.Group("/")
	protected.Use(middleware.AuthMiddleware(app.AuthService))
	{
		protected.GET("/auth/profile", handler.GetProfile)
		protected.POST("/auth/avatar", handler.UploadAvatar)
		protected.POST("/auth/password/set", handler.SetPassword)
	}
}
