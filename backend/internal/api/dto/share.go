package dto

// CreateShareInput 创建分享请求
type CreateShareInput struct {
	MediaUUID      string `json:"media_uuid" binding:"required"`
	TargetUserID   *uint  `json:"target_user_id,omitempty"`
	DurationMinute int    `json:"duration_minute" binding:"required,min=1"`
}

