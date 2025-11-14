package media

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/album/backend/internal/api/dto"
	"github.com/album/backend/internal/api/middleware"
	apiresponse "github.com/album/backend/internal/api/response"
	mediaservice "github.com/album/backend/internal/service/media"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
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
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

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
		if err != nil {
			h.log.Error("invalid media_taken_at format",
				logger.String("media_taken_at", mediaTakenAtStr),
				logger.Error(err),
			)
			apiresponse.Error(c, "Invalid 'media_taken_at' format. Must be RFC3339 format (e.g., 2025-09-17T14:28:29.000Z)")
			return
		}
		// 统一转换为 UTC 存储
		utcTime := parsed.UTC()
		mediaTakenAt = &utcTime
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

// GetMedias 获取媒体列表
func (h *Handler) GetMedias(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 1. 解析请求参数
	var req dto.GetMediasRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		apiresponse.Error(c, "Invalid request parameters")
		return
	}

	// 2. 设置默认值
	if req.Page < 1 {
		req.Page = 1
	}
	if req.PageSize < 1 {
		req.PageSize = 20
	}
	if req.PageSize > 100 {
		req.PageSize = 100
	}

	// 3. 调用Service层
	result, err := h.mediaService.GetMedias(c.Request.Context(), &mediaservice.GetMediasRequest{
		UserID:   userID,
		Page:     req.Page,
		PageSize: req.PageSize,
		ItemType: strings.ToLower(req.ItemType),
	})
	if err != nil {
		h.log.Error("failed to get medias",
			logger.Error(err),
			logger.Uint("user_id", userID),
		)
		apiresponse.Error(c, "Failed to get medias")
		return
	}

	// 4. 转换为响应格式
	medias := make([]*dto.MediaResponse, 0, len(result.Medias))
	for _, media := range result.Medias {
		medias = append(medias, &dto.MediaResponse{
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
		})
	}

	response := &dto.GetMediasResponse{
		Medias:   medias,
		Total:    result.Total,
		Page:     result.Page,
		PageSize: result.PageSize,
	}

	apiresponse.Success(c, "Success", response)
}

// CheckHashes 检查哈希
func (h *Handler) CheckHashes(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 1. 解析请求体
	var req dto.CheckHashesRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresponse.Error(c, "Invalid request body")
		return
	}

	// 2. 验证哈希列表
	if len(req.Hashes) == 0 {
		apiresponse.Error(c, "Hashes list cannot be empty")
		return
	}

	// 3. 调用Service层
	result, err := h.mediaService.CheckHashes(c.Request.Context(), userID, req.Hashes)
	if err != nil {
		h.log.Error("failed to check hashes",
			logger.Error(err),
			logger.Uint("user_id", userID),
			logger.Int("hash_count", len(req.Hashes)),
		)
		apiresponse.Error(c, "Failed to check hashes")
		return
	}

	// 4. 转换为响应格式
	response := &dto.CheckHashesResponse{
		ExistingHashes: result.ExistingHashes,
		MissingHashes:  result.MissingHashes,
	}

	apiresponse.Success(c, "Success", response)
}

// GetChanges 获取媒体变更
func (h *Handler) GetChanges(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 1. 解析请求参数
	var req dto.GetChangesRequest
	if err := c.ShouldBindQuery(&req); err != nil {
		apiresponse.Error(c, "Invalid request parameters")
		return
	}

	// 2. 解析since参数（可选）
	var since *time.Time
	if req.Since != "" {
		parsed, err := time.Parse(time.RFC3339, req.Since)
		if err != nil {
			apiresponse.Error(c, "Invalid 'since' format. Must be RFC3339 format")
			return
		}
		since = &parsed
	}

	// 3. 调用Service层
	changes, err := h.mediaService.GetChanges(c.Request.Context(), &mediaservice.GetChangesRequest{
		UserID: userID,
		Since:  since,
	})
	if err != nil {
		h.log.Error("failed to get changes",
			logger.Error(err),
			logger.Uint("user_id", userID),
		)
		apiresponse.Error(c, "Failed to get changes")
		return
	}

	// 4. 转换为响应格式
	changeList := make([]*dto.MediaChange, 0, len(changes))
	for _, change := range changes {
		changeList = append(changeList, &dto.MediaChange{
			UUID:      change.UUID,
			Hash:      change.Hash,
			ItemType:  change.ItemType,
			Action:    change.Action,
			UpdatedAt: change.UpdatedAt.Format(time.RFC3339),
		})
	}

	response := &dto.GetChangesResponse{
		Changes: changeList,
		Since:   req.Since,
	}

	apiresponse.Success(c, "Success", response)
}

