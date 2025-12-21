package media

import (
	"context"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/album/backend/internal/api/dto"
	"github.com/album/backend/internal/api/middleware"
	apiresponse "github.com/album/backend/internal/api/response"
	appctx "github.com/album/backend/internal/app"
	mediaservice "github.com/album/backend/internal/service/media"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Handler 媒体处理器
type Handler struct {
	mediaService mediaservice.Service
	app          *appctx.App
	log          logger.Logger
}

// NewHandler 创建媒体处理器
func NewHandler(mediaService mediaservice.Service, app *appctx.App) *Handler {
	return &Handler{
		mediaService: mediaService,
		app:          app,
		log:          logger.New("api.v1.media"),
	}
}

// UploadMedia 上传媒体文件
// @Summary      上传媒体文件
// @Description  上传图片或视频文件，支持秒传（通过 hash 检查）。如果文件已存在，直接返回已存在的媒体信息
// @Tags         Media
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        file formData file true "媒体文件"
// @Param        hash formData string true "文件 MD5 哈希值（32位十六进制字符串）"
// @Param        item_type formData string true "媒体类型" Enums(image, video)
// @Param        cloud_uuid formData string true "客户端生成的 UUID"
// @Param        original_filename formData string false "原始文件名"
// @Param        media_taken_at formData string false "媒体拍摄时间（RFC3339 格式）"
// @Success      200 {object} response.ApiResponse{data=dto.MediaResponse} "文件已存在（秒传）"
// @Success      201 {object} response.ApiResponse{data=dto.MediaResponse} "上传成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误或文件格式不支持"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/upload-stream [post]
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
	// 验证Hash格式（MD5应该是32个字符的十六进制字符串）
	if len(hash) != 32 {
		apiresponse.Error(c, "Invalid 'hash' format. Must be a 32-character hexadecimal string (MD5)")
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

	// 5. 获取设备信息（用于统计上传来源设备）
	deviceID := middleware.MustGetDeviceID(c)
	deviceType := middleware.MustGetDeviceType(c)

	h.log.Info("Starting media upload",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.String("device_type", deviceType),
		logger.String("item_type", itemType),
		logger.String("cloud_uuid", cloudUUID),
		logger.String("filename", originalFilename),
	)

	// 6. 秒传检查（在打开文件流之前，优化性能）
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
			ThumbHash:        existingMedia.ThumbHash,
		}
		h.log.Info("media instant upload (file already exists)",
			logger.String("uuid", existingMedia.UUID),
			logger.String("requested_uuid", cloudUUID),
			logger.String("hash", hash),
			logger.Uint("user_id", userID),
			logger.String("device_id", deviceID),
			logger.String("device_type", deviceType),
		)
		apiresponse.Success(c, "File already exists for this user", response)
		return
	}

	// 7. 获取上传的文件（只有在不是秒传时才需要）
	file, err := c.FormFile("file")
	if err != nil {
		h.log.Error("failed to get uploaded file",
			logger.Error(err),
		)
		apiresponse.Error(c, "Missing file in request")
		return
	}

	// 8. 验证文件大小（如果配置了最大文件大小）
	if h.app != nil && h.app.Config != nil && h.app.Config.API != nil && h.app.Config.API.MaxFileSize > 0 {
		maxSize := int64(h.app.Config.API.MaxFileSize)
		if file.Size > maxSize {
			h.log.Warn("file size exceeds maximum allowed size",
				logger.Int64("file_size", file.Size),
				logger.Int64("max_size", maxSize),
				logger.String("filename", file.Filename),
			)
			apiresponse.Error(c, fmt.Sprintf("File size (%d bytes) exceeds maximum allowed size (%d bytes)", file.Size, maxSize))
			return
		}
	}

	// 9. 打开文件流（流式处理）
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

	// 10. 调用Service层上传媒体（传入所有参数）
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

	// 11. 转换为响应格式
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
		ThumbHash:        media.ThumbHash,
	}

	// 12. 新上传成功，返回201
	h.log.Info("media uploaded successfully",
		logger.String("uuid", media.UUID),
		logger.String("filename", file.Filename),
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.String("device_type", deviceType),
		logger.Int64("file_size", file.Size),
	)
	apiresponse.Created(c, "Media uploaded successfully", response)
}

