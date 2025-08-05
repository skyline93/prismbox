package handlers

import (
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

// CreateAlbumInput 定义了创建相册的请求体结构
type CreateAlbumInput struct {
	Name        string `json:"name" binding:"required" example:"我的家庭聚会"`
	Description string `json:"description" example:"2025年春节的欢乐时光"`
}

// AddItemsToAlbumInput 定义了向相册添加媒体的请求体结构
type AddItemsToAlbumInput struct {
	MediaUUIDs []string `json:"media_uuids" binding:"required"`
}

// CreateAlbum godoc
// @Summary      创建新相册
// @Description  为当前登录的用户创建一个新的相册
// @Tags         Albums
// @Accept       json
// @Produce      json
// @Param        album body CreateAlbumInput true "相册信息"
// @Success      201  {object}  core.ApiResponse{data=models.Album} "相册创建成功"
// @Failure      400  {object}  core.ApiResponse "请求参数错误或服务器内部错误"
// @Security     BearerAuth
// @Router       /albums [post]
func (h *AlbumHandler) CreateAlbum(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var input CreateAlbumInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	album := models.Album{
		UUID:        uuid.New().String(),
		Name:        input.Name,
		Description: input.Description,
		UserID:      userID, // 关联当前登录的用户
	}

	if err := h.DB.Create(&album).Error; err != nil {
		core.Error(c, "Failed to create album")
		return
	}

	core.Success(c, "Album created successfully", album)
}

// GetAlbums godoc
// @Summary      获取相册列表
// @Description  获取当前用户的所有相册列表。为提高性能，此接口不包含媒体内容，只包含数量统计。
// @Tags         Albums
// @Produce      json
// @Success      200  {object}  core.ApiResponse{data=[]models.Album} "成功获取相册列表"
// @Failure      400  {object}  core.ApiResponse "数据库错误"
// @Security     BearerAuth
// @Router       /albums [get]
func (h *AlbumHandler) GetAlbums(c *gin.Context) {
	userID := c.MustGet("userID").(uint)

	var albums []models.Album
	// 添加 user_id 查询条件进行数据隔离
	if err := h.DB.Where("user_id = ?", userID).Order("created_at desc").Find(&albums).Error; err != nil {
		core.Error(c, "Failed to fetch albums")
		return
	}

	// 为每个相册计算其包含的项目数量
	for i := range albums {
		count := h.DB.Model(&albums[i]).Association("Items").Count()
		albums[i].ItemCount = count
	}

	core.Success(c, "Albums retrieved successfully", albums)
}

// GetAlbum godoc
// @Summary      获取单个相册详情
// @Description  获取单个相册及其包含的所有媒体项（分页）
// @Tags         Albums
// @Produce      json
// @Param        uuid path string true "相册的UUID" format(uuid)
// @Param        page query int false "页码" default(1)
// @Param        limit query int false "每页数量" default(100)
// @Success      200  {object}  core.ApiResponse{data=models.Album} "成功获取相册详情"
// @Failure      400  {object}  core.ApiResponse "错误信息可能为 'Album not found or permission denied'"
// @Security     BearerAuth
// @Router       /albums/{uuid} [get]
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
		core.Error(c, "Album not found or permission denied")
		return
	}

	// 分页查询关联的媒体项
	var items []*models.Media
	h.DB.Model(&album).Order("created_at desc").Limit(limit).Offset(offset).Association("Items").Find(&items)
	album.Items = items
	album.ItemCount = h.DB.Model(&album).Association("Items").Count()

	core.Success(c, "Album details retrieved successfully", album)
}

// AddItemsToAlbum godoc
// @Summary      向相册添加媒体
// @Description  向指定相册添加一个或多个媒体项
// @Tags         Albums
// @Accept       json
// @Produce      json
// @Param        uuid path string true "相册的UUID" format(uuid)
// @Param        media_uuids body AddItemsToAlbumInput true "要添加的媒体UUID列表"
// @Success      200  {object}  core.ApiResponse "媒体项添加成功"
// @Failure      400  {object}  core.ApiResponse "请求参数错误、相册或照片未找到、无权限等"
// @Security     BearerAuth
// @Router       /albums/{uuid}/items [post]
func (h *AlbumHandler) AddItemsToAlbum(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	albumUUID := c.Param("uuid")

	var album models.Album
	// 确保用户操作的是自己的相册
	if err := h.DB.Where("user_id = ?", userID).First(&album, "uuid = ?", albumUUID).Error; err != nil {
		core.Error(c, "Album not found or permission denied")
		return
	}

	var input AddItemsToAlbumInput

	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	var mediaToAdd []*models.Media
	// 关键安全校验：确保要添加的照片也属于当前用户
	if err := h.DB.Where("uuid IN ? AND user_id = ?", input.MediaUUIDs, userID).Find(&mediaToAdd).Error; err != nil {
		core.Error(c, "Failed to find media")
		return
	}

	if len(mediaToAdd) == 0 {
		core.Error(c, "None of the provided media were found or you do not have permission")
		return
	}

	// 使用 Append 进行关联添加
	if err := h.DB.Model(&album).Association("Items").Append(mediaToAdd); err != nil {
		core.Error(c, "Failed to add items to album")
		return
	}

	// 如果相册还没有封面，自动将第一张添加的照片设为封面
	if album.CoverMediaUUID == nil && len(mediaToAdd) > 0 {
		firstMediaUUID := mediaToAdd[0].UUID
		h.DB.Model(&album).Update("cover_media_uuid", &firstMediaUUID)
	}

	core.Success(c, "Items added successfully", nil)
}

// DeleteAlbum godoc
// @Summary      删除相册
// @Description  删除相册（软删除）。注意：这只删除相册和关联记录，不删除原始的照片文件。
// @Tags         Albums
// @Produce      json
// @Param        uuid path string true "相册的UUID" format(uuid)
// @Success      200  {object}  core.ApiResponse "相册删除成功"
// @Failure      400  {object}  core.ApiResponse "错误信息可能为 'Album not found' 或 'Failed to delete'"
// @Security     BearerAuth
// @Router       /albums/{uuid} [delete]
func (h *AlbumHandler) DeleteAlbum(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	albumUUID := c.Param("uuid")

	var album models.Album
	// 确保用户只能删除自己的相册
	if err := h.DB.Where("user_id = ?", userID).First(&album, "uuid = ?", albumUUID).Error; err != nil {
		core.Error(c, "Album not found or permission denied")
		return
	}

	// GORM 在软删除主记录时，会自动删除 many2many 的连接表记录
	// 使用 Select(clause.Associations) 来确保级联删除关联
	if err := h.DB.Select(clause.Associations).Delete(&album).Error; err != nil {
		core.Error(c, "Failed to delete album")
		return
	}

	core.Success(c, "Album deleted successfully", nil)
}
