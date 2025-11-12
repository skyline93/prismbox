package models

import (
	"time"
)

// Share 分享模型
type Share struct {
	ID        uint      `gorm:"primarykey" json:"id"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	// 用于公开分享链接的唯一令牌
	ShareToken string `gorm:"type:varchar(36);uniqueIndex;not null" json:"share_token"`

	// 分享的创建者
	OwnerID uint `gorm:"not null" json:"owner_id"`
	Owner   User `gorm:"foreignKey:OwnerID" json:"-"`

	// 分享给谁 (如果为NULL，则为游客分享)
	TargetUserID *uint `gorm:"index" json:"target_user_id"`
	TargetUser   *User `gorm:"foreignKey:TargetUserID" json:"-"`

	// 分享的是哪个媒体
	MediaID uint  `gorm:"not null" json:"media_id"`
	Media   Media `gorm:"foreignKey:MediaID" json:"-"`

	// 分享的过期时间
	ExpiresAt time.Time `json:"expires_at"`

	// 是否已撤销
	IsRevoked bool `gorm:"default:false" json:"is_revoked"`
}

