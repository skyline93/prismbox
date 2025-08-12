package handlers

import (
	"errors"
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"server/constant"
	"server/core"
	"server/models"
	"server/processing"
	"server/routing"
	"server/urlsigner"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

const (
	defaultPageSize = 100
	iso8601Format   = time.RFC3339
)

type MediaResponse struct {
	UUID             string             `json:"uuid"`
	Filename         string             `json:"filename"`
	OriginalFilename string             `json:"original_filename"`
	ItemType         constant.MediaType `json:"item_type"`
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

	// 使用 user_id 和 uuid 双重条件来删除，确保用户只能删除自己的照片
	result := h.DB.Where("uuid = ? AND user_id = ?", mediaUUID, userID).Delete(&models.Media{})
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
		userID, ok := userIDValue.(string)
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
		// 这是一个服务器侧的问题，文件在数据库里有记录但在磁盘上丢失了
		log.Printf("File record exists in DB but not found on disk: %s", filePath)
		core.Error(c, "File not available on server")
		return
	}

	c.File(filePath)
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
