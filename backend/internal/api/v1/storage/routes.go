package storage

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册存储相关路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.StoragePoolService == nil {
		return
	}

	handler := NewHandler(app.StoragePoolService)

	group := rg.Group("/storage")
	if app.AuthService != nil {
		group.Use(middleware.AuthMiddleware(app.AuthService))
	}

	pools := group.Group("/pools")
	{
		pools.GET("", handler.ListPools)
		pools.GET("/:uuid", handler.GetPool)
		pools.POST("", handler.CreatePool)
		pools.PATCH("/:uuid", handler.UpdatePool)
		pools.POST("/:uuid/enable", handler.EnablePool)
		pools.POST("/:uuid/disable", handler.DisablePool)
		pools.POST("/refresh", handler.RefreshPools)
		pools.POST("/reconcile", handler.ReconcilePools)
		pools.GET("/usage", handler.GetUsage)
	}
}

