package models

import (
	"time"

	"gorm.io/gorm"
)

// Media 媒体文件模型
type Media struct {
	gorm.Model

	// 核心字段
	UUID             string  `gorm:"type:varchar(255);uniqueIndex;not null"`
	UserID           uint    `gorm:"index:idx_media_user_hash,unique;index;not null"`
	Hash             string  `gorm:"type:varchar(255);index:idx_media_user_hash,unique;not null"`
	ItemType         string  `gorm:"type:varchar(50);not null"` // "image", "video"
	OriginalFilename string  `gorm:"type:varchar(255)"`
	Filename         string  `gorm:"type:varchar(255)"`
	FileSize         int64   `gorm:"not null"`
	MimeType         string  `gorm:"type:varchar(100)"`
	// Live Photo 视频资产 UUID（仅对图片资产有效，用于指向关联的视频媒体记录）
	LivePhotoVideoUUID *string `gorm:"column:live_photo_video_uuid;type:varchar(255);index"`
	// IsLivePhotoVideo 是否为 Live Photo 附属视频（仅对视频资产有效；在上传该视频时由客户端携带标记写入，用于同步时排除）
	IsLivePhotoVideo bool `gorm:"column:is_live_photo_video;default:false"`

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
	FocalLength  *float64 `gorm:"column:focal_length"` // 焦距 mm（EXIF FocalLength）
	Latitude     *float64
	Longitude    *float64

	// 处理状态
	ProcessingStatus string `gorm:"type:varchar(50);default:'PENDING'"` // "PENDING", "COMPLETED", "FAILED"
	Deleted          bool   `gorm:"default:false"`                      // 业务软删除标志

	// 存储路径（用于 7.2 主存储设计）
	LocalPath     string `gorm:"type:varchar(512)"` // 本地存储路径（hash-based key）
	CloudPath     string `gorm:"type:varchar(512)"` // 云存储路径（备份完成后）
	LocalPoolUUID string `gorm:"type:varchar(255);index"`
	CloudPoolUUID string `gorm:"type:varchar(255);index"`

	// 备份状态（用于 7.4 备份调度器）
	BackupStatus      string `gorm:"type:varchar(50);default:'pending'"` // "pending", "processing", "completed", "failed"
	BackupStartedAt   *time.Time
	BackupCompletedAt *time.Time
	BackupError       string `gorm:"type:text"`

	// ThumbHash 占位符（用于快速加载占位符）
	ThumbHash string `gorm:"column:thumb_hash;type:varchar(200)"` // base64 编码的 ThumbHash，约 100-150 字符
}

// TableName 指定表名
func (Media) TableName() string {
	return "medias"
}