// GetMediaDetail 获取媒体详情
func (h *Handler) GetMediaDetail(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		apiresponse.Error(c, "Media UUID is required")
		return
	}

	// 1. 获取授权的媒体（检查所有权）
	userIDPtr := &userID
	media, err := h.mediaService.GetAuthorizedMedia(c.Request.Context(), mediaUUID, userIDPtr)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			apiresponse.Error(c, "Media not found or permission denied")
		} else {
			h.log.Error("failed to get media detail",
				logger.Error(err),
				logger.String("uuid", mediaUUID),
				logger.Uint("user_id", userID),
			)
			apiresponse.Error(c, "Failed to get media detail")
		}
		return
	}

	// 2. 转换为响应格式
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

	apiresponse.Success(c, "Success", response)
}

// Delete 删除媒体（软删除，移到回收站）
func (h *Handler) Delete(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		apiresponse.Error(c, "Media UUID is required")
		return
	}

	// 调用Service层删除媒体
	err := h.mediaService.DeleteMedia(c.Request.Context(), userID, mediaUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) || strings.Contains(err.Error(), "not found") {
			apiresponse.Error(c, "Media not found or permission denied")
		} else {
			h.log.Error("failed to delete media",
				logger.Error(err),
				logger.String("uuid", mediaUUID),
				logger.Uint("user_id", userID),
			)
			apiresponse.Error(c, "Database error")
		}
		return
	}

	apiresponse.Success(c, "Media moved to bin", nil)
}

// Restore 恢复媒体（从回收站恢复）
func (h *Handler) Restore(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		apiresponse.Error(c, "Media UUID is required")
		return
	}

	// 调用Service层恢复媒体
	err := h.mediaService.RestoreMedia(c.Request.Context(), userID, mediaUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) || strings.Contains(err.Error(), "not found") {
			apiresponse.Error(c, "Media not found in bin or permission denied")
		} else {
			h.log.Error("failed to restore media",
				logger.Error(err),
				logger.String("uuid", mediaUUID),
				logger.Uint("user_id", userID),
			)
			apiresponse.Error(c, "Database error")
		}
		return
	}

	apiresponse.Success(c, "Media restored successfully", nil)
}

// Purge 永久删除媒体（硬删除，删除数据库记录和存储文件）
func (h *Handler) Purge(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		apiresponse.Error(c, "Media UUID is required")
		return
	}

	// 调用Service层永久删除媒体
	err := h.mediaService.PurgeMedia(c.Request.Context(), userID, mediaUUID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) || strings.Contains(err.Error(), "not found") {
			apiresponse.Error(c, "Media not found in bin or permission denied")
		} else {
			h.log.Error("failed to purge media",
				logger.Error(err),
				logger.String("uuid", mediaUUID),
				logger.Uint("user_id", userID),
			)
			apiresponse.Error(c, "Failed to purge media due to a database transaction error")
		}
		return
	}

	apiresponse.Success(c, "Media permanently deleted", nil)
}

