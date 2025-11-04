package gq

import (
	"database/sql"
	"time"

	"gorm.io/gorm"
)

// Task 是任务队列的数据库模型
type Task struct {
	gorm.Model

	// UUID 用于对外暴露和追踪，避免暴露自增ID
	UUID string `gorm:"type:varchar(36);uniqueIndex;not null"`

	// 任务所属的队列名称
	Queue string `gorm:"type:varchar(255);index;not null"`

	// 任务类型，用于匹配 Handler
	Type string `gorm:"type:varchar(255);not null"`

	// 任务的载荷，以 JSON 格式存储
	Payload []byte `gorm:"type:json"`

	// 任务状态: pending, active, retrying, archived, failed
	Status string `gorm:"type:varchar(50);index;not null"`

	// 任务优先级，数值越大，优先级越高
	Priority int `gorm:"default:0;not null"`

	// 当前重试次数
	RetryCount int `gorm:"default:0"`

	// 最大允许重试次数
	MaxRetries int `gorm:"default:3"`

	// 最后一次执行的错误信息
	LastError string `gorm:"type:text"`

	// 下次处理时间（用于计划任务和重试退避）
	ProcessAt time.Time `gorm:"index"`

	// 处理完成时间
	ProcessedAt sql.NullTime

	// 永久失败时间
	FailedAt sql.NullTime
}

// 任务状态常量
const (
	StatusPending  = "pending"
	StatusActive   = "active"
	StatusRetrying = "retrying"
	StatusArchived = "archived"
	StatusFailed   = "failed"
)

// AutoMigrate 自动迁移数据库表结构
func AutoMigrate(db *gorm.DB) error {
	return db.AutoMigrate(&Task{})
}
