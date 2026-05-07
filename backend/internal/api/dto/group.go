package dto

// CreateGroupInput is the request body to create a group.
// @Description Create group request body
type CreateGroupInput struct {
	Name        string `json:"name" binding:"required" example:"Summer trip"`
	Description string `json:"description" example:"Family vacation 2025"`
}

// UpdateGroupInput is the request body to update a group.
// @Description Update group request body
type UpdateGroupInput struct {
	Name        *string `json:"name" example:"Summer trip (updated)"`
	Description *string `json:"description" example:"Best family trip of 2025"`
}

// JoinGroupInput is the request body to join with an invite code.
// @Description Join group request body
type JoinGroupInput struct {
	Code string `json:"code" binding:"required" example:"A7B3D9K1"`
}

// CreatePostInput is the request body for a new post.
// @Description Create post request body
type CreatePostInput struct {
	MediaUUIDs []string `json:"media_uuids" binding:"required,min=1"`
	Caption    string   `json:"caption"`
}

// CreateCommentInput is the request body for a comment or reply.
// @Description Create comment request body
type CreateCommentInput struct {
	Content         string  `json:"content" binding:"required"`
	ParentCommentID *string `json:"parent_comment_id"`
}
