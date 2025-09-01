// server/models/group_models.go

package models

import (
	"time"

	"gorm.io/gorm"
)

// GroupRole 定义了成员在圈子中的角色
type GroupRole string

const (
	RoleOwner  GroupRole = "owner"
	RoleAdmin  GroupRole = "admin"
	RoleMember GroupRole = "member"
)

// Group 对应 PRD 中的 `groups` 表
type Group struct {
	ID             uint           `gorm:"primarykey" json:"id"`
	CreatedAt      time.Time      `json:"created_at"`
	UpdatedAt      time.Time      `json:"updated_at"`
	DeletedAt      gorm.DeletedAt `gorm:"index" json:"-"`
	UUID           string         `gorm:"type:varchar(36);uniqueIndex;not null" json:"uuid"`
	Name           string         `gorm:"type:varchar(100);not null" json:"name"`
	Description    string         `gorm:"type:varchar(255)" json:"description"`
	CoverMediaUUID string         `gorm:"type:varchar(36)" json:"cover_media_uuid"`
	OwnerID        uint           `gorm:"not null" json:"owner_id"`

	Owner   User   `gorm:"foreignKey:OwnerID" json:"-"`
	Members []User `gorm:"many2many:group_members;" json:"-"` // 通过 group_members 表建立多对多关系
}

// GroupMember 对应 PRD 中的 `group_members` 表 (多对多关系枢纽)
type GroupMember struct {
	ID       uint      `gorm:"primarykey" json:"-"`
	GroupID  uint      `gorm:"not null;uniqueIndex:idx_group_user,priority:1" json:"-"` // 复合唯一索引，防止用户重复加入
	UserID   uint      `gorm:"not null;uniqueIndex:idx_group_user,priority:2" json:"user_id"`
	Role     GroupRole `gorm:"type:varchar(20);default:'member';not null" json:"role"`
	JoinedAt time.Time `gorm:"autoCreateTime" json:"joined_at"`
}

// GroupMedia 对应 PRD 中的 `group_media` 表 (媒体引用核心)
type GroupMedia struct {
	ID         uint      `gorm:"primarykey" json:"id"`
	CreatedAt  time.Time `json:"created_at"`
	GroupID    uint      `gorm:"not null;index" json:"group_id"`
	MediaUUID  string    `gorm:"type:varchar(36);not null;index" json:"media_uuid"`
	UploaderID uint      `gorm:"not null" json:"uploader_id"`
	Caption    string    `gorm:"type:varchar(500)" json:"caption"`

	Uploader User      `gorm:"foreignKey:UploaderID" json:"uploader"`             // 预加载上传者信息
	Comments []Comment `gorm:"foreignKey:GroupMediaID" json:"comments,omitempty"` // 预加载评论
}

// GroupInvite 对应 PRD 中的 `group_invites` 表
type GroupInvite struct {
	ID          uint      `gorm:"primarykey" json:"id"`
	CreatedAt   time.Time `json:"created_at"`
	GroupID     uint      `gorm:"not null" json:"group_id"`
	CreatedByID uint      `gorm:"not null" json:"created_by_id"`
	Code        string    `gorm:"type:varchar(20);uniqueIndex;not null" json:"code"`
	ExpiresAt   time.Time `json:"expires_at"`
	UsageLimit  int       `json:"usage_limit"` // 0 表示无限制
}

// Comment 对应 PRD 中的 `comments` 表
type Comment struct {
	ID           uint           `gorm:"primarykey" json:"id"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
	GroupMediaID uint           `gorm:"not null;index" json:"group_media_id"`
	UserID       uint           `gorm:"not null" json:"user_id"`
	Content      string         `gorm:"type:text;not null" json:"content"`

	User User `gorm:"foreignKey:UserID" json:"user"` // 预加载评论者信息
}

type Like struct {
	ID           uint      `gorm:"primarykey" json:"id"`
	CreatedAt    time.Time `json:"created_at"`
	GroupMediaID uint      `gorm:"not null;uniqueIndex:idx_media_user,priority:1" json:"group_media_id"`
	UserID       uint      `gorm:"not null;uniqueIndex:idx_media_user,priority:2" json:"user_id"`
}
