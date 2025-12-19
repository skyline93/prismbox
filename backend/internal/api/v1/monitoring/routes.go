package monitoring

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册监控路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.MediaService == nil {
		return
	}

	handler := NewHandler(app.MediaService)

	protected := rg.Group("/monitoring")
	if app.AuthService != nil {
		protected.Use(middleware.AuthMiddleware(app.AuthService))
	}
	{
		protected.GET("/thumbnail", handler.GetThumbnailMetrics)
	}
}
