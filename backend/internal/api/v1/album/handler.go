package album

import (
	"errors"
	"net/http"

	"github.com/album/backend/internal/api/middleware"
	"github.com/album/backend/internal/api/response"
	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	albumencryption "github.com/album/backend/internal/service/album_encryption"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Handler 相册处理器
type Handler struct {
	albumEncryptionService albumencryption.Service
	albumRepo              repository.AlbumRepository
	mediaRepo              repository.MediaRepository
	db                     *gorm.DB
	log                    logger.Logger
}

// NewHandler 创建相册处理器
func NewHandler(
	albumEncryptionService albumencryption.Service,
	albumRepo repository.AlbumRepository,
	mediaRepo repository.MediaRepository,
	db *gorm.DB,
) *Handler {
	return &Handler{
		albumEncryptionService: albumEncryptionService,
		albumRepo:              albumRepo,
		mediaRepo:              mediaRepo,
		db:                     db,
		log:                    logger.New("api.v1.album"),
	}
}

// SetPasswordInput 设置密码请求
type SetPasswordInput struct {
	Password string `json:"password" binding:"required,min=8" example:"password123"` // 密码（至少8位）
}

// ChangePasswordInput 更改密码请求
type ChangePasswordInput struct {
	OldPassword string `json:"old_password" binding:"required" example:"oldpassword123"`       // 旧密码
	NewPassword string `json:"new_password" binding:"required,min=8" example:"newpassword123"` // 新密码（至少8位）
}

// VerifyPasswordInput 验证密码请求
type VerifyPasswordInput struct {
	Password string `json:"password" binding:"required" example:"password123"` // 密码
}

// VerifyPasswordResponse 验证密码响应
type VerifyPasswordResponse struct {
	Token     string `json:"token" example:"abc123..."`                 // 会话令牌
	ExpiresAt string `json:"expires_at" example:"2024-01-01T12:00:00Z"` // 过期时间（ISO 8601格式）
}

// AddAssetsInput 添加资产请求
type AddAssetsInput struct {
	AssetIDs []string `json:"asset_ids" binding:"required" example:"[\"asset1\",\"asset2\"]"` // 资产ID列表
}

// RemoveAssetsInput 移除资产请求
type RemoveAssetsInput struct {
	AssetIDs []string `json:"asset_ids" binding:"required" example:"[\"asset1\",\"asset2\"]"` // 资产ID列表
}

// SetPassword 设置或更新相册密码
// @Summary      设置相册密码
// @Description  为加密空间相册设置或更新密码。设置密码后，所有现有会话令牌将被撤销。
// @Tags         Album
// @Accept       json
// @Produce      json
// @Param        albumId path string true "相册ID"
// @Param        input body SetPasswordInput true "密码信息"
// @Success      200 {object} response.ApiResponse "密码设置成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "未授权"
// @Failure      404 {object} response.ApiResponse "相册不存在"
// @Router       /albums/{albumId}/password [post]
func (h *Handler) SetPassword(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	albumID := c.Param("albumId")

	var input SetPasswordInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	ctx := c.Request.Context()
	if err := h.albumEncryptionService.SetPassword(ctx, albumID, userID, input.Password); err != nil {
		if errors.Is(err, albumencryption.ErrAlbumNotFound) {
			response.ErrorNotFound(c, "Album not found")
			return
		}
		h.log.Error("Failed to set password", logger.Error(err), logger.String("albumID", albumID), logger.Int("userID", int(userID)))
		response.Error(c, "Failed to set password")
		return
	}

	response.Success(c, "Password set successfully", nil)
}

// ChangePassword 更改相册密码
// @Summary      更改相册密码
// @Description  更改加密空间相册的密码。需要提供旧密码进行验证。更改密码后，所有现有会话令牌将被撤销。
// @Tags         Album
// @Accept       json
// @Produce      json
// @Param        albumId path string true "相册ID"
// @Param        input body ChangePasswordInput true "密码信息"
// @Success      200 {object} response.ApiResponse "密码更改成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "未授权"
// @Failure      403 {object} response.ApiResponse "旧密码错误"
// @Failure      404 {object} response.ApiResponse "相册不存在"
// @Router       /albums/{albumId}/password/change [post]
func (h *Handler) ChangePassword(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	albumID := c.Param("albumId")

	var input ChangePasswordInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	ctx := c.Request.Context()
	if err := h.albumEncryptionService.ChangePassword(ctx, albumID, userID, input.OldPassword, input.NewPassword); err != nil {
		if errors.Is(err, albumencryption.ErrAlbumNotFound) {
			response.ErrorNotFound(c, "Album not found")
			return
		}
		if errors.Is(err, albumencryption.ErrInvalidPassword) {
			response.ErrorWithStatus(c, http.StatusForbidden, "Invalid old password")
			return
		}
		if errors.Is(err, albumencryption.ErrPasswordNotSet) {
			response.ErrorWithStatus(c, http.StatusForbidden, "Password not set for this album")
			return
		}
		if errors.Is(err, albumencryption.ErrAlbumNotEncrypted) {
			response.ErrorWithStatus(c, http.StatusForbidden, "Album is not encrypted")
			return
		}
		h.log.Error("Failed to change password", logger.Error(err), logger.String("albumID", albumID), logger.Int("userID", int(userID)))
		response.Error(c, "Failed to change password")
		return
	}

	response.Success(c, "Password changed successfully", nil)
}

// VerifyPassword 验证密码并获取会话令牌
// @Summary      验证密码
// @Description  验证加密空间相册的密码，验证成功后返回会话令牌。
// @Tags         Album
// @Accept       json
// @Produce      json
// @Param        albumId path string true "相册ID"
// @Param        input body VerifyPasswordInput true "密码信息"
// @Success      200 {object} response.ApiResponse{data=VerifyPasswordResponse} "验证成功，返回会话令牌"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "未授权"
// @Failure      404 {object} response.ApiResponse "相册不存在"
// @Failure      403 {object} response.ApiResponse "密码错误或相册未加密"
// @Router       /albums/{albumId}/verify-password [post]
func (h *Handler) VerifyPassword(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	albumID := c.Param("albumId")

	var input VerifyPasswordInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	ctx := c.Request.Context()
	sessionToken, err := h.albumEncryptionService.VerifyPassword(ctx, albumID, userID, input.Password)
	if err != nil {
		if errors.Is(err, albumencryption.ErrAlbumNotFound) {
			response.ErrorNotFound(c, "Album not found")
			return
		}
		if errors.Is(err, albumencryption.ErrInvalidPassword) {
			response.ErrorWithStatus(c, http.StatusForbidden, "Invalid password")
			return
		}
		if errors.Is(err, albumencryption.ErrPasswordNotSet) {
			response.ErrorWithStatus(c, http.StatusForbidden, "Password not set for this album")
			return
		}
		if errors.Is(err, albumencryption.ErrAlbumNotEncrypted) {
			response.ErrorWithStatus(c, http.StatusForbidden, "Album is not encrypted")
			return
		}
		h.log.Error("Failed to verify password", logger.Error(err), logger.String("albumID", albumID), logger.Int("userID", int(userID)))
		response.Error(c, "Failed to verify password")
		return
	}

	response.Success(c, "Password verified successfully", VerifyPasswordResponse{
		Token:     sessionToken.Token,
		ExpiresAt: sessionToken.ExpiresAt.Format("2006-01-02T15:04:05Z07:00"),
	})
}

// RevokeAllSessions 撤销所有会话令牌
// @Summary      撤销所有会话令牌
// @Description  撤销指定相册的所有会话令牌，通常在密码更改后调用。
// @Tags         Album
// @Accept       json
// @Produce      json
// @Param        albumId path string true "相册ID"
// @Success      200 {object} response.ApiResponse "撤销成功"
// @Failure      401 {object} response.ApiResponse "未授权"
// @Failure      404 {object} response.ApiResponse "相册不存在"
// @Router       /albums/{albumId}/sessions [delete]
func (h *Handler) RevokeAllSessions(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	albumID := c.Param("albumId")

	ctx := c.Request.Context()
	if err := h.albumEncryptionService.RevokeAllSessions(ctx, albumID, userID); err != nil {
		if errors.Is(err, albumencryption.ErrAlbumNotFound) {
			response.ErrorNotFound(c, "Album not found")
			return
		}
		h.log.Error("Failed to revoke sessions", logger.Error(err), logger.String("albumID", albumID), logger.Int("userID", int(userID)))
		response.Error(c, "Failed to revoke sessions")
		return
	}

	response.Success(c, "All sessions revoked successfully", nil)
}

// AddAssets 添加资产到加密空间
// @Summary      添加资产到加密空间
// @Description  将资产添加到加密空间相册。需要提供有效的会话令牌。
// @Tags         Album
// @Accept       json
// @Produce      json
// @Param        albumId path string true "相册ID"
// @Param        X-Session-Token header string true "会话令牌"
// @Param        input body AddAssetsInput true "资产ID列表"
// @Success      200 {object} response.ApiResponse "添加成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "未授权"
// @Failure      403 {object} response.ApiResponse "会话令牌无效或已过期"
// @Failure      404 {object} response.ApiResponse "相册不存在"
// @Router       /albums/{albumId}/assets [post]
func (h *Handler) AddAssets(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	albumID := c.Param("albumId")

	// 验证会话令牌（通过中间件）
	// 会话令牌验证在中间件中完成

	var input AddAssetsInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	ctx := c.Request.Context()

	// 验证相册存在且属于该用户
	album, err := h.albumRepo.FindByUUID(ctx, albumID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, "Album not found")
			return
		}
		h.log.Error("Failed to find album", logger.Error(err), logger.String("albumID", albumID))
		response.Error(c, "Failed to find album")
		return
	}

	// 验证相册属于该用户
	if album.UserID != userID {
		response.ErrorNotFound(c, "Album not found")
		return
	}

	// 验证资产存在且属于该用户
	var medias []*models.Media
	for _, assetID := range input.AssetIDs {
		media, err := h.mediaRepo.FindActiveByUUIDAndUser(ctx, assetID, userID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				h.log.Warn("Asset not found or not owned by user", logger.String("assetID", assetID), logger.Int("userID", int(userID)))
				continue
			}
			h.log.Error("Failed to find asset", logger.Error(err), logger.String("assetID", assetID))
			continue
		}
		medias = append(medias, media)
	}

	if len(medias) == 0 {
		response.Error(c, "No valid assets found")
		return
	}

	// 使用 GORM 的 Association 添加资产到相册
	if err := h.db.WithContext(ctx).Model(album).Association("Items").Append(medias); err != nil {
		h.log.Error("Failed to add assets to album", logger.Error(err), logger.String("albumID", albumID))
		response.Error(c, "Failed to add assets to album")
		return
	}

	h.log.Info("Assets added to encrypted space", logger.String("albumID", albumID), logger.Int("userID", int(userID)), logger.Int("assetCount", len(medias)))

	response.Success(c, "Assets added successfully", gin.H{
		"added_count": len(medias),
	})
}

