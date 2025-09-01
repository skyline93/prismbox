package handlers

import (
	"server/constant"
	"time"
)

type MediaResponse struct {
	UUID             string             `json:"uuid"`
	Filename         string             `json:"filename"`
	OriginalFilename string             `json:"original_filename"`
	ItemType         constant.MediaType `json:"item_type"`
	Hash             string             `json:"hash"`
	Width            int                `json:"width"`
	Height           int                `json:"height"`
	CreatedAt        time.Time          `json:"created_at"`
	MediaTakenAt     *time.Time         `json:"media_taken_at"`
	UpdatedAt        time.Time          `json:"updated_at"`
	ThumbnailURL     string             `json:"thumbnail_url"`
	PreviewURL       string             `json:"preview_url"`
	DownloadURL      string             `json:"download_url"`
}

// CheckHashesRequest 是 /media/check_hashes 接口的请求体
type CheckHashesRequest struct {
	Hashes []string `json:"hashes" binding:"required"`
}

// CheckHashesResponse 是 /media/check_hashes 接口的响应体
type CheckHashesResponse struct {
	ExistingHashes []string `json:"existing_hashes"`
}

// MediaChangesResponse 是 /media/changes 接口的响应体
type MediaChangesResponse struct {
	Created []MediaResponse `json:"created"`
	Updated []MediaResponse `json:"updated"`
	Deleted []string        `json:"deleted"` // 删除的媒体只返回 UUID
}
