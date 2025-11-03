package handlers

import (
	"context"
	"errors"
	"io"
	"log"
	"os"
	"path/filepath"
	"server/constant"
	"server/core"
	"server/models"
	"server/processing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

// MediaRepositoryInterface 定义了 MediaHandler 所需的所有数据操作方法。
// 这种接口驱动的设计使得 Handler 与具体的数据库实现解耦，更易于测试和维护。
// 它同时兼容 replicator.WritableRepository 接口。
type MediaRepositoryInterface interface {
	// Create 方法用于在数据库中创建一条新的媒体记录。
	// 这是 replicator.WritableRepository[*models.Media] 接口的一部分。
	Create(ctx context.Context, media *models.Media) (*models.Media, error)

	// Update 方法用于更新数据库中已有的媒体记录。
	// 业务逻辑中的软删除和恢复操作都通过此方法实现，以便 replicator 能捕获到 UPDATED 变更。
	// 这是 replicator.WritableRepository[*models.Media] 接口的一部分。
	Update(ctx context.Context, media *models.Media) (*models.Media, error)

	// Delete 方法用于从数据库中永久删除一条媒体记录及其所有关联数据。
	// 业务逻辑中的 Purge (清空) 操作会调用此方法，replicator 将记录一个 DELETED 变更。
	// 这是 replicator.WritableRepository[*models.Media] 接口的一部分。
	Delete(ctx context.Context, media *models.Media) error

	// FindByUserAndHash 是一个特定于业务的查询，用于秒传检查。
	FindByUserAndHash(ctx context.Context, userID uint, hash string) (*models.Media, error)

	// FindActiveByUUIDAndUser 查找一个未被软删除的媒体记录。
	FindActiveByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error)

	// FindInBinByUUIDAndUser 查找一个在回收站中（已被软删除）的媒体记录。
	FindInBinByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error)
}

// Upload godoc
// @Summary      上传单个媒体文件
// @Description  通过 multipart/form-data 上传照片或视频。服务器会先进行秒传检查。
// @Tags         Media
// @Accept       multipart/form-data
// @Produce      json
// @Param        file formData file true "媒体文件本身"
// @Param        hash formData string true "文件的SHA256哈希值"
// @Param        item_type formData string true "媒体类型 (IMAGE 或 VIDEO)" Enums(IMAGE, VIDEO)
// @Param        original_filename formData string false "文件的原始名称"
// @Success      201  {object}  core.ApiResponse{data=MediaResponse} "上传成功，后台处理开始"
// @Success      200  {object}  core.ApiResponse{data=MediaResponse} "文件已存在（秒传成功）"
// @Failure      400  {object}  core.ApiResponse "请求参数错误、文件上传失败或服务器内部错误"
// @Security     BearerAuth
// @Router       /media/upload [post]
func (h *MediaHandler) Upload(c *gin.Context) {
	// 从认证中间件获取用户ID
	userID := c.MustGet("userID").(uint)

	// 从表单获取元数据
	hash := c.PostForm("hash")
	itemTypeStr := c.PostForm("item_type")
	originalFilename := c.PostForm("original_filename")

	// 校验必要参数
	if hash == "" {
		core.Error(c, "Form field 'hash' is required")
		return
	}
	if itemTypeStr == "" {
		core.Error(c, "Form field 'item_type' is required")
		return
	}
	itemType := constant.MediaType(itemTypeStr)
	if itemType != constant.TypeImage && itemType != constant.TypeVideo {
		core.Error(c, "Invalid 'item_type'. Must be 'IMAGE' or 'VIDEO'")
		return
	}

	// 秒传检查：检查当前用户是否已上传过此文件
	var existingMedia models.Media
	if err := h.DB.First(&existingMedia, "hash = ? AND user_id = ?", hash, userID).Error; err == nil {
		core.Success(c, "File already exists for this user", h.buildMediaResponse(userID, existingMedia))
		return
	}

	// 获取上传的文件
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		core.Error(c, "File upload failed: "+err.Error())
		return
	}
	defer file.Close()

	// 读取文件内容
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		core.Error(c, "Failed to read file")
		return
	}

	// 生成新文件名并保存文件
	newUUID := uuid.New().String()
	newFilename := newUUID + filepath.Ext(header.Filename)
	filePath := filepath.Join(h.UploadDir, newFilename)
	if err := os.WriteFile(filePath, fileBytes, 0644); err != nil {
		core.Error(c, "Failed to save file")
		return
	}

	// 创建初始数据库记录
	media := models.Media{
		UUID:             newUUID,
		UserID:           userID,
		Hash:             hash,
		ItemType:         itemType,
		OriginalFilename: originalFilename,
		Filename:         newFilename,
		ProcessingStatus: constant.StatusPending,
	}

	if _, err := h.MediaRepo.Create(c.Request.Context(), &media); err != nil {
		os.Remove(filePath)
		core.Error(c, "Failed to save metadata to database")
		return
	}

	// 根据文件类型，异步调用后台处理任务
	if itemType == constant.TypeVideo {
		go processing.ProcessVideo(h.DB, filePath, newUUID)
	} else {
		go processing.ProcessImage(h.DB, filePath, newUUID)
	}

	mediaResponse := h.buildMediaResponse(userID, media)

	// 返回成功响应
	core.Success(c, "Upload successful, processing started", mediaResponse)
}

