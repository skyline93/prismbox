package models

import (
	"fmt"
	"time"

	"gorm.io/gorm"
)

// Media 媒体文件模型
type Media struct {
	gorm.Model

	// 核心字段
	UUID             string `gorm:"type:varchar(255);uniqueIndex;not null"`
	UserID           uint   `gorm:"index:idx_media_user_hash,unique;index;not null"`
	Hash             string `gorm:"type:varchar(255);index:idx_media_user_hash,unique;not null"`
	ItemType         string `gorm:"type:varchar(50);not null"` // "image", "video"
	OriginalFilename string `gorm:"type:varchar(255)"`
	Filename         string `gorm:"type:varchar(255)"`
	FileSize         int64  `gorm:"not null"`
	MimeType         string `gorm:"type:varchar(100)"`

	// 媒体元数据
	Width        int
	Height       int
	Duration     *float64
	MediaTakenAt *time.Time
	CameraMake   *string
	CameraModel  *string
	Aperture     *string
	ShutterSpeed *string
	ISO          *int
	Latitude     *float64
	Longitude    *float64

	// 处理状态
	ProcessingStatus string `gorm:"type:varchar(50);default:'PENDING'"` // "PENDING", "COMPLETED", "FAILED"
	Deleted          bool   `gorm:"default:false"`                      // 业务软删除标志

	// 存储路径（用于 7.2 主存储设计）
	LocalPath string `gorm:"type:varchar(512)"` // 本地存储路径
	CloudPath string `gorm:"type:varchar(512)"` // 云存储路径（备份完成后）

	// 备份状态（用于 7.4 备份调度器）
	BackupStatus      string `gorm:"type:varchar(50);default:'pending'"` // "pending", "processing", "completed", "failed"
	BackupStartedAt   *time.Time
	BackupCompletedAt *time.Time
	BackupError       string `gorm:"type:text"`
}

// TableName 指定表名
func (Media) TableName() string {
	return "medias"
}

// GetRecordID 实现 changelog.SyncedModel 接口
func (m *Media) GetRecordID() string {
	return m.UUID
}

// GetTableName 实现 changelog.SyncedModel 接口
func (m *Media) GetTableName() string {
	return "medias"
}

// GetIsolationKey 实现 changelog.SyncedModel 接口
// 返回隔离字段名，Media 使用 user_id 作为隔离字段
func (m *Media) GetIsolationKey() string {
	return "user_id"
}

// GetIsolationValue 实现 changelog.SyncedModel 接口
// 返回用户ID作为隔离值
func (m *Media) GetIsolationValue() string {
	return fmt.Sprintf("%d", m.UserID)
}
