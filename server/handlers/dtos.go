// handlers/dtos.go

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

// InitiateUploadRequest 是 /media/upload/initiate 接口的请求体
type InitiateUploadRequest struct {
	OriginalFilename string             `json:"original_filename" binding:"required"`
	Hash             string             `json:"hash" binding:"required"`
	TotalSize        int64              `json:"total_size" binding:"required"`
	ItemType         constant.MediaType `json:"item_type" binding:"required"`
}

// InitiateUploadResponse 是 /media/upload/initiate 接口在需要上传文件时的响应体
type InitiateUploadResponse struct {
	UploadID       string `json:"upload_id"`
	ChunkSize      int    `json:"chunk_size"`
	UploadedChunks []int  `json:"uploaded_chunks"`
}

// CompleteUploadRequest 是 /media/upload/complete 接口的请求体
type CompleteUploadRequest struct {
	UploadID         string             `json:"upload_id" binding:"required"`
	OriginalFilename string             `json:"original_filename" binding:"required"`
	Hash             string             `json:"hash" binding:"required"`
	ItemType         constant.MediaType `json:"item_type" binding:"required"`
}
