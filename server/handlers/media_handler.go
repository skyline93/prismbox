// handlers/media_handler.go

package handlers

import (
	"server/models"
	"server/routing"
	"server/urlsigner"
	"time"

	"gorm.io/gorm"
)

const (
	defaultPageSize = 100
	iso8601Format   = time.RFC3339
)

// MediaHandler 封装了所有与照片/视频相关的HTTP处理器
type MediaHandler struct {
	MediaRepo MediaRepositoryInterface

	DB        *gorm.DB
	UploadDir string

	URLSigner        *urlsigner.Signer
	URLBuilder       *routing.URLBuilder
	SignedURLLoadTTL time.Duration
}

func NewMediaHandler(
	mediaRepo MediaRepositoryInterface,
	db *gorm.DB,
	uploadDir string,
	urlSigner *urlsigner.Signer,
	urlBuilder *routing.URLBuilder,
	signedURLLoadTTL time.Duration,

) *MediaHandler {
	return &MediaHandler{
		MediaRepo:        mediaRepo,
		DB:               db,
		UploadDir:        uploadDir,
		URLSigner:        urlSigner,
		URLBuilder:       urlBuilder,
		SignedURLLoadTTL: signedURLLoadTTL,
	}
}

// buildMediaResponse 是一个辅助函数，用于根据媒体对象构建标准的API响应结构。
// 它会为不同类型的媒体资源（缩略图、预览图、原始文件）生成带签名的URL。
func (h *MediaHandler) buildMediaResponse(userID uint, media models.Media) *MediaResponse {

	thumbnailPath := h.URLBuilder.BuildMediaThumbnailPath(media.UUID)
	previewPath := h.URLBuilder.BuildMediaPreviewPath(media.UUID)
	originalPath := h.URLBuilder.BuildMediaOriginalPath(media.UUID)

	thumbnailSignedURL, err := h.URLSigner.Generate(thumbnailPath, userID, h.SignedURLLoadTTL)
	if err != nil {
		return nil
	}

	previewSignedURL, err := h.URLSigner.Generate(previewPath, userID, h.SignedURLLoadTTL)
	if err != nil {
		return nil
	}

	originalSignedURL, err := h.URLSigner.Generate(originalPath, userID, h.SignedURLLoadTTL)
	if err != nil {
		return nil
	}

	resp := &MediaResponse{
		UUID:             media.UUID,
		Filename:         media.Filename,
		OriginalFilename: media.OriginalFilename,
		ItemType:         media.ItemType,
		Hash:             media.Hash,
		CreatedAt:        media.CreatedAt,
		MediaTakenAt:     media.MediaTakenAt,
		UpdatedAt:        media.UpdatedAt,
		ThumbnailURL:     thumbnailSignedURL,
		PreviewURL:       previewSignedURL,
		DownloadURL:      originalSignedURL,
	}

	return resp
}

// buildMediaResponses 是一个辅助函数，用于将一个媒体对象切片转换为API响应结构切片。
func (h *MediaHandler) buildMediaResponses(userID uint, medias []models.Media) []MediaResponse {
	mediaResponses := make([]MediaResponse, 0, len(medias))

	for _, media := range medias {
		resp := h.buildMediaResponse(userID, media)
		mediaResponses = append(mediaResponses, *resp)
	}

	return mediaResponses
}
