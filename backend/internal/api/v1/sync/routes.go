package sync

import (
	"github.com/album/backend/internal/api/middleware"
	appctx "github.com/album/backend/internal/app"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册同步路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.SyncService == nil {
		return
	}

	handler := NewHandler(app.SyncService, app)

	protected := rg.Group("/sync")
	if app.AuthService != nil {
		protected.Use(middleware.AuthMiddleware(app.AuthService))
	}
	// 添加设备信息中间件（强制要求设备ID和设备类型）
	protected.Use(middleware.DeviceMiddleware())
	{
		// 流式同步接口
		protected.POST("/assets/stream", handler.StreamSyncAssets)

		// Checkpoint 接口
		protected.GET("/checkpoint", handler.GetCheckpoint)
		protected.POST("/checkpoint", handler.SetCheckpoint)
		protected.DELETE("/checkpoint", handler.DeleteCheckpoint)
	}
}
