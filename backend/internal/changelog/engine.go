package changelog

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Engine 变更日志同步引擎
type Engine struct {
	config  *Config
	handler *syncHandler
	cleanup *cleanupService
	enabled bool
}

// NewEngine 创建变更日志引擎
// 如果配置中 Enabled=false，将创建一个禁用状态的引擎
func NewEngine(db *gorm.DB, config *Config) *Engine {
	engine := &Engine{
		config:  config,
		enabled: config.Enabled,
	}

	// 只有在启用时才初始化组件
	if config.Enabled {
		// 自动迁移数据库表
		if err := db.AutoMigrate(&Changelog{}, &ClientSyncStatus{}); err != nil {
			// 如果迁移失败，记录错误但不阻止启动
			// 在实际应用中，可以使用 logger 记录
		}

		// 初始化内部组件
		syncSvc := newSyncService(db, config)
		engine.handler = newSyncHandler(syncSvc, config)
		engine.cleanup = newCleanupService(db, config)
	}

	return engine
}

// RegisterRoutesAndJobs 注册路由和启动后台任务
// 如果引擎未启用，此方法将不执行任何操作
func (e *Engine) RegisterRoutesAndJobs(router *gin.RouterGroup) {
	if !e.enabled {
		return // 未启用时，不注册路由，不启动任务
	}

	if e.handler != nil {
		e.handler.registerRoutes(router)
	}
	if e.cleanup != nil {
		e.cleanup.start()
	}
}

// IsEnabled 检查引擎是否启用
func (e *Engine) IsEnabled() bool {
	return e.enabled
}
