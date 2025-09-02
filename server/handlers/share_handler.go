// handlers/share_handler.go

package handlers

import (
	"server/constant"
	"server/core"
	"server/models"
	"server/routing"
	"server/urlsigner"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ShareHandler struct {
	DB               *gorm.DB
	URLSigner        *urlsigner.Signer
	URLBuilder       *routing.URLBuilder
	SignedURLLoadTTL time.Duration
}

type CreateShareInput struct {
	MediaUUID      string `json:"media_uuid" binding:"required"`
	TargetUserID   *uint  `json:"target_user_id,omitempty"`
	DurationMinute int    `json:"duration_minute" binding:"required,min=1"`
}

type ShareMetaResponse struct {
	UUID             string             `json:"uuid"`
	OriginalFilename string             `json:"original_filename"`
	ItemType         constant.MediaType `json:"item_type"`
	Width            int                `json:"width"`
	Height           int                `json:"height"`
	MediaTokenAt     *time.Time         `json:"media_taken_at"`
	SignedURL        string             `json:"signed_url"`
}

// CreateShare godoc
// @Summary      创建分享链接
// @Description  为指定的媒体资源创建一个分享。可以分享给特定用户（通过ID）或游客。
// @Tags         Shares
// @Accept       json
// @Produce      json
// @Param        share_info body CreateShareInput true "分享信息"
// @Success      201 {object} core.ApiResponse{data=string} "成功创建，返回公开分享链接"
// @Failure      400 {object} core.ApiResponse "请求参数错误"
// @Failure      404 {object} core.ApiResponse "照片或目标用户未找到"
// @Security     BearerAuth
// @Router       /shares [post]
func (h *ShareHandler) CreateShare(c *gin.Context) {
	ownerID := c.MustGet("userID").(uint)

	var input CreateShareInput
	if err := c.ShouldBindJSON(&input); err != nil {
		core.Error(c, "Invalid input: "+err.Error())
		return
	}

	// 1. 验证照片是否存在且属于分享者
	var media models.Media
	if err := h.DB.First(&media, "uuid = ? AND user_id = ?", input.MediaUUID, ownerID).Error; err != nil {
		core.Error(c, "Media not found or permission denied")
		return
	}

	// --- ❗ 核心改动：直接使用 TargetUserID，不再通过用户名查找 ---
	// 2. 如果指定了目标用户ID，验证该用户是否存在
	if input.TargetUserID != nil {
		var targetUser models.User
		// 验证目标用户ID确实存在于数据库中
		if err := h.DB.First(&targetUser, *input.TargetUserID).Error; err != nil {
			core.Error(c, "Target user with the given ID not found")
			return
		}
	}

	// 3. 创建分享记录
	share := models.Share{
		ShareToken:   uuid.NewString(),
		OwnerID:      ownerID,
		TargetUserID: input.TargetUserID, // 直接使用传入的ID
		MediaID:      media.ID,
		ExpiresAt:    time.Now().Add(time.Minute * time.Duration(input.DurationMinute)),
	}

	if err := h.DB.Create(&share).Error; err != nil {
		core.Error(c, "Failed to create share record")
		return
	}

	// 4. 构建并返回公开链接
	publicURL := h.URLBuilder.BuildPublicShareURL(share.ShareToken)
	core.Success(c, "Share link created successfully", publicURL)
}

// ListSharedWithMe godoc
// @Summary      查看分享给我的内容
// @Description  列出其他用户分享给当前登录用户的所有有效媒体
// @Tags         Shares
// @Produce      json
// @Success      200 {object} core.ApiResponse{data=[]models.Share} "成功获取列表"
// @Security     BearerAuth
// @Router       /shares/with-me [get]
func (h *ShareHandler) ListSharedWithMe(c *gin.Context) {
	userID := c.MustGet("userID").(uint)
	var shares []models.Share

	// 预加载Media和Owner信息
	err := h.DB.Preload("Media").Preload("Owner").
		Where("target_user_id = ? AND is_revoked = ? AND expires_at > ?", userID, false, time.Now()).
		Find(&shares).Error

	if err != nil {
		core.Error(c, "Failed to fetch shares")
		return
	}

	core.Success(c, "Shares retrieved successfully", shares)
}

// GetShareMetadata godoc
// @Summary      获取分享元数据 (API客户端使用)
// @Description  通过分享令牌获取媒体资源的元数据和临时的下载URL。这是为移动端等API客户端设计的。
// @Tags         Shares
// @Produce      json
// @Param        share_token path string true "分享令牌"
// @Success      200 {object} core.ApiResponse{data=ShareMetaResponse} "成功，返回照片元数据，并在其中动态添加一个临时的signed_url字段"
// @Failure      404 {object} core.ApiResponse "分享链接不存在"
// @Failure      410 {object} core.ApiResponse "分享链接已过期或被撤销"
// @Router       /shares/{share_token}/meta [get]
func (h *ShareHandler) GetShareMetadata(c *gin.Context) {
	shareToken := c.Param("share_token")

	// 1. 在数据库中查找分享记录
	var share models.Share
	err := h.DB.Preload("Media").Where("share_token = ?", shareToken).First(&share).Error
	if err != nil {
		core.Error(c, "Share link not found")
		return
	}

	// 2. 验证分享链接的有效性
	if share.IsRevoked {
		core.Error(c, "This share link has been revoked.")
		return
	}
	if time.Now().After(share.ExpiresAt) {
		core.Error(c, "This share link has expired.")
		return
	}

	// --- 核心区别 ---
	// 3. 生成一个极短时效的签名URL
	resourcePath := h.URLBuilder.BuildMediaPreviewPath(share.Media.UUID)
	signedURL, err := h.URLSigner.Generate(resourcePath, 0, h.SignedURLLoadTTL)
	if err != nil {
		core.Error(c, "Failed to generate temporary resource URL")
		return
	}

	// 为了不在原始模型上添加字段，我们创建一个map来组合响应
	responseData := ShareMetaResponse{
		UUID:             share.Media.UUID,
		ItemType:         share.Media.ItemType,
		OriginalFilename: share.Media.OriginalFilename,
		Width:            share.Media.Width,
		Height:           share.Media.Height,
		MediaTokenAt:     share.Media.MediaTakenAt,
		SignedURL:        signedURL, // 将临时的下载链接附加到响应中
	}

	// 4. 返回纯粹的JSON数据
	core.Success(c, "Share metadata retrieved successfully", responseData)
}
