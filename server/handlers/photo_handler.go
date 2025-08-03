package handlers

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
	"server/constant"
	"server/core"
	"server/models"
	"server/processing"
	"strconv"

	"github.com/google/uuid"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

const (
	defaultPageSize = 100
)

// PhotoHandler 封装了所有与照片/视频相关的HTTP处理器
type PhotoHandler struct {
	DB        *gorm.DB
	UploadDir string
}

// Upload godoc
// @Summary      上传单个媒体文件
// @Description  通过 multipart/form-data 上传照片或视频。服务器会先进行秒传检查。
// @Tags         Photos
// @Accept       multipart/form-data
// @Produce      json
// @Param        file formData file true "媒体文件本身"
// @Param        hash formData string true "文件的SHA256哈希值"
// @Param        item_type formData string true "媒体类型 (IMAGE 或 VIDEO)" Enums(IMAGE, VIDEO)
// @Param        original_filename formData string false "文件的原始名称"
// @Success      201  {object}  core.ApiResponse{data=models.Photo} "上传成功，后台处理开始"
// @Success      200  {object}  core.ApiResponse{data=models.Photo} "文件已存在（秒传成功）"
// @Failure      400  {object}  core.ApiResponse "请求参数错误、文件上传失败或服务器内部错误"
// @Security     BearerAuth
// @Router       /photos/upload [post]
func (h *PhotoHandler) Upload(c *gin.Context) {
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
	var existingPhoto models.Photo
	if err := h.DB.First(&existingPhoto, "hash = ? AND user_id = ?", hash, userID).Error; err == nil {
		core.Success(c, "File already exists for this user", existingPhoto)
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
	photo := models.Photo{
		UUID:             newUUID,
		UserID:           userID,
		Hash:             hash,
		ItemType:         itemType,
		OriginalFilename: originalFilename,
		Filename:         newFilename,
		ProcessingStatus: constant.StatusPending,
	}
	if err := h.DB.Create(&photo).Error; err != nil {
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

	// 返回成功响应
	core.Success(c, "Upload successful, processing started", photo)
}

// GetPhotos godoc
// @Summary      获取媒体列表
// @Description  获取当前用户的所有媒体列表（分页）
// @Tags         Photos
// @Produce      json
// @Param        page query int false "页码" default(1)
// @Param        limit query int false "每页数量" default(100)
// @Success      200  {object}  core.ApiResponse{data=[]models.Photo} "成功获取媒体列表"
// @Failure      400  {object}  core.ApiResponse "数据库错误"
// @Security     BearerAuth
// @Router       /photos [get]
func (h *PhotoHandler) GetPhotos(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(defaultPageSize)))

	if page < 1 {
		page = 1
	}
	offset := (page - 1) * limit

	var photos []models.Photo
	// 添加 user_id 查询条件进行数据隔离
	if err := h.DB.Where("user_id = ?", userID).Order("created_at desc").Limit(limit).Offset(offset).Find(&photos).Error; err != nil {
		core.Error(c, "Database error")
		return
	}

	core.Success(c, "Photos retrieved successfully", photos)
}

// Delete godoc
// @Summary      删除指定的媒体文件
// @Description  将指定的媒体文件移入回收站（软删除）
// @Tags         Photos
// @Produce      json
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse "成功删除"
// @Failure      400  {object}  core.ApiResponse "错误信息可能为 'Photo not found or permission denied' 或 'Database error'"
// @Security     BearerAuth
// @Router       /photos/{uuid} [delete]
func (h *PhotoHandler) Delete(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	photoUUID := c.Param("uuid")

	// 使用 user_id 和 uuid 双重条件来删除，确保用户只能删除自己的照片
	result := h.DB.Where("uuid = ? AND user_id = ?", photoUUID, userID).Delete(&models.Photo{})
	if result.Error != nil {
		core.Error(c, "Database error")
		return
	}
	if result.RowsAffected == 0 {
		core.Error(c, "Photo not found or permission denied")
		return
	}

	core.Success(c, "Photo moved to bin", nil)
}

// DownloadOriginal godoc
// @Summary      下载原始文件
// @Description  下载指定UUID的原始媒体文件。
// @Tags         Photos
// @Produce      application/octet-stream
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200 {file} file "原始文件数据"
// @Failure      400 {object} core.ApiResponse "错误信息可能为 'Photo not found' 或 'File is not ready yet'"
// @Security     BearerAuth
// @Router       /photos/{uuid}/download/original [get]
func (h *PhotoHandler) DownloadOriginal(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	photoUUID := c.Param("uuid")

	var photo models.Photo
	// 校验用户权限
	if err := h.DB.Where("user_id = ?", userID).First(&photo, "uuid = ?", photoUUID).Error; err != nil {
		core.Error(c, "Photo not found or permission denied")
		return
	}

	// 检查处理状态，如果还在处理中，则不允许下载
	if photo.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, fmt.Sprintf("File is not ready yet. Current status: %s", photo.ProcessingStatus))
		return
	}

	h.downloadFile(c, photo.Filename)
}

// DownloadPreview godoc
// @Summary      获取预览图或预览视频
// @Description  获取指定UUID的预览文件 (图片为 .jpg, 视频为 .mp4)。
// @Tags         Photos
// @Produce      image/jpeg
// @Produce      video/mp4
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200 {file} file "预览文件数据"
// @Failure      400 {object} core.ApiResponse "错误信息可能为 'Preview not found' 或 'Preview is not ready yet'"
// @Security     BearerAuth
// @Router       /photos/{uuid}/download/preview [get]
func (h *PhotoHandler) DownloadPreview(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	photoUUID := c.Param("uuid")

	var photo models.Photo
	// 校验用户权限
	if err := h.DB.Where("user_id = ?", userID).First(&photo, "uuid = ?", photoUUID).Error; err != nil {
		core.Error(c, "Photo not found or permission denied")
		return
	}

	if photo.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, fmt.Sprintf("Preview is not ready yet. Current status: %s", photo.ProcessingStatus))
		return
	}

	// 根据媒体类型决定预览文件的后缀
	suffix := constant.PreviewImageSuffix
	if photo.ItemType == constant.TypeVideo {
		suffix = constant.PreviewVideoSuffix
	}

	h.downloadFile(c, photo.UUID+suffix)
}

// DownloadThumbnail godoc
// @Summary      获取缩略图
// @Description  获取指定UUID的缩略图 (统一为 .jpg 格式)。
// @Tags         Photos
// @Produce      image/jpeg
// @Param        uuid path string true "媒体文件的UUID" format(uuid)
// @Success      200 {file} file "缩略图文件数据"
// @Failure      400 {object} core.ApiResponse "错误信息可能为 'Thumbnail not found' 或 'Thumbnail is not ready yet'"
// @Security     BearerAuth
// @Router       /photos/{uuid}/download/thumbnail [get]
func (h *PhotoHandler) DownloadThumbnail(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	photoUUID := c.Param("uuid")

	var photo models.Photo
	// 校验用户权限
	if err := h.DB.Where("user_id = ?", userID).First(&photo, "uuid = ?", photoUUID).Error; err != nil {
		core.Error(c, "Photo not found or permission denied")
		return
	}

	if photo.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, fmt.Sprintf("Thumbnail is not ready yet. Current status: %s", photo.ProcessingStatus))
		return
	}

	// 缩略图总是使用统一的后缀
	h.downloadFile(c, c.Param("uuid")+constant.ThumbSuffix)
}

// downloadFile 是一个私有辅助函数，用于从磁盘提供文件下载
func (h *PhotoHandler) downloadFile(c *gin.Context, filename string) {
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
