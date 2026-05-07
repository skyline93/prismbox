package media

import (
	"context"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
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

// UploadMedia streams a media file upload.
// @Summary      Upload media
// @Description  Upload an image or video; the server computes the file hash.
// @Tags         Media
// @Accept       multipart/form-data
// @Produce      json
// @Security     BearerAuth
// @Param        file formData file true "Media file"
// @Param        item_type formData string true "Item type" Enums(image, video)
// @Param        cloud_uuid formData string true "Client-generated UUID"
// @Param        original_filename formData string false "Original filename"
// @Param        media_taken_at formData string false "Capture time (RFC3339)"
// @Success      201 {object} response.ApiResponse{data=dto.MediaResponse} "Created"
// @Failure      400 {object} response.ApiResponse "Bad request or unsupported format"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /media/upload-stream [post]
func (h *Handler) UploadMedia(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 1. 获取表单参数
	itemTypeStr := c.PostForm("item_type")
	originalFilename := c.PostForm("original_filename")
	cloudUUID := c.PostForm("cloud_uuid")
	mediaTakenAtStr := c.PostForm("media_taken_at")
	// Live Photo 关联视频 UUID（可选，仅当上传图片主资产时使用）
	livePhotoVideoUUID := c.PostForm("live_photo_video_id")
	// Live Photo 附属视频标记（可选，仅当上传视频时使用；传 "1" 或 "true" 表示该视频为 Live Photo 附属）
	isLivePhotoVideoStr := c.PostForm("is_live_photo_video")

	// 2. 校验必填参数
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

	// 4b. 解析媒体详情（可选，建议在上传主图/Live Photo 主图时携带）
	deviceMake := strings.TrimSpace(c.PostForm("device_make"))
	deviceModel := strings.TrimSpace(c.PostForm("device_model"))
	exifExposureTime := strings.TrimSpace(c.PostForm("exif_exposure_time"))
	exifFNumberStr := strings.TrimSpace(c.PostForm("exif_f_number"))
	exifIsoStr := strings.TrimSpace(c.PostForm("exif_iso"))
	exifFocalLengthStr := strings.TrimSpace(c.PostForm("exif_focal_length"))
	latitudeStr := strings.TrimSpace(c.PostForm("latitude"))
	longitudeStr := strings.TrimSpace(c.PostForm("longitude"))

	var exifFNumber *float64
	if exifFNumberStr != "" {
		if v, err := strconv.ParseFloat(exifFNumberStr, 64); err == nil && v > 0 {
			exifFNumber = &v
		}
	}
	var exifIso *int
	if exifIsoStr != "" {
		if v, err := strconv.Atoi(exifIsoStr); err == nil && v > 0 {
			exifIso = &v
		}
	}
	var exifFocalLength *float64
	if exifFocalLengthStr != "" {
		if v, err := strconv.ParseFloat(exifFocalLengthStr, 64); err == nil && v > 0 {
			exifFocalLength = &v
		}
	}
	var latitude, longitude *float64
	if latitudeStr != "" {
		if v, err := strconv.ParseFloat(latitudeStr, 64); err == nil {
			latitude = &v
		}
	}
	if longitudeStr != "" {
		if v, err := strconv.ParseFloat(longitudeStr, 64); err == nil {
			longitude = &v
		}
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

	// 3. 获取上传的文件
	file, err := c.FormFile("file")
	if err != nil {
		h.log.Error("failed to get uploaded file",
			logger.Error(err),
		)
		apiresponse.Error(c, "Missing file in request")
		return
	}

	// 4. 验证文件大小（如果配置了最大文件大小）
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

	// 5. 打开文件流（流式处理）
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

	// 6. 调用Service层上传媒体（后端会计算 hash）
	isLivePhotoVideo := isLivePhotoVideoStr == "1" || strings.EqualFold(isLivePhotoVideoStr, "true")
	req := &mediaservice.UploadMediaRequest{
		UserID:             userID,
		ItemType:           itemType,
		OriginalFilename:   originalFilename,
		CloudUUID:          cloudUUID,
		MediaTakenAt:       mediaTakenAt,
		Filename:           file.Filename,
		FileSize:           file.Size,
		Data:               src,
		LivePhotoVideoUUID: func() *string {
			if livePhotoVideoUUID == "" {
				return nil
			}
			v := livePhotoVideoUUID
			return &v
		}(),
		IsLivePhotoVideo: isLivePhotoVideo,
	}
	if deviceMake != "" {
		req.DeviceMake = &deviceMake
	}
	if deviceModel != "" {
		req.DeviceModel = &deviceModel
	}
	if exifExposureTime != "" {
		req.ExifExposureTime = &exifExposureTime
	}
	req.ExifFNumber = exifFNumber
	req.ExifIso = exifIso
	req.ExifFocalLength = exifFocalLength
	req.Latitude = latitude
	req.Longitude = longitude

	media, err := h.mediaService.UploadMedia(c.Request.Context(), req)
	if err != nil {
		h.log.Error("failed to upload media",
			logger.Error(err),
			logger.String("filename", file.Filename),
			logger.Uint("user_id", userID),
		)
		apiresponse.Error(c, fmt.Sprintf("Failed to upload media: %v", err))
		return
	}

	// 7. 转换为响应格式
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

// ValidateUploadEndpoint is a HEAD probe for the upload URL.
// @Summary      Validate upload endpoint
// @Description  Use HEAD to verify the upload endpoint is reachable (auth only)
// @Tags         Media
// @Security     BearerAuth
// @Success      200 "OK"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetMedias lists the current user's media with pagination.
// @Summary      List media
// @Description  Paginated list with optional item type filter
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        page query int false "Page number (default 1)" default(1) minimum(1)
// @Param        page_size query int false "Page size (default 20, max 100)" default(20) minimum(1) maximum(100)
// @Param        item_type query string false "Item type" Enums(image, video)
// @Success      200 {object} response.ApiResponse{data=dto.GetMediasResponse} "OK"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

		// Live Photo 关联视频 UUID
		if media.LivePhotoVideoUUID != nil && *media.LivePhotoVideoUUID != "" {
			v := *media.LivePhotoVideoUUID
			response.LivePhotoVideoID = &v
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

// CheckHashes checks which content hashes already exist (dedupe / instant upload).
// @Summary      Check content hashes
// @Description  Batch hash lookup; max 100 per request, 30s timeout
// @Tags         Media
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body dto.CheckHashesRequest true "Hash list (max 100)"
// @Success      200 {object} response.ApiResponse{data=dto.CheckHashesResponse} "OK"
// @Failure      400 {object} response.ApiResponse "Bad request (batch size or invalid hash)"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Failure      408 {object} response.ApiResponse "Request timeout"
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

// GetChanges returns media changes since a timestamp.
// @Summary      Get media changes
// @Description  Change feed after the since query parameter (created, updated, deleted)
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        since query string false "Start time (RFC3339)"
// @Success      200 {object} response.ApiResponse{data=dto.GetChangesResponse} "OK"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// GetMediaDetail returns metadata for one media item.
// @Summary      Get media detail
// @Description  Detail including download URLs when processing is complete (authentication required)
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Media UUID"
// @Success      200 {object} response.ApiResponse{data=dto.MediaResponse} "OK"
// @Failure      400 {object} response.ApiResponse "Not found or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

	// 4. Live Photo 关联视频 UUID
	if media.LivePhotoVideoUUID != nil && *media.LivePhotoVideoUUID != "" {
		v := *media.LivePhotoVideoUUID
		response.LivePhotoVideoID = &v
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

// Delete soft-deletes media (moves to bin).
// @Summary      Delete media
// @Description  Soft-delete; can be restored from bin
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Media UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Not found or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// Restore restores media from the bin.
// @Summary      Restore media
// @Description  Undoes soft-delete
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Media UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Not found or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// Purge permanently deletes media from bin and storage.
// @Summary      Purge media
// @Description  Hard delete; cannot be recovered
// @Tags         Media
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Media UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Not found or forbidden"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// DownloadOriginal streams the original file.
// @Summary      Download original file
// @Description  Original bytes; Bearer auth or signed URL
// @Tags         Media
// @Produce      application/octet-stream
// @Security     BearerAuth
// @Param        uuid path string true "Media UUID"
// @Success      200 "File bytes"
// @Failure      400 {object} response.ApiResponse "Not found, forbidden, or not ready"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

	// 4. HEAD 请求：仅检查原文件是否存在，不返回 body
	if c.Request.Method == http.MethodHead {
		reader, err := h.mediaService.GetFileReader(c.Request.Context(), media.LocalPath, media.LocalPoolUUID)
		if err != nil {
			apiresponse.Error(c, "File not found or permission denied")
			return
		}
		_ = reader.Close()
		c.Header("Content-Type", mimeType)
		c.Status(http.StatusOK)
		return
	}

	// 5. 提供文件（传入 reader、大小与文件名以支持 Range 与 Content-Length）
	reader, err := h.mediaService.GetFileReader(c.Request.Context(), media.LocalPath, media.LocalPoolUUID)
	if err != nil {
		h.log.Error("failed to get file reader for download",
			logger.Error(err),
			logger.String("storage_key", media.LocalPath),
		)
		apiresponse.Error(c, "File not available on server")
		return
	}
	h.downloadFile(c, reader, mimeType, media.FileSize, getFilename(media.LocalPath))
}

// DownloadPreview streams the preview image.
// @Summary      Download preview
// @Description  Compressed preview image; Bearer auth or signed URL
// @Tags         Media
// @Produce      image/jpeg
// @Security     BearerAuth
// @Param        uuid path string true "Media UUID"
// @Success      200 "Preview bytes"
// @Failure      400 {object} response.ApiResponse "Not found, forbidden, or not ready"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

	// 5. HEAD 请求：仅检查预览是否存在，不返回 body
	if c.Request.Method == http.MethodHead {
		reader, err := h.mediaService.GetFileReader(c.Request.Context(), storageKey, media.LocalPoolUUID)
		if err != nil {
			apiresponse.Error(c, "Preview not found or permission denied")
			return
		}
		_ = reader.Close()
		c.Header("Content-Type", mimeType)
		c.Status(http.StatusOK)
		return
	}

	// 6. 提供文件（传入 reader、大小与文件名以支持 Content-Length）
	reader, err := h.mediaService.GetFileReader(c.Request.Context(), storageKey, media.LocalPoolUUID)
	if err != nil {
		h.log.Error("failed to get file reader for preview download",
			logger.Error(err),
			logger.String("storage_key", storageKey),
		)
		apiresponse.Error(c, "Preview not available on server")
		return
	}
	size, err := h.mediaService.GetFileSize(c.Request.Context(), storageKey)
	if err != nil {
		_ = reader.Close()
		h.log.Error("failed to get file size for preview",
			logger.Error(err),
			logger.String("storage_key", storageKey),
		)
		apiresponse.Error(c, "Preview not available on server")
		return
	}
	h.downloadFile(c, reader, mimeType, size, getFilename(storageKey))
}

// DownloadThumbnail streams a thumbnail for an asset.
// @Summary      Download thumbnail
// @Description  Small preview; dynamic size; Bearer auth or signed URL
// @Tags         Assets
// @Produce      image/jpeg
// @Security     BearerAuth
// @Param        uuid path string true "Asset UUID"
// @Param        size query string false "Size: 200x200, thumbnail, preview, or single edge e.g. 200 (default thumbnail)"
// @Success      200 "Thumbnail bytes"
// @Failure      400 {object} response.ApiResponse "Not found, forbidden, or not ready"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
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

// downloadFile 从已打开的 reader 提供文件下载，支持 Range 请求与 Content-Length
func (h *Handler) downloadFile(c *gin.Context, reader io.ReadCloser, mimeType string, totalSize int64, filename string) {
	defer reader.Close()

	contentType := mimeType
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	c.Header("Content-Type", contentType)

	disposition := "inline"
	if !strings.HasPrefix(contentType, "image/") && !strings.HasPrefix(contentType, "video/") {
		disposition = "attachment"
	}
	c.Header("Content-Disposition", fmt.Sprintf("%s; filename=\"%s\"", disposition, filename))

	// 解析 Range（仅支持单段 bytes=start-end）
	rangeHeader := c.GetHeader("Range")
	start, end, ok := parseRange(rangeHeader, totalSize)
	if ok {
		seeker, canSeek := reader.(io.Seeker)
		if canSeek {
			if _, err := seeker.Seek(start, io.SeekStart); err != nil {
				h.log.Warn("range seek failed, falling back to full response", logger.Error(err))
			} else {
				partLen := end - start + 1
				c.Header("Content-Range", fmt.Sprintf("bytes %d-%d/%d", start, end, totalSize))
				c.Header("Content-Length", strconv.FormatInt(partLen, 10))
				c.Status(http.StatusPartialContent)
				if _, err := io.CopyN(c.Writer, reader, partLen); err != nil {
					if !c.Writer.Written() {
						apiresponse.Error(c, "Failed to serve file")
					}
					return
				}
				return
			}
		}
	}

	// 无 Range 或无法 Seek：整文件，必须设置 Content-Length 以满足 iOS 等客户端
	c.Header("Content-Length", strconv.FormatInt(totalSize, 10))
	c.Status(http.StatusOK)
	if _, err := io.Copy(c.Writer, reader); err != nil {
		h.log.Error("failed to write file to response", logger.Error(err))
		if !c.Writer.Written() {
			apiresponse.Error(c, "Failed to serve file")
		}
	}
}

// parseRange 解析 "Range: bytes=start-end"，返回 [start,end] 闭区间；不支持多段。
// 支持格式：bytes=0-499、bytes=500-、bytes=-500。totalSize<=0 时返回 false。
func parseRange(s string, totalSize int64) (start, end int64, ok bool) {
	if totalSize <= 0 {
		return 0, 0, false
	}
	s = strings.TrimSpace(s)
	if !strings.HasPrefix(strings.ToLower(s), "bytes=") {
		return 0, 0, false
	}
	s = s[6:]
	parts := strings.SplitN(s, "-", 2)
	if len(parts) != 2 {
		return 0, 0, false
	}
	var startVal, endVal int64
	if parts[0] == "" {
		// bytes=-suffix → 最后 suffix 字节
		endVal = totalSize - 1
		if endVal < 0 {
			endVal = 0
		}
		if parts[1] == "" {
			return 0, 0, false
		}
		suffix, err := strconv.ParseInt(strings.TrimSpace(parts[1]), 10, 64)
		if err != nil || suffix <= 0 {
			return 0, 0, false
		}
		startVal = endVal - suffix + 1
		if startVal < 0 {
			startVal = 0
		}
		return startVal, endVal, true
	}
	startVal, err := strconv.ParseInt(strings.TrimSpace(parts[0]), 10, 64)
	if err != nil || startVal < 0 || startVal >= totalSize {
		return 0, 0, false
	}
	if parts[1] == "" {
		// bytes=start-
		endVal = totalSize - 1
		return startVal, endVal, true
	}
	endVal, err = strconv.ParseInt(strings.TrimSpace(parts[1]), 10, 64)
	if err != nil || endVal < startVal {
		return 0, 0, false
	}
	if endVal >= totalSize {
		endVal = totalSize - 1
	}
	return startVal, endVal, true
}

// getFilename 从storageKey提取文件名
func getFilename(storageKey string) string {
	parts := strings.Split(storageKey, "/")
	if len(parts) > 0 {
		return parts[len(parts)-1]
	}
	return storageKey
}
