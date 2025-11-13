package changelog

import (
	appctx "github.com/album/backend/internal/app"
	"github.com/gin-gonic/gin"
)

// RegisterRoutes 注册变更日志路由
func RegisterRoutes(rg *gin.RouterGroup, app *appctx.App) {
	if app == nil || app.ChangelogEngine == nil {
		return
	}

	// 路由注册由 engine 内部完成
	app.ChangelogEngine.RegisterRoutesAndJobs(rg)
}