// UploadStream godoc
// @Summary      流式上传单个媒体文件 (推荐)
// @Description  通过 multipart/form-data 流式上传文件，避免大文件消耗内存。服务器会先进行秒传检查。
// @Tags         Media
// @Accept       multipart/form-data
// @Produce      json
// @Param        file formData file true "媒体文件本身"
// @Param        hash formData string true "文件的SHA256哈希值"
// @Param        item_type formData string true "媒体类型 (IMAGE 或 VIDEO)" Enums(IMAGE, VIDEO)
// @Param        original_filename formData string false "文件的原始名称"
// @Param        cloud_uuid formData string false "客户端预生成的UUID (可选)"
// @Param        media_taken_at formData string false "媒体拍摄时间 (ISO 8601格式，可选)"
// @Success      201  {object}  core.ApiResponse{data=MediaResponse} "上传成功，后台处理开始"
// @Success      200  {object}  core.ApiResponse{data=MediaResponse} "文件已存在（秒传成功）"
// @Failure      400  {object}  core.ApiResponse "请求参数错误或服务器内部错误"
// @Failure      500  {object}  core.ApiResponse "服务器文件处理错误"
// @Security     BearerAuth
// @Router       /media/upload-stream [post]
func (h *MediaHandler) UploadStream(c *gin.Context) {
	// 1. 获取元数据和用户ID
	userID := c.MustGet("userID").(uint)
	hash := c.PostForm("hash")
	itemTypeStr := c.PostForm("item_type")
	originalFilename := c.PostForm("original_filename")
	cloudUuid := c.PostForm("cloud_uuid")
	mediaTakenAtStr := c.PostForm("media_taken_at")

	// 2. 校验元数据
	if hash == "" {
		core.Error(c, "Form field 'hash' is required")
		return
	}
	itemType := constant.MediaType(itemTypeStr)
	if itemType != constant.TypeImage && itemType != constant.TypeVideo {
		core.Error(c, "Invalid 'item_type'. Must be 'image' or 'video'")
		return
	}
	if cloudUuid == "" {
		cloudUuid = uuid.New().String()
	}

	// 2.1. 解析媒体拍摄时间（可选）
	var mediaTakenAt *time.Time
	if mediaTakenAtStr != "" {
		parsed, err := time.Parse(time.RFC3339, mediaTakenAtStr)
		if err == nil {
			mediaTakenAt = &parsed
		} else {
			log.Printf("Warning: Failed to parse media_taken_at '%s': %v", mediaTakenAtStr, err)
		}
	}

	// 3. 秒传检查 (使用仓储方法)
	if existingMedia, err := h.MediaRepo.FindByUserAndHash(c.Request.Context(), userID, hash); err == nil {
		core.Success(c, "File already exists for this user", h.buildMediaResponse(userID, *existingMedia))
		return
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		log.Printf("Error during hash check for user %d: %v", userID, err)
		core.Error(c, "Database error during hash check")
		return
	}

	// 4. 以流式方式处理文件
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		core.Error(c, "File retrieval failed: "+err.Error())
		return
	}
	defer file.Close()

	// 5. 创建目标文件并准备写入
	newFilename := cloudUuid + filepath.Ext(header.Filename)
	filePath := filepath.Join(h.UploadDir, newFilename)
	dst, err := os.Create(filePath)
	if err != nil {
		core.Error(c, "Failed to create destination file on server")
		return
	}
	defer dst.Close()

	// 6. 将上传流直接复制到文件中
	if _, err := io.Copy(dst, file); err != nil {
		os.Remove(filePath)
		core.Error(c, "Failed to save file stream to disk")
		return
	}

	// 7. 文件成功保存后，通过仓储创建数据库记录
	media := models.Media{
		UUID:             cloudUuid,
		UserID:           userID,
		Hash:             hash,
		ItemType:         itemType,
		OriginalFilename: originalFilename,
		Filename:         newFilename,
		ProcessingStatus: constant.StatusPending,
		MediaTakenAt:     mediaTakenAt, // 保存客户端传递的拍摄时间
	}
	if _, err := h.MediaRepo.Create(c.Request.Context(), &media); err != nil {
		os.Remove(filePath)
		core.Error(c, "Failed to save metadata to database")
		return
	}

	// 8. 触发异步处理并返回成功响应
	if itemType == constant.TypeVideo {
		go processing.ProcessVideo(h.DB, filePath, cloudUuid)
	} else {
		go processing.ProcessImage(h.DB, filePath, cloudUuid)
	}

	core.Created(c, "Upload successful, processing started", h.buildMediaResponse(userID, media))
}

