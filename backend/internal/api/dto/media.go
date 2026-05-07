package dto

// MediaResponse is the API representation of a media item.
// @Description Media item metadata
type MediaResponse struct {
	UUID             string  `json:"uuid"`
	UserID           uint    `json:"user_id"`
	Hash             string  `json:"hash"`
	ItemType         string  `json:"item_type"`
	OriginalFilename string  `json:"original_filename"`
	Filename         string  `json:"filename"`
	FileSize         int64   `json:"file_size"`
	MimeType         string  `json:"mime_type"`
	ProcessingStatus string  `json:"processing_status"`
	LocalPath        string  `json:"local_path"`
	BackupStatus     string  `json:"backup_status"`
	CreatedAt        string  `json:"created_at"`
	UpdatedAt        string  `json:"updated_at"`
	Width            int     `json:"width"`
	Height           int     `json:"height"`
	MediaTakenAt     *string `json:"media_taken_at,omitempty"`
	ThumbHash        string  `json:"thumb_hash,omitempty"` // ThumbHash placeholder (base64)
	ThumbnailURL     string  `json:"thumbnail_url,omitempty"`
	PreviewURL       string  `json:"preview_url,omitempty"`
	DownloadURL      string  `json:"download_url,omitempty"`
	// Live Photo: linked video UUID on the image asset
	LivePhotoVideoID *string `json:"live_photo_video_id,omitempty"`
}

// GetMediasRequest holds query parameters for listing media.
// @Description List media query parameters
type GetMediasRequest struct {
	Page     int    `form:"page" binding:"omitempty,min=1"`
	PageSize int    `form:"page_size" binding:"omitempty,min=1,max=100"`
	ItemType string `form:"item_type" binding:"omitempty,oneof=image video"`
}

// GetMediasResponse is a paginated list of media.
// @Description Paginated media list
type GetMediasResponse struct {
	Medias   []*MediaResponse `json:"medias"`
	Total    int              `json:"total"`
	Page     int              `json:"page"`
	PageSize int              `json:"page_size"`
}

// CheckHashesRequest is the body for batch hash existence checks.
// @Description Check hashes request body
type CheckHashesRequest struct {
	Hashes []string `json:"hashes" binding:"required,min=1"`
}

// CheckHashesResponse reports which hashes exist on the server.
// @Description Check hashes response
type CheckHashesResponse struct {
	ExistingHashes []string `json:"existing_hashes"` // Hashes that already exist
	MissingHashes  []string `json:"missing_hashes"`  // Hashes not yet stored
	TotalCount     int      `json:"total_count"`     // Total requested
	ExistingCount  int      `json:"existing_count"`  // Count existing
	MissingCount   int      `json:"missing_count"`   // Count missing
}

// GetChangesRequest holds query parameters for the changes feed.
// @Description Media changes query parameters
type GetChangesRequest struct {
	Since string `form:"since"` // RFC3339 timestamp
}

// MediaChange is one change record in the feed.
// @Description Single media change record
type MediaChange struct {
	UUID      string `json:"uuid"`
	Hash      string `json:"hash"`
	ItemType  string `json:"item_type"`
	Action    string `json:"action"` // "created", "updated", "deleted"
	UpdatedAt string `json:"updated_at"`
}

// GetChangesResponse wraps the list of changes since a point in time.
// @Description Media changes response
type GetChangesResponse struct {
	Changes []*MediaChange `json:"changes"`
	Since   string         `json:"since"`
}
