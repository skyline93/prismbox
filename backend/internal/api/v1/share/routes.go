package share

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	shareservice "github.com/album/backend/internal/service/share"
	"github.com/gin-gonic/gin"
)

// Service 别名，避免循环依赖
type Service = shareservice.Service

// RegisterRoutes 注册分享相关路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.ShareService == nil {
		return
	}

	// 类型断言
	shareService, ok := app.ShareService.(Service)
	if !ok {
		return
	}

	handler := NewHandler(shareService)

	// 受保护的分享路由
	shareRoutes := rg.Group("/shares")
	shareRoutes.Use(middleware.AuthMiddleware(app.AuthService))
	{
		shareRoutes.POST("", handler.CreateShare)
		shareRoutes.GET("/with-me", handler.ListSharedWithMe)
	}

	// 公开的分享路由（不需要认证）
	publicApiRoutes := rg.Group("/")
	{
		publicApiRoutes.GET("/shares/:share_token/meta", handler.GetShareMetadata)
	}
}

// RegisterPublicRoutes 注册公开路由（在根路由注册，不在/api/v1下）
func RegisterPublicRoutes(engine *gin.Engine, app *appctx.App) {
	if app == nil || app.ShareService == nil {
		return
	}

	// 类型断言
	shareService, ok := app.ShareService.(Service)
	if !ok {
		return
	}

	handler := NewHandler(shareService)

	// 公开的分享资源路由（返回HTML页面）
	engine.GET("/s/:share_token", handler.GetSharedResource)
}

