package models

import (
	"time"

	"gorm.io/gorm"
)

// User 表示系统中的用户账户。
type User struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"-"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`

	Username string `gorm:"type:varchar(100);uniqueIndex;null" json:"username,omitempty"`
	Email    string `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	Password string `gorm:"type:varchar(255);null" json:"-"`

	Avatar        string         `gorm:"type:varchar(255)" json:"avatar"`
	AuthProviders []AuthProvider `json:"-"`
}

// AuthProvider 记录第三方认证提供商信息。
type AuthProvider struct {
	gorm.Model

	UserID uint `gorm:"not null;uniqueIndex:idx_provider_user_id"`
	User   User `gorm:"foreignKey:UserID"`

	ProviderName   string `gorm:"type:varchar(50);not null;uniqueIndex:idx_provider_user_id"`
	ProviderUserID string `gorm:"type:text;not null"`
}

// RefreshToken 用于存储刷新令牌。
type RefreshToken struct {
	ID        uint `gorm:"primarykey"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	UserID    uint `gorm:"not null;index"`
	User      User
	Token     string    `gorm:"type:varchar(512);uniqueIndex;not null"`
	ExpiresAt time.Time `gorm:"not null"`
	IsRevoked bool      `gorm:"default:false"`
}
