// replicator/replicator.go

package replicator

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Replicator 是复制器模块的主实例，封装了所有功能组件。
type Replicator struct {
	config  *Config
	handler *syncHandler
	cleanup *cleanupService
}

// New 创建并初始化一个新的复制器实例。
func New(db *gorm.DB, config *Config) *Replicator {
	// 自动迁移所有需要的数据库表
	db.AutoMigrate(&Changelog{}, &ClientSyncStatus{})

	// 初始化内部组件
	syncSvc := newSyncService(db, config)
	syncHdl := newSyncHandler(syncSvc, config)
	cleanupSvc := newCleanupService(db, config)

	return &Replicator{
		config:  config,
		handler: syncHdl,
		cleanup: cleanupSvc,
	}
}

// RegisterRoutesAndJobs 将模块的API路由注册到Gin，并启动后台任务。
func (r *Replicator) RegisterRoutesAndJobs(router *gin.RouterGroup) {
	r.handler.registerRoutes(router)
	r.cleanup.start()
}
