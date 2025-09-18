// handlers/media_handler.go

package handlers

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"server/constant"
	"server/core"
	"server/models"
	"server/processing"
	"server/routing"
	"server/urlsigner"
	"sort"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

const (
	defaultPageSize = 100
	iso8601Format   = time.RFC3339
	chunkSize       = 1 * 1024 * 1024 // 1 MB
	tmpUploadDir    = "tmp"           // 临时分片存储目录
)

// MediaHandler 封装了所有与照片/视频相关的HTTP处理器
type MediaHandler struct {
	DB        *gorm.DB
	UploadDir string

	URLSigner        *urlsigner.Signer
	URLBuilder       *routing.URLBuilder
	SignedURLLoadTTL time.Duration
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
	if err := h.DB.Create(&media).Error; err != nil {
		// 如果数据库创建失败，尝试删除已保存的文件以避免产生孤立文件
		os.Remove(filePath)
		core.Error(c, "Failed to save initial metadata")
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

// GetMedias godoc
// @Summary      获取媒体列表
// @Description  获取当前用户的所有媒体列表（分页）
// @Tags         Media
// @Produce      json
// @Param        page query int false "页码" default(1)
// @Param        limit query int false "每页数量" default(100)
// @Param        updated_since query string false "只返回在此时间戳 (ISO 8601) 之后更新的记录"
// @Success      200  {object}  core.ApiResponse{data=[]MediaResponse} "成功获取媒体列表"
// @Failure      400  {object}  core.ApiResponse "数据库错误"
// @Security     BearerAuth
// @Router       /media [get]
func (h *MediaHandler) GetMedias(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(defaultPageSize)))
	updatedSinceStr := c.Query("updated_since")

	if page < 1 {
		page = 1
	}
	offset := (page - 1) * limit

	var medias []models.Media
	query := h.DB.Where("user_id = ?", userID)

	// [v2.1] 应用 updated_since 过滤器
	if updatedSinceStr != "" {
		updatedSince, err := time.Parse(iso8601Format, updatedSinceStr)
		if err != nil {
			core.Error(c, "Invalid 'updated_since' timestamp format. Use ISO 8601.")
			return
		}
		query = query.Where("updated_at > ?", updatedSince)
	}

	if err := query.Order("created_at desc").Limit(limit).Offset(offset).Find(&medias).Error; err != nil {
		core.Error(c, "Database error: "+err.Error())
		return
	}

	mediaResponses := h.buildMediaResponses(userID, medias)
	core.Success(c, "Medias retrieved successfully", mediaResponses)
}

// GetMediaDetail godoc
// @Summary      获取媒体详情
// @Description  获取指定UUID的媒体详情。可以通过用户认证或有效的分享链接访问。
// @Tags         Media
// @Produce      json
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse{data=MediaResponse} "成功获取媒体详情"
// @Failure      400  {object}  core.ApiResponse "错误信息可能为 'Media not found or permission denied' 或 'Database error'"
// @Security     BearerAuth
// @Router       /media/{uuid} [get]
func (h *MediaHandler) GetMediaDetail(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	mediaUUID := c.Param("uuid")

	var media models.Media
	if err := h.DB.Where("uuid = ? AND user_id = ?", mediaUUID, userID).First(&media).Error; err != nil {
		core.Error(c, "Database error")
		return
	}

	resp := h.buildMediaResponse(userID, media)

	core.Success(c, "Media detail retrieved successfully", resp)
}

// Delete godoc
// @Summary      删除指定的媒体文件
// @Description  将指定的媒体文件移入回收站（软删除）
// @Tags         Media
// @Produce      json
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse "成功删除"
// @Failure      400  {object}  core.ApiResponse "错误信息可能为 'Media not found or permission denied' 或 'Database error'"
// @Security     BearerAuth
// @Router       /media/{uuid} [delete]
func (h *MediaHandler) Delete(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	mediaUUID := c.Param("uuid")

	// 不再使用 gorm.Delete()，而是将 deleted 字段更新为 true
	// 同时确保只操作 deleted = false 的记录
	result := h.DB.Model(&models.Media{}).
		Where("uuid = ? AND user_id = ? AND deleted = ?", mediaUUID, userID, false).
		Update("deleted", true)

	if result.Error != nil {
		core.Error(c, "Database error")
		return
	}
	if result.RowsAffected == 0 {
		core.Error(c, "Media not found or permission denied")
		return
	}

	core.Success(c, "Media moved to bin", nil)
}

