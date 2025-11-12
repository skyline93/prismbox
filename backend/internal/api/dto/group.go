package dto

// CreateGroupInput 创建圈子请求
type CreateGroupInput struct {
	Name        string `json:"name" binding:"required" example:"巴厘岛假日"`
	Description string `json:"description" example:"2025年的家庭旅行"`
}

// UpdateGroupInput 更新圈子请求
type UpdateGroupInput struct {
	Name        *string `json:"name" example:"巴厘岛假日 updated"`
	Description *string `json:"description" example:"2025年最棒的家庭旅行"`
}

// JoinGroupInput 加入圈子请求
type JoinGroupInput struct {
	Code string `json:"code" binding:"required" example:"A7B3D9K1"`
}

// CreatePostInput 创建帖子请求
type CreatePostInput struct {
	MediaUUIDs []string `json:"media_uuids" binding:"required,min=1"`
	Caption    string   `json:"caption"`
}

// CreateCommentInput 创建评论请求
type CreateCommentInput struct {
	Content         string  `json:"content" binding:"required"`
	ParentCommentID *string `json:"parent_comment_id"`
}

