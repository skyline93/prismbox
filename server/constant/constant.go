package constant

const (
	PreviewVideoSuffix = "_prev.mp4"
	PreviewImageSuffix = "_prev.jpg"
	ThumbSuffix        = "_thumb.jpg"
)

type MediaType string

const (
	TypeImage MediaType = "IMAGE"
	TypeVideo MediaType = "VIDEO"
)

type ProcessingStatus string

const (
	StatusPending   ProcessingStatus = "PENDING"
	StatusCompleted ProcessingStatus = "COMPLETED"
	StatusFailed    ProcessingStatus = "FAILED"
)