// Restore godoc
// @Summary      恢复指定的媒体文件
// @Description  将指定媒体文件从回收站中恢复
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

	// 不再需要 Unscoped()，直接查询 deleted = true 的记录，并将其更新为 false
	result := h.DB.Model(&models.Media{}).
		Where("uuid = ? AND user_id = ? AND deleted = ?", mediaUUID, userID, true).
		Update("deleted", false)

	if result.Error != nil {
		core.Error(c, "Database error")
		return
	}
	if result.RowsAffected == 0 {
		core.Error(c, "Media not found in bin or permission denied")
		return
	}

	core.Success(c, "Media restored successfully", nil)
}

// Purge godoc
// @Summary      永久删除媒体资源
// @Description  从数据库和文件系统中彻底删除一个媒体资源及其所有关联数据（缩略图、预览图、分享链接、相册关联等）。此操作不可逆。通常用于清空回收站中的项目。
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

	var media models.Media
	if err := h.DB.Where("uuid = ? AND user_id = ? AND deleted = ?", mediaUUID, userID, true).First(&media).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			core.Error(c, "Media not found or permission denied")
		} else {
			core.Error(c, "Database error while finding media")
		}
		return
	}

	// 启动数据库事务，确保所有数据库操作的原子性
	err := h.DB.Transaction(func(tx *gorm.DB) error {
		// 1. 删除与相册的关联 (多对多关系)
		// 直接执行SQL从中间表删除关联关系
		if err := tx.Exec("DELETE FROM album_items WHERE media_id = ?", media.ID).Error; err != nil {
			return fmt.Errorf("failed to disassociate from albums: %w", err)
		}

		// 2. 删除相关的分享记录
		if err := tx.Unscoped().Where("media_id = ?", media.ID).Delete(&models.Share{}).Error; err != nil {
			return fmt.Errorf("failed to delete shares: %w", err)
		}

		// 3. 删除相关的圈子媒体引用 (GroupMedia)
		if err := tx.Unscoped().Where("media_uuid = ?", media.UUID).Delete(&models.GroupMedia{}).Error; err != nil {
			return fmt.Errorf("failed to delete group media references: %w", err)
		}

		// 4. 将使用此媒体作为封面的相册和圈子的封面字段置空
		if err := tx.Model(&models.Album{}).Where("cover_media_uuid = ?", media.UUID).Update("cover_media_uuid", nil).Error; err != nil {
			return fmt.Errorf("failed to nullify album covers: %w", err)
		}
		if err := tx.Model(&models.Group{}).Where("cover_media_uuid = ?", media.UUID).Update("cover_media_uuid", "").Error; err != nil {
			return fmt.Errorf("failed to clear group covers: %w", err)
		}

		// 5. 永久删除媒体记录本身
		// 使用 Unscoped() 来确保执行的是物理删除 (DELETE FROM media WHERE id = ...)，
		// 而不是GORM的软删除（即使模型没有gorm.DeletedAt，这也是最明确的写法）。
		if err := tx.Unscoped().Delete(&models.Media{}, media.ID).Error; err != nil {
			return fmt.Errorf("failed to permanently delete media record: %w", err)
		}

		// 返回 nil 以提交事务
		return nil
	})

	if err != nil {
		log.Printf("Failed to purge media %s: %v", mediaUUID, err)
		core.Error(c, "Failed to purge media due to a database transaction error")
		return
	}

	// 6. 在数据库事务成功后，从文件系统删除物理文件
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

	core.Success(c, "Media permanently deleted", nil)
}

