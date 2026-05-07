package dto

// CreateShareInput is the body for creating a share link.
// @Description Create share link request body
type CreateShareInput struct {
	MediaUUID      string `json:"media_uuid" binding:"required"`
	TargetUserID   *uint  `json:"target_user_id,omitempty"`
	DurationMinute int    `json:"duration_minute" binding:"required,min=1"`
}