// RemoveAssets 从加密空间移除资产
// @Summary      从加密空间移除资产
// @Description  从加密空间相册中移除资产。需要提供有效的会话令牌。
// @Tags         Album
// @Accept       json
// @Produce      json
// @Param        albumId path string true "相册ID"
// @Param        X-Session-Token header string true "会话令牌"
// @Param        input body RemoveAssetsInput true "资产ID列表"
// @Success      200 {object} response.ApiResponse "移除成功"
// @Failure      400 {object} response.ApiResponse "请求参数错误"
// @Failure      401 {object} response.ApiResponse "未授权"
// @Failure      403 {object} response.ApiResponse "会话令牌无效或已过期"
// @Failure      404 {object} response.ApiResponse "相册不存在"
// @Router       /albums/{albumId}/assets [delete]
func (h *Handler) RemoveAssets(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	albumID := c.Param("albumId")

	// 验证会话令牌（通过中间件）
	// 会话令牌验证在中间件中完成

	var input RemoveAssetsInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	ctx := c.Request.Context()

	// 验证相册存在且属于该用户
	album, err := h.albumRepo.FindByUUID(ctx, albumID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, "Album not found")
			return
		}
		h.log.Error("Failed to find album", logger.Error(err), logger.String("albumID", albumID))
		response.Error(c, "Failed to find album")
		return
	}

	// 验证相册属于该用户
	if album.UserID != userID {
		response.ErrorNotFound(c, "Album not found")
		return
	}

	// 验证资产存在且属于该用户
	var medias []*models.Media
	for _, assetID := range input.AssetIDs {
		media, err := h.mediaRepo.FindActiveByUUIDAndUser(ctx, assetID, userID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				h.log.Warn("Asset not found or not owned by user", logger.String("assetID", assetID), logger.Int("userID", int(userID)))
				continue
			}
			h.log.Error("Failed to find asset", logger.Error(err), logger.String("assetID", assetID))
			continue
		}
		medias = append(medias, media)
	}

	if len(medias) == 0 {
		response.Error(c, "No valid assets found")
		return
	}

	// 使用 GORM 的 Association 从相册移除资产
	if err := h.db.WithContext(ctx).Model(album).Association("Items").Delete(medias); err != nil {
		h.log.Error("Failed to remove assets from album", logger.Error(err), logger.String("albumID", albumID))
		response.Error(c, "Failed to remove assets from album")
		return
	}

	h.log.Info("Assets removed from encrypted space", logger.String("albumID", albumID), logger.Int("userID", int(userID)), logger.Int("assetCount", len(medias)))

	response.Success(c, "Assets removed successfully", gin.H{
		"removed_count": len(medias),
	})
}

