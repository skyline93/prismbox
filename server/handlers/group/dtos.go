// server/handlers/group/dtos.go
// This file contains Data Transfer Objects (DTOs) for group-related handlers.

package group

import (
	"server/handlers"
	"server/models"
	"time"
)

// --- DTOs (Data Transfer Objects) ---

// CreateGroupInput 定义了创建圈子的请求体结构
type CreateGroupInput struct {
	Name        string `json:"name" binding:"required" example:"巴厘岛假日"`
	Description string `json:"description" example:"2025年的家庭旅行"`
}

// UpdateGroupInput 定义了更新圈子信息的请求体结构
type UpdateGroupInput struct {
	Name        *string `json:"name" example:"巴厘岛假日 updated"`
	Description *string `json:"description" example:"2025年最棒的家庭旅行"`
}

// GroupMemberResponse 定义了获取圈子成员列表时的响应结构，过滤了敏感信息
type GroupMemberResponse struct {
	UserID   uint             `json:"user_id"`
	Username string           `json:"username"`
	Role     models.GroupRole `json:"role"`
	JoinedAt time.Time        `json:"joined_at"`
}

// JoinGroupInput 定义了使用邀请码加入圈子的请求体结构
type JoinGroupInput struct {
	Code string `json:"code" binding:"required" example:"A7B3D9K1"`
}

// ShareMediaInput 定义了分享媒体到圈子的请求体结构
type ShareMediaInput struct {
	MediaUUIDs []string `json:"media_uuids" binding:"required"`
	Caption    string   `json:"caption,omitempty"`
}

// GroupFeedItemResponse 定义了圈子 Feed 流中单个媒体项的响应结构
type GroupFeedItemResponse struct {
	GroupMediaID  uint                   `json:"group_media_id"`
	Caption       string                 `json:"caption"`
	SharedAt      time.Time              `json:"shared_at"`
	LikesCount    int64                  `json:"likes_count"`
	CommentsCount int64                  `json:"comments_count"`
	Uploader      UploaderInfo           `json:"uploader"`
	MediaDetails  handlers.MediaResponse `json:"media_details"`
}

// UploaderInfo 嵌套在 GroupFeedItemResponse 中，用于表示上传者信息
type UploaderInfo struct {
	UserID    uint   `json:"user_id"`
	Username  string `json:"username"`
	AvatarURL string `json:"avatar_url"`
}

// CreateCommentInput 定义了创建评论的请求体结构
// type CreateCommentInput struct {
// 	Content string `json:"content" binding:"required"`
// }

// // CommentResponse 定义了获取评论列表时的响应结构
// type CommentResponse struct {
// 	ID        uint      `json:"id"`
// 	CreatedAt time.Time `json:"created_at"`
// 	Content   string    `json:"content"`
// 	User      UserInfo  `json:"user"`
// }

// UserInfo 嵌套在 CommentResponse 中，用于表示评论者信息
type UserInfo struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
}

// GroupDetailResponse 定义了获取圈子详情时的响应结构
// 它包含了圈子的基础信息，并附加了当前请求者的上下文信息（如角色）
type GroupDetailResponse struct {
	// 继承自 models.Group 的字段
	UUID           string    `json:"uuid"`
	Name           string    `json:"name"`
	Description    string    `json:"description"`
	CoverMediaUUID string    `json:"cover_media_uuid"`
	OwnerID        uint      `json:"owner_id"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`

	// 动态聚合的字段
	MemberCount int64 `json:"member_count"` // 成员总数

	// 针对当前请求者的上下文信息
	CurrentUserID   uint             `json:"current_user_id"`
	CurrentUserRole models.GroupRole `json:"current_user_role"`
}