// ValidateUploadEndpoint 验证上传端点（HEAD 方法）
// 用于端点健康检查和可用性验证
// @Summary      验证上传端点
// @Description  用于客户端验证上传端点是否可用（HEAD 请求）
// @Tags         Media
// @Security     BearerAuth
// @Success      200 "端点可用"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/upload-stream [head]
func (h *Handler) ValidateUploadEndpoint(c *gin.Context) {
	// 只需要验证认证，不需要实际处理文件上传
	// 认证通过后返回 200 状态码表示端点可用
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 端点可用，返回 200
	c.Status(http.StatusOK)
	h.log.Info("upload endpoint validated",
		logger.Uint("user_id", userID),
	)
}

// GetMedias 获取媒体列表
// @Summary      获取媒体列表
// @Description  分页获取当前用户的媒体列表，支持按类型筛选
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        page query int false "页码（默认1）" default(1) minimum(1)
// @Param        page_size query int false "每页数量（默认20，最大100）" default(20) minimum(1) maximum(100)
// @Param        item_type query string false "媒体类型" Enums(image, video)
// @Success      200 {object} response.ApiResponse{data=dto.GetMediasResponse} "获取成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media [get]
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
	publicBaseURL := ""
	if h.app != nil && h.app.Config != nil && h.app.Config.Server != nil {
		publicBaseURL = h.app.Config.Server.PublicBaseURL
	}

	for _, media := range result.Medias {
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
			UpdatedAt:        media.UpdatedAt.Format(time.RFC3339),
			Width:            media.Width,
			Height:           media.Height,
			ThumbHash:        media.ThumbHash,
		}

		// 处理可选的 MediaTakenAt 字段
		if media.MediaTakenAt != nil {
			takenAt := media.MediaTakenAt.Format(time.RFC3339)
			response.MediaTakenAt = &takenAt
		}

		// 构建URL（仅在处理完成时提供）
		if media.ProcessingStatus == "COMPLETED" && publicBaseURL != "" {
			response.ThumbnailURL = fmt.Sprintf("%s/api/v1/media/%s/download/thumbnail", publicBaseURL, media.UUID)
			response.PreviewURL = fmt.Sprintf("%s/api/v1/media/%s/download/preview", publicBaseURL, media.UUID)
			response.DownloadURL = fmt.Sprintf("%s/api/v1/media/%s/download/original", publicBaseURL, media.UUID)
		}

		medias = append(medias, response)
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
// @Summary      检查文件哈希
// @Description  批量检查文件哈希值，返回已存在和缺失的哈希列表（用于秒传检查）。每批最多 100 个哈希，超时时间 30 秒。
// @Tags         Media
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body dto.CheckHashesRequest true "哈希列表（最多 100 个）"
// @Success      200 {object} response.ApiResponse{data=dto.CheckHashesResponse} "检查成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误（批量大小超限、哈希格式无效）"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Failure      408 {object} response.ApiResponse "请求超时"
// @Router       /media/check_hashes [post]
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

	// 3. 批量大小限制：最多 100 个
	const maxBatchSize = 100
	if len(req.Hashes) > maxBatchSize {
		h.log.Warn("hash batch size exceeds limit",
			logger.Uint("user_id", userID),
			logger.Int("requested_count", len(req.Hashes)),
			logger.Int("max_allowed", maxBatchSize),
		)
		apiresponse.Error(c, fmt.Sprintf("Hashes list cannot exceed %d items. Got %d items", maxBatchSize, len(req.Hashes)))
		return
	}

	// 4. 哈希格式验证：MD5 应该是 32 位十六进制字符串
	for i, hash := range req.Hashes {
		if len(hash) != 32 {
			h.log.Warn("invalid hash format",
				logger.Uint("user_id", userID),
				logger.Int("index", i),
				logger.Int("hash_length", len(hash)),
			)
			apiresponse.Error(c, fmt.Sprintf("Invalid hash format at index %d. Hash must be a 32-character hexadecimal string (MD5)", i))
			return
		}
		// 验证是否为有效的十六进制字符串
		if _, err := hex.DecodeString(hash); err != nil {
			h.log.Warn("invalid hash format (not hexadecimal)",
				logger.Uint("user_id", userID),
				logger.Int("index", i),
				logger.Error(err),
			)
			apiresponse.Error(c, fmt.Sprintf("Invalid hash format at index %d. Hash must be a valid hexadecimal string", i))
			return
		}
	}

	// 5. 调用Service层（带超时控制：30 秒）
	ctx, cancel := context.WithTimeout(c.Request.Context(), 30*time.Second)
	defer cancel()

	result, err := h.mediaService.CheckHashes(ctx, userID, req.Hashes)
	if err != nil {
		// 区分超时错误和其他错误
		if ctx.Err() == context.DeadlineExceeded {
			h.log.Error("check hashes timeout",
				logger.Error(err),
				logger.Uint("user_id", userID),
				logger.Int("hash_count", len(req.Hashes)),
			)
			c.JSON(http.StatusRequestTimeout, apiresponse.ApiResponse{
				Code:    1,
				Message: "Request timeout. Please try again with a smaller batch size",
				Data:    nil,
			})
			return
		}
		h.log.Error("failed to check hashes",
			logger.Error(err),
			logger.Uint("user_id", userID),
			logger.Int("hash_count", len(req.Hashes)),
		)
		apiresponse.Error(c, "Failed to check hashes")
		return
	}

	// 6. 转换为响应格式
	response := &dto.CheckHashesResponse{
		ExistingHashes: result.ExistingHashes,
		MissingHashes:  result.MissingHashes,
		TotalCount:     len(req.Hashes),
		ExistingCount:  len(result.ExistingHashes),
		MissingCount:   len(result.MissingHashes),
	}

	apiresponse.Success(c, "Success", response)
}

