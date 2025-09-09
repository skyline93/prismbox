// models/models.go

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
	Password  string         `json:"-"`
	Avatar    string         `gorm:"type:varchar(255)" json:"avatar"`
}

type RefreshToken struct {
	ID        uint `gorm:"primarykey"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	UserID    uint `gorm:"not null;index"`
	User      User
	Token     string `gorm:"type:varchar(512);uniqueIndex;not null"`
	ExpiresAt time.Time
	IsRevoked bool `gorm:"default:false"`
}

type Media struct {
	ID               uint                      `gorm:"primarykey" json:"id"`
	CreatedAt        time.Time                 `json:"created_at"`
	UpdatedAt        time.Time                 `json:"updated_at"`
	DeletedAt        gorm.DeletedAt            `gorm:"index" json:"-"`
	UUID             string                    `gorm:"type:varchar(36);uniqueIndex" json:"uuid"`
	UserID           uint                      `gorm:"index" json:"user_id"`
	Hash             string                    `gorm:"uniqueIndex:idx_user_hash,priority:2" json:"hash"`
	ItemType         constant.MediaType        `json:"item_type"`
	OriginalFilename string                    `json:"original_filename"`
	Filename         string                    `json:"filename"`
	FileSize         int64                     `json:"file_size"`
	MimeType         string                    `json:"mime_type"`
	Width            int                       `json:"width"`
	Height           int                       `json:"height"`
	Duration         float64                   `json:"duration"`
	MediaTakenAt     *time.Time                `json:"media_taken_at"`
	CameraMake       *string                   `json:"camera_make"`
	CameraModel      *string                   `json:"camera_model"`
	Aperture         *string                   `json:"aperture"`
	ShutterSpeed     *string                   `json:"shutter_speed"`
	ISO              *int                      `json:"iso"`
	Latitude         *float64                  `json:"latitude"`
	Longitude        *float64                  `json:"longitude"`
	ProcessingStatus constant.ProcessingStatus `json:"processing_status"`
}

type Album struct {
	ID             uint           `gorm:"primarykey" json:"id"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
	UUID           string         `gorm:"type:varchar(36);uniqueIndex" json:"uuid"`
	Name           string         `json:"name"`
	Description    string         `json:"description"`
	UserID         uint           `gorm:"index" json:"user_id"` // ❗ 核心改动: 关联用户
	CoverMediaUUID *string        `json:"cover_media_uuid"`
	Items          []*Media       `gorm:"many2many:album_items;" json:"items,omitempty"`
	ItemCount      int64          `gorm:"-" json:"item_count"`
}

type Share struct {
	ID        uint `gorm:"primarykey"`
	CreatedAt time.Time
	UpdatedAt time.Time

	// 用于公开分享链接的唯一令牌
	ShareToken string `gorm:"type:varchar(36);uniqueIndex;not null"`

	// 分享的创建者
	OwnerID uint `gorm:"not null"`
	Owner   User `gorm:"foreignKey:OwnerID"`

	// 分享给谁 (如果为NULL，则为游客分享)
	TargetUserID *uint `gorm:"index"`
	TargetUser   *User `gorm:"foreignKey:TargetUserID"`

	// 分享的是哪个照片
	MediaID uint  `gorm:"not null"`
	Media   Media `gorm:"foreignKey:MediaID"`

	// 分享的过期时间
	ExpiresAt time.Time

	// 是否已被创建者手动撤销
	IsRevoked bool `gorm:"default:false"`
}

// UploadTask 用于追踪正在进行中的分片上传作业
type UploadTask struct {
	ID        string `gorm:"primaryKey;type:varchar(36)"` // Unique Upload ID (UUID)
	UserID    uint   `gorm:"index"`
	FileHash  string `gorm:"index;type:varchar(64)"` // SHA256 hash of the complete file
	TotalSize int64
	ChunkSize int
	NumChunks int
	Status    string `gorm:"type:varchar(20)"` // INITIATED, COMPLETED, FAILED
	CreatedAt time.Time
	ExpiresAt time.Time `gorm:"index"` // 用于清理任务，防止产生垃圾数据
}
