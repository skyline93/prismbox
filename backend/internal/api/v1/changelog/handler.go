package changelog

import (
	"github.com/album/backend/internal/changelog"
	"github.com/gin-gonic/gin"
)

// Handler 变更日志 API 处理器
type Handler struct {
	engine *changelog.Engine
}

// NewHandler 创建变更日志处理器
func NewHandler(engine *changelog.Engine) *Handler {
	return &Handler{
		engine: engine,
	}
}

// RegisterRoutes 注册路由（由 engine 内部处理）
// 这个方法主要是为了保持 API 一致性，实际路由注册在 engine 中完成
func (h *Handler) RegisterRoutes(router *gin.RouterGroup) {
	// 路由注册由 engine.RegisterRoutesAndJobs 完成
	// 这里可以添加额外的路由或中间件
}