// GetChanges 获取媒体变更
// @Summary      获取媒体变更
// @Description  获取指定时间点之后的媒体变更记录（创建、更新、删除）
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        since query string false "起始时间（RFC3339 格式）"
// @Success      200 {object} response.ApiResponse{data=dto.GetChangesResponse} "获取成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/changes [get]
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
// @Summary      获取媒体详情
// @Description  获取指定媒体的详细信息，包括下载链接（需要认证）
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "媒体 UUID"
// @Success      200 {object} response.ApiResponse{data=dto.MediaResponse} "获取成功"
// @Failure      400 {object} response.ApiResponse "媒体不存在或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/{uuid} [get]
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
		UpdatedAt:        media.UpdatedAt.Format(time.RFC3339),
		Width:            media.Width,
		Height:           media.Height,
		ThumbHash:        media.ThumbHash,
	}

	// 3. 处理可选的 MediaTakenAt 字段
	if media.MediaTakenAt != nil {
		takenAt := media.MediaTakenAt.Format(time.RFC3339)
		response.MediaTakenAt = &takenAt
	}

	// 4. 构建URL（仅在处理完成时提供）
	if media.ProcessingStatus == "COMPLETED" {
		publicBaseURL := ""
		if h.app != nil && h.app.Config != nil && h.app.Config.Server != nil {
			publicBaseURL = h.app.Config.Server.PublicBaseURL
		}
		if publicBaseURL != "" {
			response.ThumbnailURL = fmt.Sprintf("%s/api/v1/media/%s/download/thumbnail", publicBaseURL, media.UUID)
			response.PreviewURL = fmt.Sprintf("%s/api/v1/media/%s/download/preview", publicBaseURL, media.UUID)
			response.DownloadURL = fmt.Sprintf("%s/api/v1/media/%s/download/original", publicBaseURL, media.UUID)
		}
	}

	apiresponse.Success(c, "Success", response)
}

