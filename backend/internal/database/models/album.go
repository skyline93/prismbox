package models

import (
	"time"

	"gorm.io/gorm"
)

// AlbumType 相册类型枚举
type AlbumType string

const (
	AlbumTypeNormal        AlbumType = "normal"
	AlbumTypeEncryptedSpace AlbumType = "encrypted_space"
	AlbumTypeCustom        AlbumType = "custom"
)

// Album 相册模型
type Album struct {
	gorm.Model

	// 核心字段
	UUID        string `gorm:"type:varchar(255);uniqueIndex;not null"`
	Name        string `gorm:"type:varchar(255);not null"`
	Description string `gorm:"type:text"`
	UserID      uint   `gorm:"index;not null"`

	// 缩略图
	CoverMediaUUID *string `gorm:"type:varchar(255)"`

	// 活动功能
	IsActivityEnabled bool `gorm:"default:false"`

	// 排序方式
	Order int `gorm:"default:1"`

	// 加密空间相关字段
	IsEncrypted bool      `gorm:"default:false"`
	AlbumType   AlbumType `gorm:"type:varchar(50);default:'normal'"`
	PasswordHash *string  `gorm:"type:varchar(255)"` // bcrypt/Argon2 哈希

	// 关联
	Items []Media `gorm:"many2many:album_items;"`
}

// TableName 指定表名
func (Album) TableName() string {
	return "albums"
}

// AlbumSession 相册会话令牌模型
type AlbumSession struct {
	// 使用自定义主键 UUID，不使用 gorm.Model
	ID        string    `gorm:"type:varchar(255);primaryKey"`
	CreatedAt time.Time `gorm:"not null"`
	UpdatedAt time.Time `gorm:"not null"`

	// 关联字段
	AlbumID string `gorm:"type:varchar(255);index;not null"`
	UserID  uint   `gorm:"index;not null"`

	// 会话令牌（存储哈希值）
	SessionToken string `gorm:"type:varchar(255);uniqueIndex;not null"`

	// 过期时间
	ExpiresAt time.Time `gorm:"not null"`

	// 关联
	Album Album `gorm:"foreignKey:AlbumID;references:UUID"`
	User  User  `gorm:"foreignKey:UserID"`
}

// TableName 指定表名
func (AlbumSession) TableName() string {
	return "album_sessions"
}

