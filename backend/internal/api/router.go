package api

import (
	"github.com/album/backend/internal/api/v1/auth"
	"github.com/album/backend/internal/api/v1/group"
	"github.com/album/backend/internal/api/v1/media"
	"github.com/album/backend/internal/app"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
)

// Router 路由注册器
type Router struct {
	engine *gin.Engine
	app    *app.App
}

// NewRouter 创建路由注册器
func NewRouter(app *app.App) *Router {
	// 设置Gin模式
	// gin.SetMode(gin.ReleaseMode)

	r := gin.Default()
	return &Router{
		engine: r,
		app:    app,
	}
}

// Setup 设置路由
func (r *Router) Setup() {
	// 1. 全局中间件
	r.setupGlobalMiddleware()

	// 2. 静态资源
	r.setupStatic()

	// 3. API v1 路由组
	r.setupAPIV1()
}

// setupGlobalMiddleware 设置全局中间件
func (r *Router) setupGlobalMiddleware() {
	// TODO: 添加日志中间件（使用 pkg/logger）
	// r.engine.Use(middleware.LoggerMiddleware())

	// TODO: 添加恢复中间件
	// r.engine.Use(middleware.RecoveryMiddleware())

	// TODO: 添加CORS中间件
	// r.engine.Use(middleware.CORSMiddleware())

	log := logger.New("api.router")
	log.Info("global middleware setup completed")
}

// setupAPIV1 设置API v1路由
func (r *Router) setupAPIV1() {
	v1 := r.engine.Group("/api/v1")

	// 注册认证路由
	auth.RegisterRoutes(v1, r.app)

	// 注册媒体路由
	media.RegisterRoutes(v1, r.app)

	// 注册圈子路由
	group.RegisterRoutes(v1, r.app)
}

func (r *Router) setupStatic() {
	r.engine.Static("/static", "./public")
}

// Engine 返回Gin引擎
func (r *Router) Engine() *gin.Engine {
	return r.engine
}
