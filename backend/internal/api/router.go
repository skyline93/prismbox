package api

import (
	"os"

	"github.com/album/backend/internal/api/middleware"
	"github.com/album/backend/internal/api/v1/auth"
	"github.com/album/backend/internal/api/v1/changelog"
	"github.com/album/backend/internal/api/v1/group"
	"github.com/album/backend/internal/api/v1/media"
	"github.com/album/backend/internal/api/v1/share"
	"github.com/album/backend/internal/api/v1/storage"
	"github.com/album/backend/internal/app"
	"github.com/album/backend/internal/version"
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

	// CORS中间件（可选，如果nginx处理CORS，这里可以禁用）
	// 通过环境变量 ALBUM_ENABLE_APP_CORS 控制，默认禁用
	if os.Getenv("ALBUM_ENABLE_APP_CORS") == "true" {
		r.engine.Use(middleware.CORSMiddleware())
		log := logger.New("api.router")
		log.Info("CORS middleware enabled (application level)")
	}

	log := logger.New("api.router")
	log.Info("global middleware setup completed")
}

// setupAPIV1 设置API v1路由
func (r *Router) setupAPIV1() {
	v1 := r.engine.Group("/api/v1")

	// 注册版本信息路由（公开，不需要认证）
	v1.GET("/version", r.getVersion)

	// 注册认证路由
	auth.RegisterRoutes(v1, r.app)

	// 注册媒体路由
	media.RegisterRoutes(v1, r.app)

	// 注册圈子路由
	group.RegisterRoutes(v1, r.app)

	// 注册分享路由
	share.RegisterRoutes(v1, r.app)

	// 注册存储路由
	storage.RegisterRoutes(v1, r.app)

	// 注册分享的公开路由（在根路由）
	share.RegisterPublicRoutes(r.engine, r.app)

	// 注册变更日志路由（如果启用）
	if r.app.ChangelogEngine != nil && r.app.ChangelogEngine.IsEnabled() {
		changelog.RegisterRoutes(v1, r.app)
	}
}

func (r *Router) setupStatic() {
	r.engine.Static("/static", "./public")
}

// setupPublicRoutes 设置公开路由（不需要认证）
func (r *Router) setupPublicRoutes() {
	// 公开的分享资源路由在share/routes.go中注册
	// 因为需要在根路由注册，所以通过RegisterPublicRoutes函数处理
}

// getVersion 返回服务端版本信息
func (r *Router) getVersion(c *gin.Context) {
	info := version.Get()
	c.JSON(200, info)
}

// Engine 返回Gin引擎
func (r *Router) Engine() *gin.Engine {
	return r.engine
}
