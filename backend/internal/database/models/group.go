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

// GroupPost 对应圈子中的帖子
type GroupPost struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	GroupID   uint           `gorm:"not null;index" json:"group_id"`
	CreatorID uint           `gorm:"not null" json:"creator_id"`
	Caption   string         `gorm:"type:varchar(500)" json:"caption"`

	Creator  User         `gorm:"foreignKey:CreatorID" json:"creator"`         // 预加载创建者信息
	Media    []GroupMedia `gorm:"foreignKey:PostID" json:"media"`              // 一个帖子包含多个媒体
	Comments []Comment    `gorm:"foreignKey:PostID" json:"comments,omitempty"` // 预加载评论
	Likes    []Like       `gorm:"foreignKey:PostID" json:"-"`

	Group Group `gorm:"foreignKey:GroupID" json:"-"`
}

// GroupMedia 对应 PRD 中的 `group_media` 表 (媒体引用核心)
type GroupMedia struct {
	ID        uint      `gorm:"primarykey" json:"id"`
	CreatedAt time.Time `json:"created_at"`
	GroupID   uint      `gorm:"not null;index" json:"group_id"` // 保留 GroupID 以便快速按圈子过滤
	PostID    uint      `gorm:"not null;index" json:"post_id"`  // 关联到 GroupPost
	MediaUUID string    `gorm:"type:varchar(36);not null;index" json:"media_uuid"`
}

// Comment 对应圈子帖子中的评论
type Comment struct {
	ID        uint           `gorm:"primarykey" json:"id"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
	PostID    uint           `gorm:"not null;index" json:"post_id"`
	UserID    uint           `gorm:"not null" json:"user_id"`
	Content   string         `gorm:"type:text;not null" json:"content"`

	// 用于支持嵌套评论
	ParentCommentID *uint `gorm:"index" json:"parent_comment_id"` // 使用指针，因为顶级评论没有父ID

	User    User          `gorm:"foreignKey:UserID" json:"user"`
	Post    GroupPost     `gorm:"foreignKey:PostID" json:"-"`
	Replies []Comment     `gorm:"foreignKey:ParentCommentID" json:"-"` // GORM关联，用于预加载
	Likes   []CommentLike `gorm:"foreignKey:CommentID" json:"-"`
}

// CommentLike 用于记录评论的点赞
type CommentLike struct {
	ID        uint      `gorm:"primarykey" json:"id"`
	CreatedAt time.Time `json:"created_at"`
	CommentID uint      `gorm:"not null;uniqueIndex:idx_comment_user,priority:1" json:"comment_id"`
	UserID    uint      `gorm:"not null;uniqueIndex:idx_comment_user,priority:2" json:"user_id"`
}

// Like 用于记录帖子的点赞
type Like struct {
	ID        uint      `gorm:"primarykey" json:"id"`
	CreatedAt time.Time `json:"created_at"`
	PostID    uint      `gorm:"not null;uniqueIndex:idx_post_user,priority:1" json:"post_id"`
	UserID    uint      `gorm:"not null;uniqueIndex:idx_post_user,priority:2" json:"user_id"`
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