// GetOrCreateEncryptedSpace 获取或创建加密空间相册
// @Summary      获取或创建加密空间相册
// @Description  获取用户的加密空间相册，如果不存在则创建。
// @Tags         Album
// @Accept       json
// @Produce      json
// @Success      200 {object} response.ApiResponse{data=object} "相册信息"
// @Failure      401 {object} response.ApiResponse "未授权"
// @Router       /albums/encrypted-space [get]
func (h *Handler) GetOrCreateEncryptedSpace(c *gin.Context) {
	userID := middleware.MustGetUserID(c)

	ctx := c.Request.Context()
	album, err := h.albumEncryptionService.GetOrCreateEncryptedAlbum(ctx, userID)
	if err != nil {
		h.log.Error("Failed to get or create encrypted space", logger.Error(err), logger.Int("userID", int(userID)))
		response.Error(c, "Failed to get or create encrypted space")
		return
	}

	response.Success(c, "Encrypted space retrieved successfully", gin.H{
		"id":           album.UUID,
		"name":         album.Name,
		"description":  album.Description,
		"is_encrypted": album.IsEncrypted,
		"album_type":   album.AlbumType,
		"created_at":   album.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		"updated_at":   album.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
	})
}

// GetAssets 获取加密空间资产列表
// @Summary      获取加密空间资产列表
// @Description  获取加密空间相册的资产列表。需要提供有效的会话令牌。
// @Tags         Album
// @Accept       json
// @Produce      json
// @Param        albumId path string true "相册ID"
// @Param        X-Session-Token header string true "会话令牌"
// @Success      200 {object} response.ApiResponse{data=[]string} "资产ID列表"
// @Failure      401 {object} response.ApiResponse "未授权"
// @Failure      403 {object} response.ApiResponse "会话令牌无效或已过期"
// @Failure      404 {object} response.ApiResponse "相册不存在"
// @Router       /albums/{albumId}/assets [get]
func (h *Handler) GetAssets(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	albumID := c.Param("albumId")

	// 验证会话令牌（通过中间件）
	// 会话令牌验证在中间件中完成

	ctx := c.Request.Context()

	// 验证相册存在且属于该用户
	album, err := h.albumRepo.FindByUUID(ctx, albumID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.ErrorNotFound(c, "Album not found")
			return
		}
		h.log.Error("Failed to find album", logger.Error(err), logger.String("albumID", albumID))
		response.Error(c, "Failed to find album")
		return
	}

	// 验证相册属于该用户
	if album.UserID != userID {
		response.ErrorNotFound(c, "Album not found")
		return
	}

	// 获取相册的所有资产
	var medias []models.Media
	if err := h.db.WithContext(ctx).Model(album).Association("Items").Find(&medias); err != nil {
		h.log.Error("Failed to get assets from album", logger.Error(err), logger.String("albumID", albumID))
		response.Error(c, "Failed to get assets from album")
		return
	}

	// 提取资产ID列表
	assetIDs := make([]string, 0, len(medias))
	for _, media := range medias {
		assetIDs = append(assetIDs, media.UUID)
	}

	h.log.Info("Get assets from encrypted space", logger.String("albumID", albumID), logger.Int("userID", int(userID)), logger.Int("assetCount", len(assetIDs)))

	response.Success(c, "Assets retrieved successfully", gin.H{
		"assets": assetIDs,
	})
}