// getAuthorizedMedia 是一个核心的私有辅助函数，用于统一处理照片的授权逻辑。
// 它能够处理两种情况：
// 1. 私有访问：通过检查 Gin 上下文中的 "userID" 来验证照片所有权。
// 2. 公开分享访问：在没有 "userID" 的情况下，通过查询 Share 表来验证是否存在有效的分享记录。
// 如果授权成功，它会返回完整的 Media 对象；否则返回错误。
func (h *MediaHandler) getAuthorizedMedia(c *gin.Context) (*models.Media, error) {
	mediaUUID := c.Param("uuid")
	if mediaUUID == "" {
		return nil, errors.New("media UUID is required")
	}

	var media models.Media
	var err error

	userIDValue, userExists := c.Get("userID")

	if userExists {
		// --- 路径 A: 私有访问 ---
		// 上下文中有 userID，说明是已登录用户通过常规方式访问。
		userID, ok := userIDValue.(uint)
		if !ok {
			// 这是一个服务器内部错误，userID的类型不应出错
			return nil, errors.New("invalid userID type in context")
		}

		// 查询照片，条件是 UUID 匹配且 user_id 匹配
		err = h.DB.Where("user_id = ? AND uuid = ?", userID, mediaUUID).First(&media).Error

	} else {
		// --- 路径 B: 公开分享链接访问 ---
		// 上下文中没有 userID，说明请求可能是通过一个公开的、不记名的签名URL发起的。
		// 我们需要检查是否存在一个有效的、未过期的分享记录指向这张照片。
		// 这需要通过 JOIN 查询 Media 和 Share 表。
		err = h.DB.Joins("JOIN shares ON shares.media_id = media.id").
			Where("media.uuid = ? AND shares.is_revoked = ? AND shares.expires_at > ?",
				mediaUUID, false, time.Now()).
			First(&media).Error
	}

	// 统一处理查询结果
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// 对于客户端来说，无论是找不到记录还是权限不足，都表现为“找不到”。
			// 这是为了防止攻击者通过错误信息探测哪些资源是存在的。
			return nil, gorm.ErrRecordNotFound
		}
		// 其他数据库错误
		log.Printf("Database error while authorizing media access for UUID %s: %v", mediaUUID, err)
		return nil, err
	}

	return &media, nil
}

// DownloadOriginal godoc
// @Summary      下载原始文件
// @Description  下载指定UUID的原始媒体文件。可以通过用户认证或有效的分享链接访问。
// @Tags         Media
// @Produce      application/octet-stream
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200 {file} file "原始文件数据"
// @Failure      403 {object} core.ApiResponse "权限不足或分享链接无效/过期"
// @Failure      404 {object} core.ApiResponse "照片未找到"
// @Failure      500 {object} core.ApiResponse "文件未就绪或服务器内部错误"
// @Security     BearerAuth
// @Security     SignedURL
// @Router       /media/{uuid}/download/original [get]
func (h *MediaHandler) DownloadOriginal(c *gin.Context) {
	// 1. 统一授权检查
	media, err := h.getAuthorizedMedia(c)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			core.Error(c, "Media not found or permission denied")
		} else {
			core.Error(c, "Could not verify media permissions")
		}
		return
	}

	// 2. 检查处理状态 (业务逻辑)
	if media.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, fmt.Sprintf("File is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	// 3. 提供文件
	h.downloadFile(c, media.Filename)
}

// DownloadPreview godoc
// @Summary      获取预览图或预览视频
// @Description  获取指定UUID的预览文件。可以通过用户认证或有效的分享链接访问。
// @Tags         Media
// @Produce      image/jpeg
// @Produce      video/mp4
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200 {file} file "预览文件数据"
// @Failure      403 {object} core.ApiResponse "权限不足或分享链接无效/过期"
// @Failure      404 {object} core.ApiResponse "照片未找到"
// @Failure      500 {object} core.ApiResponse "文件未就绪或服务器内部错误"
// @Security     BearerAuth
// @Security     SignedURL
// @Router       /media/{uuid}/download/preview [get]
func (h *MediaHandler) DownloadPreview(c *gin.Context) {
	// 1. 统一授权检查
	media, err := h.getAuthorizedMedia(c)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			core.Error(c, "Preview not found or permission denied")
		} else {
			core.Error(c, "Could not verify preview permissions")
		}
		return
	}

	// 2. 检查处理状态 (业务逻辑)
	if media.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, fmt.Sprintf("Preview is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	// 3. 确定文件名并提供文件 (业务逻辑)
	suffix := constant.PreviewImageSuffix
	if media.ItemType == constant.TypeVideo {
		suffix = constant.PreviewVideoSuffix
	}
	h.downloadFile(c, media.UUID+suffix)
}

