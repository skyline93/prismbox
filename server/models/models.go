package models

import (
	"server/constant"
	"time"

	"gorm.io/gorm"
)

type User struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	CreatedAt time.Time      `json:"-"`
	UpdatedAt time.Time      `json:"-"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	Username  string         `gorm:"type:varchar(100);uniqueIndex" json:"username"`
	Email     string         `gorm:"type:varchar(255);uniqueIndex" json:"email"`
	Password  string         `json:"-"` // 从不将密码暴露在JSON中
}

// --- Photo 模型升级: 添加 UserID ---
type Photo struct {
	ID               uint                      `gorm:"primarykey" json:"id"`
	CreatedAt        time.Time                 `json:"created_at"`
	UpdatedAt        time.Time                 `json:"updated_at"`
	DeletedAt        gorm.DeletedAt            `gorm:"index" json:"-"`
	UUID             string                    `gorm:"type:varchar(36);uniqueIndex" json:"uuid"`
	UserID           uint                      `gorm:"index" json:"user_id"`                             // ❗ 核心改动: 关联用户
	Hash             string                    `gorm:"uniqueIndex:idx_user_hash,priority:2" json:"hash"` // 联合唯一索引
	ItemType         constant.MediaType        `json:"item_type"`
	OriginalFilename string                    `json:"original_filename"`
	Filename         string                    `json:"filename"`
	FileSize         int64                     `json:"file_size"`
	MimeType         string                    `json:"mime_type"`
	Width            int                       `json:"width"`
	Height           int                       `json:"height"`
	Duration         float64                   `json:"duration"`
	PhotoTakenAt     *time.Time                `json:"photo_taken_at"`
	CameraMake       *string                   `json:"camera_make"`
	CameraModel      *string                   `json:"camera_model"`
	Aperture         *string                   `json:"aperture"`
	ShutterSpeed     *string                   `json:"shutter_speed"`
	ISO              *int                      `json:"iso"`
	Latitude         *float64                  `json:"latitude"`
	Longitude        *float64                  `json:"longitude"`
	ProcessingStatus constant.ProcessingStatus `json:"processing_status"`
}

// --- Album 模型升级: 添加 UserID ---
type Album struct {
	ID             uint           `gorm:"primarykey" json:"id"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
	UUID           string         `gorm:"type:varchar(36);uniqueIndex" json:"uuid"`
	Name           string         `json:"name"`
	Description    string         `json:"description"`
	UserID         uint           `gorm:"index" json:"user_id"` // ❗ 核心改动: 关联用户
	CoverPhotoUUID *string        `json:"cover_photo_uuid"`
	Items          []*Photo       `gorm:"many2many:album_items;" json:"items,omitempty"`
	ItemCount      int64          `gorm:"-" json:"item_count"`
}
