package handlers

import (
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
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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

// Upload 处理单个媒体文件的上传请求
func (h *PhotoHandler) Upload(c *gin.Context) {
	// 从认证中间件获取用户ID
	userID := c.MustGet("userID").(uint)

	// 从表单获取元数据
	hash := c.PostForm("hash")
	itemTypeStr := c.PostForm("item_type")
	originalFilename := c.PostForm("original_filename")

	// 校验必要参数
	if hash == "" {
		core.Error(c, http.StatusBadRequest, "Form field 'hash' is required")
		return
	}
	if itemTypeStr == "" {
		core.Error(c, http.StatusBadRequest, "Form field 'item_type' is required")
		return
	}
	itemType := constant.MediaType(itemTypeStr)
	if itemType != constant.TypeImage && itemType != constant.TypeVideo {
		core.Error(c, http.StatusBadRequest, "Invalid 'item_type'. Must be 'IMAGE' or 'VIDEO'")
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
		core.Error(c, http.StatusBadRequest, "File upload failed: "+err.Error())
		return
	}
	defer file.Close()

	// 读取文件内容
	fileBytes, err := io.ReadAll(file)
	if err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to read file")
		return
	}

	// 生成新文件名并保存文件
	newUUID := uuid.New().String()
	newFilename := newUUID + filepath.Ext(header.Filename)
	filePath := filepath.Join(h.UploadDir, newFilename)
	if err := os.WriteFile(filePath, fileBytes, 0644); err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to save file")
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
		core.Error(c, http.StatusInternalServerError, "Failed to save initial metadata")
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

// GetPhotos 获取当前用户的所有媒体列表（分页）
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
		core.Error(c, http.StatusInternalServerError, "Database error")
		return
	}

	core.Success(c, "Photos retrieved successfully", photos)
}

// Delete 将指定的媒体文件移入回收站（软删除）
func (h *PhotoHandler) Delete(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	photoUUID := c.Param("uuid")

	// 使用 user_id 和 uuid 双重条件来删除，确保用户只能删除自己的照片
	result := h.DB.Where("uuid = ? AND user_id = ?", photoUUID, userID).Delete(&models.Photo{})
	if result.Error != nil {
		core.Error(c, http.StatusInternalServerError, "Database error")
		return
	}
	if result.RowsAffected == 0 {
		core.Error(c, http.StatusNotFound, "Photo not found or permission denied")
		return
	}

	core.Success(c, "Photo moved to bin", nil)
}

// DownloadOriginal 下载原始文件
func (h *PhotoHandler) DownloadOriginal(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	photoUUID := c.Param("uuid")

	var photo models.Photo
	// 校验用户权限
	if err := h.DB.Where("user_id = ?", userID).First(&photo, "uuid = ?", photoUUID).Error; err != nil {
		core.Error(c, http.StatusNotFound, "Photo not found or permission denied")
		return
	}

	// 检查处理状态，如果还在处理中，则不允许下载
	if photo.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, http.StatusAccepted, fmt.Sprintf("File is not ready yet. Current status: %s", photo.ProcessingStatus))
		return
	}

	h.downloadFile(c, photo.Filename)
}

// DownloadPreview 下载预览图或预览视频
func (h *PhotoHandler) DownloadPreview(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	photoUUID := c.Param("uuid")

	var photo models.Photo
	// 校验用户权限
	if err := h.DB.Where("user_id = ?", userID).First(&photo, "uuid = ?", photoUUID).Error; err != nil {
		core.Error(c, http.StatusNotFound, "Photo not found or permission denied")
		return
	}

	if photo.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, http.StatusAccepted, fmt.Sprintf("Preview is not ready yet. Current status: %s", photo.ProcessingStatus))
		return
	}

	// 根据媒体类型决定预览文件的后缀
	suffix := constant.PreviewImageSuffix
	if photo.ItemType == constant.TypeVideo {
		suffix = constant.PreviewVideoSuffix
	}

	h.downloadFile(c, photo.UUID+suffix)
}

// DownloadThumbnail 下载缩略图
func (h *PhotoHandler) DownloadThumbnail(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	photoUUID := c.Param("uuid")

	var photo models.Photo
	// 校验用户权限
	if err := h.DB.Where("user_id = ?", userID).First(&photo, "uuid = ?", photoUUID).Error; err != nil {
		core.Error(c, http.StatusNotFound, "Photo not found or permission denied")
		return
	}

	if photo.ProcessingStatus != constant.StatusCompleted {
		core.Error(c, http.StatusAccepted, fmt.Sprintf("Thumbnail is not ready yet. Current status: %s", photo.ProcessingStatus))
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
		core.Error(c, http.StatusNotFound, "File not available on server")
		return
	}

	c.File(filePath)
}