// DownloadThumbnail godoc
// @Summary      获取缩略图
// @Description  获取指定UUID的缩略图。可以通过用户认证或有效的分享链接访问。
// @Tags         Media
// @Produce      image/jpeg
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200 {file} file "缩略图文件数据"
// @Failure      403 {object} core.ApiResponse "权限不足或分享链接无效/过期"
// @Failure      404 {object} core.ApiResponse "照片未找到"
// @Failure      500 {object} core.ApiResponse "文件未就绪或服务器内部错误"
// @Security     BearerAuth
// @Security     SignedURL
// @Router       /media/{uuid}/download/thumbnail [get]
func (h *MediaHandler) DownloadThumbnail(c *gin.Context) {
	// 1. 统一授权检查
	media, err := h.getAuthorizedMedia(c)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			core.Error(c, "Thumbnail not found or permission denied")
		} else {
			core.Error(c, "Could not verify thumbnail permissions")
		}
		return
	}

	// 2. 检查处理状态 (业务逻辑)
	if media.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, fmt.Sprintf("Thumbnail is not ready yet. Current status: %s", media.ProcessingStatus))
		return
	}

	// 3. 提供文件 (业务逻辑)
	h.downloadFile(c, media.UUID+constant.ThumbSuffix)
}

// downloadFile 是一个私有辅助函数，用于从磁盘提供文件下载
func (h *MediaHandler) downloadFile(c *gin.Context, filename string) {
	filePath := filepath.Join(h.UploadDir, filename)

	// 检查文件是否存在于磁盘上
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		log.Printf("File record exists in DB but not found on disk: %s", filePath)
		core.Error(c, "File not available on server")
		return
	}

	// 使用 http.ServeFile 替换 c.File()。
	// http.ServeFile 会自动处理 Content-Type, ETag, 和 Range 请求头，
	// 这对于断点续传至关重要。
	http.ServeFile(c.Writer, c.Request, filePath)
}

// [新增] CheckHashes godoc
// @Summary      批量预检哈希
// @Description  客户端上传文件前，先通过此接口检查哪些文件（通过哈希）已经存在于云端，避免重复上传。
// @Tags         Media
// @Accept       json
// @Produce      json
// @Param        hashes body CheckHashesRequest true "包含文件哈希值数组的JSON对象"
// @Success      200  {object}  core.ApiResponse{data=CheckHashesResponse} "查询成功"
// @Failure      400  {object}  core.ApiResponse "请求体解析错误"
// @Security     BearerAuth
// @Router       /media/check_hashes [post]
func (h *MediaHandler) CheckHashes(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var req CheckHashesRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		core.Error(c, "Invalid request body: "+err.Error())
		return
	}

	if len(req.Hashes) == 0 {
		core.Success(c, "OK", CheckHashesResponse{ExistingHashes: []string{}})
		return
	}

	var existingHashes []string
	// 在 media 表中查找当前用户已存在的哈希
	h.DB.Model(&models.Media{}).
		Where("user_id = ? AND hash IN ?", userID, req.Hashes).
		Pluck("hash", &existingHashes)

	core.Success(c, "Hashes checked", CheckHashesResponse{ExistingHashes: existingHashes})
}

