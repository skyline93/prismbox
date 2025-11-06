package models

import (
	"time"

	"gorm.io/gorm"
)

// Media 媒体文件模型
type Media struct {
	gorm.Model

	// 核心字段
	UUID             string `gorm:"type:varchar(255);uniqueIndex;not null"`
	UserID           uint   `gorm:"index;not null"`
	Hash             string `gorm:"type:varchar(255);not null"`
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

// Indexes 定义索引（通过 GORM 标签）
// - UUID 唯一索引（已通过 uniqueIndex 标签定义）
// - UserID 索引（已通过 index 标签定义）
// - 复合唯一索引：UserID + Hash（需要单独定义）
func (Media) BeforeCreate(tx *gorm.DB) error {
	// 确保复合唯一索引存在
	if err := tx.Exec("CREATE UNIQUE INDEX IF NOT EXISTS idx_user_hash ON medias(user_id, hash)").Error; err != nil {
		// 忽略错误，可能索引已存在
	}
	return nil
}
