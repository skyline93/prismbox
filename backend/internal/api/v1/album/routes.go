package album

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册相册路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.AlbumRepo == nil || app.MediaRepo == nil || app.DB == nil {
		return
	}

	_ = NewHandler(app.AlbumRepo, app.MediaRepo, app.DB)

	// 需要用户认证的路由
	protected := rg.Group("/albums")
	protected.Use(middleware.AuthMiddleware(app.AuthService))
	{
		// 相册路由可以在这里添加
	}
}
