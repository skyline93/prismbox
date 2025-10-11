package constant

const (
	PreviewVideoSuffix = "_prev.mp4"
	PreviewImageSuffix = "_prev.jpg"
	ThumbSuffix        = "_thumb.jpg"
)

type MediaType string

const (
	TypeImage MediaType = "image"
	TypeVideo MediaType = "video"
)

type ProcessingStatus string

const (
	StatusPending   ProcessingStatus = "PENDING"
	StatusCompleted ProcessingStatus = "COMPLETED"
	StatusFailed    ProcessingStatus = "FAILED"
)