// [修改] GetChanges godoc
// @Summary      获取媒体变更（增量或全量）
// @Description  根据客户端提供的 `since` 时间戳，返回此时间之后所有创建、更新和删除的媒体信息。如果 `since` 未提供，则返回所有媒体的全量数据。
// @Tags         Media
// @Produce      json
// @Param        since query string false "【可选】客户端本地记录的最新更新时间戳 (ISO 8601 格式)。如果为空，则执行全量同步。"
// @Success      200  {object}  core.ApiResponse{data=MediaChangesResponse} "成功获取变更"
// @Failure      400  {object}  core.ApiResponse "时间戳格式错误"
// @Security     BearerAuth
// @Router       /media/changes [get]
func (h *MediaHandler) GetChanges(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	sinceStr := c.Query("since")

	var response MediaChangesResponse
	var err error
	var medias []models.Media

	if sinceStr == "" {
		// 【新增逻辑】如果 since 为空，执行全量同步
		// 只查询属于该用户且未被软删除的记录
		err = h.DB.Where("user_id = ?", userID).Find(&medias).Error
		if err != nil {
			core.Error(c, "Failed to fetch all media for full sync: "+err.Error())
			return
		}
		// 全量同步时，所有记录都视为“已创建”
		response.Created = h.buildMediaResponses(userID, medias)
		response.Updated = []MediaResponse{}
		response.Deleted = []string{}

	} else {
		// 【保留原逻辑】如果 since 不为空，执行增量同步
		since, err := time.Parse(iso8601Format, sinceStr)
		if err != nil {
			core.Error(c, "Invalid 'since' timestamp format. Use ISO 8601.")
			return
		}

		// 查询已变更的记录 (包括软删除的)
		err = h.DB.Unscoped().
			Where("user_id = ? AND updated_at > ?", userID, since).
			Find(&medias).Error
		if err != nil {
			core.Error(c, "Failed to fetch changes from database: "+err.Error())
			return
		}

		// 分类处理变更
		var createdOrUpdated []models.Media
		var deletedUUIDs = []string{}
		for _, media := range medias {
			if media.DeletedAt.Valid && media.DeletedAt.Time.After(since) {
				deletedUUIDs = append(deletedUUIDs, media.UUID)
			} else if !media.DeletedAt.Valid {
				createdOrUpdated = append(createdOrUpdated, media)
			}
		}

		// 增量同步时，为了简化客户端逻辑，可以将所有非删除的变更都放在 'updated' 字段中
		response.Updated = h.buildMediaResponses(userID, createdOrUpdated)
		response.Created = []MediaResponse{}
		response.Deleted = deletedUUIDs
	}

	core.Success(c, "Changes retrieved successfully", response)
}

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

func (h *MediaHandler) buildMediaResponses(userID uint, medias []models.Media) []MediaResponse {
	mediaResponses := make([]MediaResponse, 0, len(medias))

	for _, media := range medias {
		resp := h.buildMediaResponse(userID, media)
		mediaResponses = append(mediaResponses, *resp)
	}

	return mediaResponses
}

// @Summary      初始化大文件分片上传
// @Description  请求开始一个大文件的上传。服务器会先进行秒传检查，如果文件不存在，则创建一个上传作业并返回 upload_id。
// @Tags         Media
// @Accept       json
// @Produce      json
// @Param        body body InitiateUploadRequest true "文件元数据"
// @Success      200  {object}  core.ApiResponse{data=MediaResponse} "文件已存在（秒传成功）"
// @Success      201  {object}  core.ApiResponse{data=InitiateUploadResponse} "初始化成功，可以开始上传分片"
// @Failure      400  {object}  core.ApiResponse "请求参数错误"
// @Security     BearerAuth
// @Router       /media/upload/initiate [post]
func (h *MediaHandler) InitiateUpload(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var req InitiateUploadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		core.Error(c, "Invalid request body: "+err.Error())
		return
	}

	// 1. 秒传检查
	var existingMedia models.Media
	if err := h.DB.First(&existingMedia, "hash = ? AND user_id = ?", req.Hash, userID).Error; err == nil {
		core.Success(c, "File already exists for this user", h.buildMediaResponse(userID, existingMedia))
		return
	}

	// 2. 创建上传作业
	uploadID := uuid.New().String()
	numChunks := int(req.TotalSize / int64(chunkSize))
	if req.TotalSize%int64(chunkSize) != 0 {
		numChunks++
	}

	task := models.UploadTask{
		ID:        uploadID,
		UserID:    userID,
		FileHash:  req.Hash,
		TotalSize: req.TotalSize,
		ChunkSize: chunkSize,
		NumChunks: numChunks,
		Status:    "INITIATED",
		CreatedAt: time.Now(),
		ExpiresAt: time.Now().Add(24 * time.Hour), // 设置24小时过期
	}

	if err := h.DB.Create(&task).Error; err != nil {
		core.Error(c, "Failed to create upload task: "+err.Error())
		return
	}

	// 3. 准备临时目录并检查已存在的分片 (用于断点续传)
	tmpDir := filepath.Join(h.UploadDir, tmpUploadDir, uploadID)
	if err := os.MkdirAll(tmpDir, 0755); err != nil {
		core.Error(c, "Failed to create temporary directory")
		return
	}

	var uploadedChunks []int
	files, err := os.ReadDir(tmpDir)
	if err == nil {
		for _, file := range files {
			chunkIndex, err := strconv.Atoi(file.Name())
			if err == nil {
				uploadedChunks = append(uploadedChunks, chunkIndex)
			}
		}
	}
	sort.Ints(uploadedChunks)

	// 4. 返回响应
	resp := InitiateUploadResponse{
		UploadID:       uploadID,
		ChunkSize:      chunkSize,
		UploadedChunks: uploadedChunks,
	}
	core.Created(c, "Upload initiated successfully", resp)
}

