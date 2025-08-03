package handlers

import (
	"net/http"
	"server/core"
	"server/models"
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

// AlbumHandler 封装了所有与相册相关的HTTP处理器
type AlbumHandler struct {
	DB *gorm.DB
}

// CreateAlbum 处理创建新相册的请求
func (h *AlbumHandler) CreateAlbum(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var input struct {
		Name        string `json:"name" binding:"required"`
		Description string `json:"description"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, http.StatusBadRequest, "Invalid input: "+err.Error())
		return
	}

	album := models.Album{
		UUID:        uuid.New().String(),
		Name:        input.Name,
		Description: input.Description,
		UserID:      userID, // 关联当前登录的用户
	}

	if err := h.DB.Create(&album).Error; err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to create album")
		return
	}

	core.Success(c, "Album created successfully", album)
}

// GetAlbums 获取当前用户的所有相册列表
// 这个接口为了性能，不直接返回相册内的媒体项，只返回统计数量
func (h *AlbumHandler) GetAlbums(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var albums []models.Album
	// 添加 user_id 查询条件进行数据隔离
	if err := h.DB.Where("user_id = ?", userID).Order("created_at desc").Find(&albums).Error; err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to fetch albums")
		return
	}

	// 为每个相册计算其包含的项目数量
	for i := range albums {
		count := h.DB.Model(&albums[i]).Association("Items").Count()
		albums[i].ItemCount = count
	}

	core.Success(c, "Albums retrieved successfully", albums)
}

// GetAlbum 获取单个相册的详细信息，包含分页的媒体项
func (h *AlbumHandler) GetAlbum(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	albumUUID := c.Param("uuid")

	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(defaultPageSize)))

	if page < 1 {
		page = 1
	}
	offset := (page - 1) * limit

	var album models.Album
	// 校验用户权限
	if err := h.DB.Where("user_id = ?", userID).First(&album, "uuid = ?", albumUUID).Error; err != nil {
		core.Error(c, http.StatusNotFound, "Album not found or permission denied")
		return
	}

	// 分页查询关联的媒体项
	var items []*models.Photo
	h.DB.Model(&album).Order("created_at desc").Limit(limit).Offset(offset).Association("Items").Find(&items)
	album.Items = items
	album.ItemCount = h.DB.Model(&album).Association("Items").Count()

	core.Success(c, "Album details retrieved successfully", album)
}

// AddItemsToAlbum 向指定相册添加一个或多个媒体项
func (h *AlbumHandler) AddItemsToAlbum(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	albumUUID := c.Param("uuid")

	var album models.Album
	// 确保用户操作的是自己的相册
	if err := h.DB.Where("user_id = ?", userID).First(&album, "uuid = ?", albumUUID).Error; err != nil {
		core.Error(c, http.StatusNotFound, "Album not found or permission denied")
		return
	}

	var input struct {
		PhotoUUIDs []string `json:"photo_uuids" binding:"required"`
	}
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, http.StatusBadRequest, "Invalid input: "+err.Error())
		return
	}

	var photosToAdd []*models.Photo
	// 关键安全校验：确保要添加的照片也属于当前用户
	if err := h.DB.Where("uuid IN ? AND user_id = ?", input.PhotoUUIDs, userID).Find(&photosToAdd).Error; err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to find photos")
		return
	}

	if len(photosToAdd) == 0 {
		core.Error(c, http.StatusBadRequest, "None of the provided photos were found or you do not have permission")
		return
	}

	// 使用 Append 进行关联添加
	if err := h.DB.Model(&album).Association("Items").Append(photosToAdd); err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to add items to album")
		return
	}

	// 如果相册还没有封面，自动将第一张添加的照片设为封面
	if album.CoverPhotoUUID == nil && len(photosToAdd) > 0 {
		firstPhotoUUID := photosToAdd[0].UUID
		h.DB.Model(&album).Update("cover_photo_uuid", &firstPhotoUUID)
	}

	core.Success(c, "Items added successfully", nil)
}

// DeleteAlbum 删除相册（软删除）
// 注意：这只删除相册和关联记录(album_items)，不会删除原始的照片文件
func (h *AlbumHandler) DeleteAlbum(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	albumUUID := c.Param("uuid")

	var album models.Album
	// 确保用户只能删除自己的相册
	if err := h.DB.Where("user_id = ?", userID).First(&album, "uuid = ?", albumUUID).Error; err != nil {
		core.Error(c, http.StatusNotFound, "Album not found or permission denied")
		return
	}

	// GORM 在软删除主记录时，会自动删除 many2many 的连接表记录
	// 使用 Select(clause.Associations) 来确保级联删除关联
	if err := h.DB.Select(clause.Associations).Delete(&album).Error; err != nil {
		core.Error(c, http.StatusInternalServerError, "Failed to delete album")
		return
	}

	core.Success(c, "Album deleted successfully", nil)
}
