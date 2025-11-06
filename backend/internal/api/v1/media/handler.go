package media

import (
	"fmt"
	"strings"
	"time"

	"github.com/album/backend/internal/api/dto"
	apiresponse "github.com/album/backend/internal/api/response"
	mediaservice "github.com/album/backend/internal/service/media"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
)

// Handler 媒体处理器
type Handler struct {
	mediaService mediaservice.Service
	log          logger.Logger
}

// NewHandler 创建媒体处理器
func NewHandler(mediaService mediaservice.Service) *Handler {
	return &Handler{
		mediaService: mediaService,
		log:          logger.New("api.v1.media"),
	}
}

// UploadMedia 上传媒体文件（与旧架构接口一致）
func (h *Handler) UploadMedia(c *gin.Context) {
	// TODO: 实现用户认证，从JWT token中获取userID
	// 目前先使用默认的userID = 1
	userID := uint(1)

	// 1. 获取表单参数（与旧架构一致）
	hash := c.PostForm("hash")
	itemTypeStr := c.PostForm("item_type")
	originalFilename := c.PostForm("original_filename")
	cloudUUID := c.PostForm("cloud_uuid")
	mediaTakenAtStr := c.PostForm("media_taken_at")

	// 2. 校验必填参数
	if hash == "" {
		apiresponse.Error(c, "Form field 'hash' is required")
		return
	}
	// 验证Hash格式（SHA256应该是64个字符的十六进制字符串）
	if len(hash) != 64 {
		apiresponse.Error(c, "Invalid 'hash' format. Must be a 64-character hexadecimal string (SHA256)")
		return
	}
	if cloudUUID == "" {
		apiresponse.Error(c, "Form field 'cloud_uuid' is required")
		return
	}
	if itemTypeStr == "" {
		apiresponse.Error(c, "Form field 'item_type' is required")
		return
	}

	// 3. 验证item_type
	itemType := strings.ToLower(itemTypeStr)
	if itemType != "image" && itemType != "video" {
		apiresponse.Error(c, "Invalid 'item_type'. Must be 'image' or 'video'")
		return
	}

	// 4. 解析媒体拍摄时间（可选）
	var mediaTakenAt *time.Time
	if mediaTakenAtStr != "" {
		parsed, err := time.Parse(time.RFC3339, mediaTakenAtStr)
		if err == nil {
			mediaTakenAt = &parsed
		} else {
			h.log.Warn("failed to parse media_taken_at",
				logger.String("media_taken_at", mediaTakenAtStr),
				logger.Error(err),
			)
		}
	}

	// 5. 秒传检查（在打开文件流之前，优化性能）
	existingMedia, err := h.mediaService.CheckInstantUpload(c.Request.Context(), userID, hash)
	if err != nil {
		h.log.Error("failed to check instant upload",
			logger.Error(err),
			logger.String("hash", hash),
			logger.Uint("user_id", userID),
		)
		apiresponse.Error(c, "Database error during hash check")
		return
	}
	if existingMedia != nil {
		// 文件已存在，秒传成功，直接返回（不需要打开文件流）
		response := &dto.MediaResponse{
			UUID:             existingMedia.UUID,
			UserID:           existingMedia.UserID,
			Hash:             existingMedia.Hash,
			ItemType:         existingMedia.ItemType,
			OriginalFilename: existingMedia.OriginalFilename,
			Filename:         existingMedia.Filename,
			FileSize:         existingMedia.FileSize,
			MimeType:         existingMedia.MimeType,
			ProcessingStatus: existingMedia.ProcessingStatus,
			LocalPath:        existingMedia.LocalPath,
			BackupStatus:     existingMedia.BackupStatus,
			CreatedAt:        existingMedia.CreatedAt.Format(time.RFC3339),
		}
		h.log.Info("media instant upload (file already exists)",
			logger.String("uuid", existingMedia.UUID),
			logger.String("requested_uuid", cloudUUID),
			logger.String("hash", hash),
			logger.Uint("user_id", userID),
		)
		apiresponse.Success(c, "File already exists for this user", response)
		return
	}

	// 6. 获取上传的文件（只有在不是秒传时才需要）
	file, err := c.FormFile("file")
	if err != nil {
		h.log.Error("failed to get uploaded file",
			logger.Error(err),
		)
		apiresponse.Error(c, "Missing file in request")
		return
	}

	// 7. 打开文件流（流式处理）
	src, err := file.Open()
	if err != nil {
		h.log.Error("failed to open uploaded file",
			logger.Error(err),
			logger.String("filename", file.Filename),
		)
		apiresponse.Error(c, "Failed to open file")
		return
	}
	defer src.Close()

	// 8. 调用Service层上传媒体（传入所有参数）
	media, err := h.mediaService.UploadMedia(c.Request.Context(), &mediaservice.UploadMediaRequest{
		UserID:           userID,
		Hash:             hash,
		ItemType:         itemType,
		OriginalFilename: originalFilename,
		CloudUUID:        cloudUUID,
		MediaTakenAt:     mediaTakenAt,
		Filename:         file.Filename,
		FileSize:         file.Size,
		Data:             src,
	})
	if err != nil {
		h.log.Error("failed to upload media",
			logger.Error(err),
			logger.String("filename", file.Filename),
			logger.Uint("user_id", userID),
		)
		apiresponse.Error(c, fmt.Sprintf("Failed to upload media: %v", err))
		return
	}

	// 9. 转换为响应格式
	response := &dto.MediaResponse{
		UUID:             media.UUID,
		UserID:           media.UserID,
		Hash:             media.Hash,
		ItemType:         media.ItemType,
		OriginalFilename: media.OriginalFilename,
		Filename:         media.Filename,
		FileSize:         media.FileSize,
		MimeType:         media.MimeType,
		ProcessingStatus: media.ProcessingStatus,
		LocalPath:        media.LocalPath,
		BackupStatus:     media.BackupStatus,
		CreatedAt:        media.CreatedAt.Format(time.RFC3339),
	}

	// 10. 新上传成功，返回201
	h.log.Info("media uploaded successfully",
		logger.String("uuid", media.UUID),
		logger.String("filename", file.Filename),
		logger.Uint("user_id", userID),
	)
	apiresponse.Created(c, "Media uploaded successfully", response)
}

// GetMedia 获取媒体信息
func (h *Handler) GetMedia(c *gin.Context) {
	// TODO: 实现获取媒体信息
	apiresponse.Error(c, "Not implemented")
}

// GetMedias 获取媒体列表
func (h *Handler) GetMedias(c *gin.Context) {
	// TODO: 实现获取媒体列表
	apiresponse.Error(c, "Not implemented")
}

// DeleteMedia 删除媒体
func (h *Handler) DeleteMedia(c *gin.Context) {
	// TODO: 实现删除媒体
	apiresponse.Error(c, "Not implemented")
}