// @Summary      上传单个文件分片
// @Description  上传指定 upload_id 和 chunk_index 的文件分片。
// @Tags         Media
// @Accept       multipart/form-data
// @Produce      json
// @Param        upload_id formData string true "上传作业ID"
// @Param        chunk_index formData int true "分片索引 (从0开始)"
// @Param        chunk formData file true "分片文件本身"
// @Success      204 "分片上传成功 (无返回内容)"
// @Failure      400 {object} core.ApiResponse "请求参数错误、任务状态无效或任务已过期"
// @Failure      404 {object} core.ApiResponse "上传作业不存在"
// @Failure      500 {object} core.ApiResponse "服务器内部错误"
// @Security     BearerAuth
// @Router       /media/upload/chunk [post]
func (h *MediaHandler) UploadChunk(c *gin.Context) {
	// --- 1. 参数解析与校验 ---
	uploadID := c.PostForm("upload_id")
	chunkIndexStr := c.PostForm("chunk_index")
	if uploadID == "" || chunkIndexStr == "" {
		// 使用新函数返回 400 Bad Request
		core.ErrorWithStatus(c, http.StatusBadRequest, "upload_id and chunk_index are required")
		return
	}

	chunkIndex, err := strconv.Atoi(chunkIndexStr)
	if err != nil {
		core.ErrorWithStatus(c, http.StatusBadRequest, "chunk_index must be a valid integer")
		return
	}

	// --- 2. 查找并校验上传任务 ---
	var task models.UploadTask
	if err := h.DB.First(&task, "id = ?", uploadID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			// 使用新函数返回 404 Not Found
			core.ErrorWithStatus(c, http.StatusNotFound, "Upload task not found")
		} else {
			// 使用新函数返回 500 Internal Server Error
			log.Printf("Database error while finding upload task %s: %v", uploadID, err)
			core.ErrorWithStatus(c, http.StatusInternalServerError, "Failed to retrieve upload task information")
		}
		return
	}

	if task.Status != "INITIATED" {
		core.ErrorWithStatus(c, http.StatusBadRequest, fmt.Sprintf("Cannot upload chunk for a task with status '%s'", task.Status))
		return
	}
	if time.Now().After(task.ExpiresAt) {
		core.ErrorWithStatus(c, http.StatusBadRequest, "This upload task has expired")
		return
	}

	// --- 3. 获取并处理上传的分片文件 ---
	fileHeader, err := c.FormFile("chunk")
	if err != nil {
		core.ErrorWithStatus(c, http.StatusBadRequest, "Form field 'chunk' is missing or invalid")
		return
	}

	file, err := fileHeader.Open()
	if err != nil {
		log.Printf("Error opening uploaded file for task %s: %v", uploadID, err)
		core.ErrorWithStatus(c, http.StatusInternalServerError, "Could not process uploaded file")
		return
	}
	defer file.Close()

	// --- 4. 保存分片到磁盘 ---
	tmpDir := filepath.Join(h.UploadDir, "tmp_uploads", uploadID)
	if err := os.MkdirAll(tmpDir, 0750); err != nil {
		log.Printf("FATAL: Could not create chunk directory %s: %v", tmpDir, err)
		core.ErrorWithStatus(c, http.StatusInternalServerError, "Failed to prepare storage for chunk")
		return
	}

	chunkPath := filepath.Join(tmpDir, strconv.Itoa(chunkIndex))
	outFile, err := os.Create(chunkPath)
	if err != nil {
		log.Printf("FATAL: Could not create chunk file %s: %v", chunkPath, err)
		core.ErrorWithStatus(c, http.StatusInternalServerError, "Failed to save chunk")
		return
	}
	defer outFile.Close()

	if _, err = io.Copy(outFile, file); err != nil {
		log.Printf("FATAL: Could not write chunk to disk %s: %v", chunkPath, err)
		core.ErrorWithStatus(c, http.StatusInternalServerError, "Failed to write chunk to disk")
		return
	}

	// --- 5. 成功响应 ---
	// 使用新增的 NoContent 辅助函数返回 204
	core.NoContent(c)
}