// Delete godoc
// @Summary      删除指定的媒体文件 (软删除)
// @Description  将指定的媒体文件移入回收站。此操作会被 replicator 捕获为一次 UPDATE。
// @Tags         Media
// @Produce      json
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse "成功移入回收站"
// @Failure      404  {object}  core.ApiResponse "错误信息：'Media not found or permission denied'"
// @Failure      500  {object}  core.ApiResponse "数据库错误"
// @Security     BearerAuth
// @Router       /media/{uuid} [delete]
func (h *MediaHandler) Delete(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	mediaUUID := c.Param("uuid")

	// 1. 查找实体以确认存在和所有权
	media, err := h.MediaRepo.FindActiveByUUIDAndUser(c.Request.Context(), mediaUUID, userID)
	if err != nil {
		core.Error(c, "Media not found or permission denied")
		return
	}

	// 2. 修改实体状态以表示软删除
	media.Deleted = true

	// 3. 调用 Update 方法。replicator 的包装器将自动记录一条 UPDATED 变更日志。
	if _, err := h.MediaRepo.Update(c.Request.Context(), media); err != nil {
		core.Error(c, "Database error")
		return
	}

	core.Success(c, "Media moved to bin", nil)
}

// Restore godoc
// @Summary      恢复指定的媒体文件
// @Description  将指定媒体文件从回收站中恢复。此操作会被 replicator 捕获为一次 UPDATE。
// @Tags         Media
// @Produce      json
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse "成功恢复"
// @Failure      404  {object}  core.ApiResponse "在回收站中未找到媒体或权限不足"
// @Failure      500  {object}  core.ApiResponse "数据库错误"
// @Security     BearerAuth
// @Router       /media/{uuid}/restore [post]
func (h *MediaHandler) Restore(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	mediaUUID := c.Param("uuid")

	// 1. 从回收站查找实体
	media, err := h.MediaRepo.FindInBinByUUIDAndUser(c.Request.Context(), mediaUUID, userID)
	if err != nil {
		core.Error(c, "Media not found in bin or permission denied")
		return
	}

	// 2. 修改实体状态以表示恢复
	media.Deleted = false

	// 3. 调用 Update 方法。replicator 的包装器将自动记录一条 UPDATED 变更日志。
	if _, err := h.MediaRepo.Update(c.Request.Context(), media); err != nil {
		core.Error(c, "Database error")
		return
	}

	core.Success(c, "Media restored successfully", nil)
}

// Purge godoc
// @Summary      永久删除媒体资源
// @Description  从数据库和文件系统中彻底删除一个媒体资源及其所有关联数据。此操作不可逆，并会被 replicator 捕获为一次 DELETE。
// @Tags         Media
// @Produce      json
// @Param        uuid path string true "要永久删除的媒体文件的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse "成功永久删除"
// @Failure      404  {object}  core.ApiResponse "媒体资源未找到或权限不足"
// @Failure      500  {object}  core.ApiResponse "数据库或文件系统操作失败"
// @Security     BearerAuth
// @Router       /media/{uuid}/purge [delete]
func (h *MediaHandler) Purge(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	mediaUUID := c.Param("uuid")

	// 1. 查找待删除的实体，确保它在回收站中且属于当前用户
	media, err := h.MediaRepo.FindInBinByUUIDAndUser(c.Request.Context(), mediaUUID, userID)
	if err != nil {
		core.Error(c, "Media not found in bin or permission denied")
		return
	}

	// 2. 调用仓储的 Delete 方法。该方法是事务性的。
	// replicator 的包装器将自动记录一条 DELETED 变更日志。
	if err := h.MediaRepo.Delete(c.Request.Context(), media); err != nil {
		log.Printf("Failed to purge media %s: %v", mediaUUID, err)
		core.Error(c, "Failed to purge media due to a database transaction error")
		return
	}

	// 3. 在数据库事务成功后，从文件系统删除物理文件
	h.cleanupMediaFiles(media)

	core.Success(c, "Media permanently deleted", nil)
}

// cleanupMediaFiles 封装了从文件系统删除媒体相关文件的逻辑。
func (h *MediaHandler) cleanupMediaFiles(media *models.Media) {
	// 删除原始文件
	originalPath := filepath.Join(h.UploadDir, media.Filename)
	if err := os.Remove(originalPath); err != nil && !os.IsNotExist(err) {
		log.Printf("Warning: failed to delete original file %s: %v", originalPath, err)
	}

	// 删除缩略图
	thumbPath := filepath.Join(h.UploadDir, media.UUID+constant.ThumbSuffix)
	if err := os.Remove(thumbPath); err != nil && !os.IsNotExist(err) {
		log.Printf("Warning: failed to delete thumbnail file %s: %v", thumbPath, err)
	}

	// 删除预览图/视频
	previewSuffix := constant.PreviewImageSuffix
	if media.ItemType == constant.TypeVideo {
		previewSuffix = constant.PreviewVideoSuffix
	}
	previewPath := filepath.Join(h.UploadDir, media.UUID+previewSuffix)
	if err := os.Remove(previewPath); err != nil && !os.IsNotExist(err) {
		log.Printf("Warning: failed to delete preview file %s: %v", previewPath, err)
	}
}
