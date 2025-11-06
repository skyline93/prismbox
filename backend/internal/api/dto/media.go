package dto

// MediaResponse 媒体响应
type MediaResponse struct {
	UUID             string `json:"uuid"`
	UserID           uint   `json:"user_id"`
	Hash             string `json:"hash"`
	ItemType         string `json:"item_type"`
	OriginalFilename string `json:"original_filename"`
	Filename         string `json:"filename"`
	FileSize         int64  `json:"file_size"`
	MimeType         string `json:"mime_type"`
	ProcessingStatus string `json:"processing_status"`
	LocalPath        string `json:"local_path"`
	BackupStatus     string `json:"backup_status"`
	CreatedAt        string `json:"created_at"`
}
