package dto

// MediaResponse 媒体响应
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
	ThumbnailURL     string  `json:"thumbnail_url,omitempty"`
	PreviewURL       string  `json:"preview_url,omitempty"`
	DownloadURL      string  `json:"download_url,omitempty"`
}

// GetMediasRequest 获取媒体列表请求
type GetMediasRequest struct {
	Page     int    `form:"page" binding:"omitempty,min=1"`
	PageSize int    `form:"page_size" binding:"omitempty,min=1,max=100"`
	ItemType string `form:"item_type" binding:"omitempty,oneof=image video"`
}

// GetMediasResponse 获取媒体列表响应
type GetMediasResponse struct {
	Medias   []*MediaResponse `json:"medias"`
	Total    int              `json:"total"`
	Page     int              `json:"page"`
	PageSize int              `json:"page_size"`
}

// CheckHashesRequest 检查哈希请求
type CheckHashesRequest struct {
	Hashes []string `json:"hashes" binding:"required,min=1"`
}

// CheckHashesResponse 检查哈希响应
type CheckHashesResponse struct {
	ExistingHashes []string `json:"existing_hashes"`
	MissingHashes  []string `json:"missing_hashes"`
}

// GetChangesRequest 获取媒体变更请求
type GetChangesRequest struct {
	Since string `form:"since"` // RFC3339格式的时间戳
}

// MediaChange 媒体变更
type MediaChange struct {
	UUID      string `json:"uuid"`
	Hash      string `json:"hash"`
	ItemType  string `json:"item_type"`
	Action    string `json:"action"` // "created", "updated", "deleted"
	UpdatedAt string `json:"updated_at"`
}

// GetChangesResponse 获取媒体变更响应
type GetChangesResponse struct {
	Changes []*MediaChange `json:"changes"`
	Since   string         `json:"since"`
}
