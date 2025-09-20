// handlers/media_read_handler.go

package handlers

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"server/constant"
	"server/core"
	"server/models"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

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