// @Summary      完成分片上传
// @Description  通知服务器所有分片已上传完毕，请求合并文件并创建媒体记录。
// @Tags         Media
// @Accept       json
// @Produce      json
// @Param        body body CompleteUploadRequest true "完成上传所需的信息"
// @Success      200  {object}  core.ApiResponse{data=MediaResponse} "文件合并成功"
// @Failure      400  {object}  core.ApiResponse "请求错误、分片不完整或哈希校验失败"
// @Security     BearerAuth
// @Router       /media/upload/complete [post]
func (h *MediaHandler) CompleteUpload(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var req CompleteUploadRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		core.Error(c, "Invalid request body: "+err.Error())
		return
	}

	// 1. 查找上传任务
	var task models.UploadTask
	if err := h.DB.First(&task, "id = ? AND user_id = ?", req.UploadID, userID).Error; err != nil {
		core.Error(c, "Upload task not found or permission denied")
		return
	}
	tmpDir := filepath.Join(h.UploadDir, tmpUploadDir, req.UploadID)
	// 使用 defer 确保无论成功失败都清理临时目录
	defer os.RemoveAll(tmpDir)

	// 2. 校验所有分片是否完整
	for i := 0; i < task.NumChunks; i++ {
		chunkPath := filepath.Join(tmpDir, strconv.Itoa(i))
		if _, err := os.Stat(chunkPath); os.IsNotExist(err) {
			core.Error(c, fmt.Sprintf("Chunk %d is missing", i))
			return
		}
	}

	// 3. 合并文件
	newUUID := uuid.New().String()
	newFilename := newUUID + filepath.Ext(req.OriginalFilename)
	finalPath := filepath.Join(h.UploadDir, newFilename)
	destFile, err := os.Create(finalPath)
	if err != nil {
		core.Error(c, "Failed to create final file")
		return
	}
	defer destFile.Close()

	hasher := sha256.New()
	for i := 0; i < task.NumChunks; i++ {
		chunkPath := filepath.Join(tmpDir, strconv.Itoa(i))
		chunkFile, err := os.Open(chunkPath)
		if err != nil {
			os.Remove(finalPath) // 清理不完整的目标文件
			core.Error(c, "Failed to open chunk for merging")
			return
		}
		// 同时写入目标文件和哈希计算器
		multiWriter := io.MultiWriter(destFile, hasher)
		_, err = io.Copy(multiWriter, chunkFile)
		chunkFile.Close()
		if err != nil {
			os.Remove(finalPath)
			core.Error(c, "Failed to merge chunk")
			return
		}
	}

	// 4. 【关键安全校验】: 对比哈希
	calculatedHash := hex.EncodeToString(hasher.Sum(nil))
	if calculatedHash != req.Hash {
		os.Remove(finalPath) // 哈希不匹配，删除垃圾文件
		core.Error(c, "File hash mismatch. Upload corrupted.")
		return
	}

	// 5. 创建 Media 记录并启动后台处理
	media := models.Media{
		UUID:             newUUID,
		UserID:           userID,
		Hash:             req.Hash,
		ItemType:         req.ItemType,
		OriginalFilename: req.OriginalFilename,
		Filename:         newFilename,
		FileSize:         task.TotalSize, // 使用任务中记录的大小
		ProcessingStatus: constant.StatusPending,
	}
	if err := h.DB.Create(&media).Error; err != nil {
		os.Remove(finalPath)
		core.Error(c, "Failed to save final metadata")
		return
	}

	// 6. 清理 UploadTask 记录
	h.DB.Delete(&task)

	// 7. 启动异步处理
	if media.ItemType == constant.TypeVideo {
		go processing.ProcessVideo(h.DB, finalPath, newUUID)
	} else {
		go processing.ProcessImage(h.DB, finalPath, newUUID)
	}

	// 8. 返回成功响应
	mediaResponse := h.buildMediaResponse(userID, media)
	core.Success(c, "File uploaded and merged successfully", mediaResponse)
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
// @Success      201  {object}  core.ApiResponse{data=MediaResponse} "上传成功，后台处理开始"
// @Success      200  {object}  core.ApiResponse{data=MediaResponse} "文件已存在（秒传成功）"
// @Failure      400  {object}  core.ApiResponse "请求参数错误或服务器内部错误"
// @Failure      500  {object}  core.ApiResponse "服务器文件处理错误"
// @Security     BearerAuth
// @Router       /media/upload-stream [post]
func (h *MediaHandler) UploadStream(c *gin.Context) {
	// 1. 获取元数据和用户ID (这部分逻辑与非流式版本相同)
	userID := c.MustGet("userID").(uint)
	hash := c.PostForm("hash")
	itemTypeStr := c.PostForm("item_type")
	originalFilename := c.PostForm("original_filename")
	cloudUuid := c.PostForm("cloud_uuid")

	// 2. 校验元数据
	if hash == "" {
		core.Error(c, "Form field 'hash' is required")
		return
	}
	itemType := constant.MediaType(itemTypeStr)
	if itemType != constant.TypeImage && itemType != constant.TypeVideo {
		core.Error(c, "Invalid 'item_type'. Must be 'IMAGE' or 'VIDEO'")
		return
	}

	if cloudUuid == "" {
		cloudUuid = uuid.New().String()
	}

	// 3. 秒传检查 (逻辑与非流式版本相同)
	var existingMedia models.Media
	if err := h.DB.First(&existingMedia, "hash = ? AND user_id = ?", hash, userID).Error; err == nil {
		core.Success(c, "File already exists for this user", h.buildMediaResponse(userID, existingMedia))
		return
	}

	// 4. 【核心区别】以流式方式处理文件
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		core.Error(c, "File retrieval failed: "+err.Error())
		return
	}
	defer file.Close() // Multipart file part implements io.ReadCloser

	// 5. 创建目标文件并准备写入
	newFilename := cloudUuid + filepath.Ext(header.Filename)
	filePath := filepath.Join(h.UploadDir, newFilename)

	// 创建一个新的本地文件用于写入
	dst, err := os.Create(filePath)
	if err != nil {
		core.Error(c, "Failed to create destination file on server")
		return
	}
	defer dst.Close()

	// 6. 【关键步骤】将上传流直接复制到文件中
	// io.Copy 会使用缓冲区，高效地从源(上传的文件流)读取并写入到目标(磁盘文件)
	// 这避免了将整个文件读入内存。
	if _, err := io.Copy(dst, file); err != nil {
		// 如果复制失败，删除可能已创建的不完整文件
		os.Remove(filePath)
		core.Error(c, "Failed to save file stream to disk")
		return
	}

	// 7. 文件成功保存后，创建数据库记录 (逻辑与非流式版本相同)
	media := models.Media{
		UUID:             cloudUuid,
		UserID:           userID,
		Hash:             hash,
		ItemType:         itemType,
		OriginalFilename: originalFilename,
		Filename:         newFilename,
		ProcessingStatus: constant.StatusPending,
	}
	if err := h.DB.Create(&media).Error; err != nil {
		// 如果数据库创建失败，删除已保存的文件以避免产生孤立文件
		os.Remove(filePath)
		core.Error(c, "Failed to save metadata to database")
		return
	}

	// 8. 触发异步处理并返回成功响应 (逻辑与非流式版本相同)
	if itemType == constant.TypeVideo {
		go processing.ProcessVideo(h.DB, filePath, cloudUuid)
	} else {
		go processing.ProcessImage(h.DB, filePath, cloudUuid)
	}

	mediaResponse := h.buildMediaResponse(userID, media)
	core.Created(c, "Upload successful, processing started", mediaResponse)
}