// DownloadOriginal 下载原始文件
func (h *Handler) DownloadOriginal(c *gin.Context) {
	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		apiresponse.Error(c, "Media UUID is required")
		return
	}

	// 获取userID（可能为nil，表示通过签名URL访问）
	var userID *uint
	if userIDValue, exists := c.Get("userID"); exists {
		if id, ok := userIDValue.(uint); ok {
			userID = &id
		}
	}

	// 1. 统一授权检查
	media, err := h.mediaService.GetAuthorizedMedia(c.Request.Context(), mediaUUID, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			apiresponse.Error(c, "Media not found or permission denied")
		} else {
			h.log.Error("failed to get authorized media",
				logger.Error(err),
				logger.String("uuid", mediaUUID),
			)
			apiresponse.Error(c, "Could not verify media permissions")
		}
		return
	}

	// 2. 检查处理状态
	if media.ProcessingStatus != "COMPLETED" {
		apiresponse.Error(c, fmt.Sprintf("File is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	// 3. 获取原始文件的MIME类型
	mimeType := h.mediaService.GetOriginalMimeType(media)

	// 4. 提供文件
	h.downloadFile(c, media.LocalPath, mimeType)
}

// DownloadPreview 下载预览文件
func (h *Handler) DownloadPreview(c *gin.Context) {
	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		apiresponse.Error(c, "Media UUID is required")
		return
	}

	// 获取userID（可能为nil，表示通过签名URL访问）
	var userID *uint
	if userIDValue, exists := c.Get("userID"); exists {
		if id, ok := userIDValue.(uint); ok {
			userID = &id
		}
	}

	// 1. 统一授权检查
	media, err := h.mediaService.GetAuthorizedMedia(c.Request.Context(), mediaUUID, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			apiresponse.Error(c, "Preview not found or permission denied")
		} else {
			h.log.Error("failed to get authorized media",
				logger.Error(err),
				logger.String("uuid", mediaUUID),
			)
			apiresponse.Error(c, "Could not verify preview permissions")
		}
		return
	}

	// 2. 检查处理状态
	if media.ProcessingStatus != "COMPLETED" {
		apiresponse.Error(c, fmt.Sprintf("Preview is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	// 3. 构建预览图存储key
	storageKey, err := h.mediaService.BuildPreviewKey(media)
	if err != nil {
		h.log.Error("failed to build preview key",
			logger.Error(err),
			logger.String("uuid", mediaUUID),
		)
		apiresponse.Error(c, "Failed to build preview key")
		return
	}

	// 4. 获取预览图的MIME类型
	mimeType := h.mediaService.GetPreviewMimeType(media)

	// 5. 提供文件
	h.downloadFile(c, storageKey, mimeType)
}

// DownloadThumbnail 下载缩略图
func (h *Handler) DownloadThumbnail(c *gin.Context) {
	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		apiresponse.Error(c, "Media UUID is required")
		return
	}

	// 获取userID（可能为nil，表示通过签名URL访问）
	var userID *uint
	if userIDValue, exists := c.Get("userID"); exists {
		if id, ok := userIDValue.(uint); ok {
			userID = &id
		}
	}

	// 1. 统一授权检查
	media, err := h.mediaService.GetAuthorizedMedia(c.Request.Context(), mediaUUID, userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			apiresponse.Error(c, "Thumbnail not found or permission denied")
		} else {
			h.log.Error("failed to get authorized media",
				logger.Error(err),
				logger.String("uuid", mediaUUID),
			)
			apiresponse.Error(c, "Could not verify thumbnail permissions")
		}
		return
	}

	// 2. 检查处理状态
	if media.ProcessingStatus != "COMPLETED" {
		apiresponse.Error(c, fmt.Sprintf("Thumbnail is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	// 3. 构建缩略图存储key
	storageKey, err := h.mediaService.BuildThumbnailKey(media)
	if err != nil {
		h.log.Error("failed to build thumbnail key",
			logger.Error(err),
			logger.String("uuid", mediaUUID),
		)
		apiresponse.Error(c, "Failed to build thumbnail key")
		return
	}

	// 4. 获取缩略图的MIME类型
	mimeType := h.mediaService.GetThumbnailMimeType(media)

	// 5. 提供文件
	h.downloadFile(c, storageKey, mimeType)
}

// downloadFile 从存储提供文件下载
func (h *Handler) downloadFile(c *gin.Context, storageKey string, mimeType string) {
	// 获取文件读取器
	reader, err := h.mediaService.GetFileReader(c.Request.Context(), storageKey)
	if err != nil {
		h.log.Error("failed to get file reader",
			logger.Error(err),
			logger.String("storage_key", storageKey),
		)
		apiresponse.Error(c, "File not available on server")
		return
	}
	defer reader.Close()

	// 使用传入的MimeType，如果为空则使用默认值
	contentType := mimeType
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	c.Header("Content-Type", contentType)

	// 对于图片和视频，使用inline；对于其他文件，使用attachment
	disposition := "inline"
	if !strings.HasPrefix(contentType, "image/") && !strings.HasPrefix(contentType, "video/") {
		disposition = "attachment"
	}
	c.Header("Content-Disposition", fmt.Sprintf("%s; filename=\"%s\"", disposition, getFilename(storageKey)))

	// 将文件内容写入响应
	if _, err := io.Copy(c.Writer, reader); err != nil {
		h.log.Error("failed to write file to response",
			logger.Error(err),
			logger.String("storage_key", storageKey),
		)
		// 如果响应已经开始写入，无法返回错误响应
		if !c.Writer.Written() {
			apiresponse.Error(c, "Failed to serve file")
		}
		return
	}

	c.Status(http.StatusOK)
}

// getFilename 从storageKey提取文件名
func getFilename(storageKey string) string {
	parts := strings.Split(storageKey, "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return storageKey
}