// Delete 删除媒体（软删除，移到回收站）
// @Summary      删除媒体
// @Description  将媒体移到回收站（软删除），可以恢复
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "媒体 UUID"
// @Success      200 {object} response.ApiResponse "删除成功"
// @Failure      400 {object} response.ApiResponse "媒体不存在或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/{uuid} [delete]
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
// @Summary      恢复媒体
// @Description  从回收站恢复已删除的媒体
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "媒体 UUID"
// @Success      200 {object} response.ApiResponse "恢复成功"
// @Failure      400 {object} response.ApiResponse "媒体不存在或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/{uuid}/restore [post]
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
// @Summary      永久删除媒体
// @Description  永久删除媒体（硬删除），无法恢复
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "媒体 UUID"
// @Success      200 {object} response.ApiResponse "删除成功"
// @Failure      400 {object} response.ApiResponse "媒体不存在或权限不足"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/{uuid}/purge [delete]
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
// @Summary      下载原始文件
// @Description  下载媒体的原始文件，支持认证或签名 URL 访问
// @Tags         Media
// @Produce      application/octet-stream
// @Security     BearerAuth
// @Param        uuid path string true "媒体 UUID"
// @Success      200 "文件内容"
// @Failure      400 {object} response.ApiResponse "媒体不存在、权限不足或文件未处理完成"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/{uuid}/download/original [get]
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
// @Summary      下载预览文件
// @Description  下载媒体的预览图（压缩后的图片），支持认证或签名 URL 访问
// @Tags         Media
// @Produce      image/jpeg
// @Security     BearerAuth
// @Param        uuid path string true "媒体 UUID"
// @Success      200 "预览图内容"
// @Failure      400 {object} response.ApiResponse "媒体不存在、权限不足或文件未处理完成"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /media/{uuid}/download/preview [get]
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
// @Summary      下载资产缩略图
// @Description  下载资产的缩略图（小尺寸预览），支持动态尺寸和认证或签名 URL 访问
// @Tags         Assets
// @Produce      image/jpeg
// @Security     BearerAuth
// @Param        uuid path string true "资产 UUID"
// @Param        size query string false "尺寸参数：200x200, thumbnail, preview, 或单边限制如 200（默认：thumbnail）"
// @Success      200 "缩略图内容"
// @Failure      400 {object} response.ApiResponse "资产不存在、权限不足或文件未处理完成"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /assets/{uuid}/thumbnail [get]
func (h *Handler) DownloadThumbnail(c *gin.Context) {
	requestStartTime := time.Now()
	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		apiresponse.Error(c, "Media UUID is required")
		return
	}

	// 获取 size 参数（可选）
	sizeParam := c.Query("size")
	if sizeParam == "" {
		sizeParam = "thumbnail" // 默认值
	}

	h.log.Debug("thumbnail download request received",
		logger.String("media_uuid", mediaUUID),
		logger.String("size_param", sizeParam),
	)

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
			h.log.Debug("thumbnail not found or permission denied",
				logger.String("media_uuid", mediaUUID),
			)
			apiresponse.Error(c, "Thumbnail not found or permission denied")
		} else {
			h.log.Error("failed to get authorized media for thumbnail",
				logger.String("media_uuid", mediaUUID),
				logger.Error(err),
			)
			apiresponse.Error(c, "Could not verify thumbnail permissions")
		}
		return
	}

	// 2. 检查处理状态
	if media.ProcessingStatus != "COMPLETED" {
		h.log.Debug("thumbnail not ready, media still processing",
			logger.String("media_uuid", mediaUUID),
			logger.String("processing_status", media.ProcessingStatus),
		)
		apiresponse.Error(c, fmt.Sprintf("Thumbnail is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	// 3. 获取或生成缩略图（支持动态尺寸，返回详细信息）
	thumbnailResult, err := h.mediaService.GetOrGenerateThumbnailWithInfo(c.Request.Context(), media, sizeParam)
	if err != nil {
		h.log.Error("failed to get or generate thumbnail",
			logger.String("media_uuid", mediaUUID),
			logger.String("size_param", sizeParam),
			logger.String("item_type", media.ItemType),
			logger.Duration("request_latency_ms", time.Since(requestStartTime)),
			logger.Error(err),
		)
		apiresponse.Error(c, fmt.Sprintf("Failed to get thumbnail: %v", err))
		return
	}
	defer thumbnailResult.Reader.Close()

	// 4. 获取缩略图的MIME类型
	mimeType := h.mediaService.GetThumbnailMimeType(media)

	// 5. 设置响应头
	c.Header("Content-Type", mimeType)
	c.Header("ETag", fmt.Sprintf(`"%s"`, media.Hash)) // ETag 用于缓存验证

	// 根据是否为占位符设置不同的缓存策略
	if thumbnailResult.IsPlaceholder && media.ThumbHash != "" {
		// 占位符使用短缓存 + must-revalidate
		// must-revalidate: 缓存过期后必须重新验证，不能使用过期缓存
		// max-age=30: 缓存30秒，鼓励客户端定期检查实际缩略图是否已生成
		c.Header("Cache-Control", "public, max-age=30, must-revalidate")
		c.Header("X-ThumbHash", media.ThumbHash)
		c.Header("X-Is-Placeholder", "true")
		h.log.Debug("serving thumbhash placeholder",
			logger.String("media_uuid", mediaUUID),
			logger.String("size_param", sizeParam),
		)
	} else {
		// 实际缩略图使用长缓存
		c.Header("Cache-Control", "public, max-age=2592000") // 30天缓存
	}

	totalLatency := time.Since(requestStartTime)
	h.log.Info("thumbnail request completed successfully",
		logger.String("media_uuid", mediaUUID),
		logger.String("size_param", sizeParam),
		logger.Bool("is_placeholder", thumbnailResult.IsPlaceholder),
		logger.Duration("total_latency_ms", totalLatency),
	)

	// 6. 流式传输缩略图
	c.DataFromReader(200, -1, mimeType, thumbnailResult.Reader, nil)
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
