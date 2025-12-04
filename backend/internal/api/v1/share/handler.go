package share

import (
	"errors"
	"fmt"
	"net/http"

	"github.com/album/backend/internal/api/dto"
	"github.com/album/backend/internal/api/middleware"
	"github.com/album/backend/internal/api/response"
	shareservice "github.com/album/backend/internal/service/share"
	"github.com/gin-gonic/gin"
)

// Handler 分享处理器
type Handler struct {
	shareService shareservice.Service
}

// NewHandler 创建分享处理器
func NewHandler(shareService shareservice.Service) *Handler {
	return &Handler{
		shareService: shareService,
	}
}

// CreateShare 创建分享链接
// @Summary      创建分享链接
// @Description  创建媒体分享链接，可以指定目标用户或创建公开链接（需要认证）
// @Tags         Shares
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body dto.CreateShareInput true "分享信息"
// @Success      200 {object} response.ApiResponse "创建成功，返回分享URL"
// @Failure      400 {object} response.ApiResponse "媒体不存在、权限不足或目标用户不存在"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /shares [post]
func (h *Handler) CreateShare(c *gin.Context) {
	ownerID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	var input dto.CreateShareInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.Error(c, "Invalid input: "+err.Error())
		return
	}

	publicURL, err := h.shareService.CreateShare(
		c.Request.Context(),
		ownerID,
		input.MediaUUID,
		input.TargetUserID,
		input.DurationMinute,
	)
	if err != nil {
		if errors.Is(err, shareservice.ErrMediaNotFound) || errors.Is(err, shareservice.ErrMediaNotOwned) {
			response.Error(c, "Media not found or permission denied")
			return
		}
		if errors.Is(err, shareservice.ErrUserNotFound) {
			response.Error(c, "Target user with the given ID not found")
			return
		}
		response.Error(c, "Failed to create share record")
		return
	}

	response.Success(c, "Share link created successfully", publicURL)
}

// ListSharedWithMe 查看分享给我的内容
// @Summary      查看分享给我的内容
// @Description  获取所有分享给当前用户的内容列表（需要认证）
// @Tags         Shares
// @Produce      json
// @Security     BearerAuth
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      401 {object} response.ApiResponse "未认证"
// @Router       /shares/with-me [get]
func (h *Handler) ListSharedWithMe(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	shares, err := h.shareService.ListSharedWithMe(c.Request.Context(), userID)
	if err != nil {
		response.Error(c, "Failed to fetch shares")
		return
	}

	response.Success(c, "Shares retrieved successfully", shares)
}

// GetShareMetadata 获取分享元数据
// @Summary      获取分享元数据
// @Description  通过分享令牌获取分享的元数据信息（公开访问，不需要认证）
// @Tags         Shares
// @Produce      json
// @Param        share_token path string true "分享令牌"
// @Success      200 {object} response.ApiResponse "获取成功"
// @Failure      400 {object} response.ApiResponse "分享链接不存在、已撤销或已过期"
// @Router       /shares/{share_token}/meta [get]
func (h *Handler) GetShareMetadata(c *gin.Context) {
	shareToken := c.Param("share_token")

	metadata, err := h.shareService.GetShareMetadata(c.Request.Context(), shareToken)
	if err != nil {
		if errors.Is(err, shareservice.ErrShareNotFound) {
			response.Error(c, "Share link not found")
			return
		}
		if errors.Is(err, shareservice.ErrShareRevoked) {
			response.Error(c, "This share link has been revoked.")
			return
		}
		if errors.Is(err, shareservice.ErrShareExpired) {
			response.Error(c, "This share link has expired.")
			return
		}
		response.Error(c, "Failed to generate temporary resource URL")
		return
	}

	response.Success(c, "Share metadata retrieved successfully", metadata)
}

// GetSharedResource 访问分享的资源
// @Summary      访问分享的资源
// @Description  通过分享令牌访问分享的媒体资源，返回HTML页面（公开访问，不需要认证）
// @Tags         Shares
// @Produce      text/html
// @Param        share_token path string true "分享令牌"
// @Success      200 "HTML页面，包含媒体内容"
// @Failure      400 {object} response.ApiResponse "分享链接不存在、已撤销或已过期"
// @Router       /s/{share_token} [get]
func (h *Handler) GetSharedResource(c *gin.Context) {
	shareToken := c.Param("share_token")

	resource, err := h.shareService.GetSharedResource(c.Request.Context(), shareToken)
	if err != nil {
		if errors.Is(err, shareservice.ErrShareNotFound) {
			response.Error(c, "Share link not found")
			return
		}
		if errors.Is(err, shareservice.ErrShareRevoked) {
			response.Error(c, "This share link has been revoked.")
			return
		}
		if errors.Is(err, shareservice.ErrShareExpired) {
			response.Error(c, "This share link has expired.")
			return
		}
		response.Error(c, "Failed to generate temporary resource URL")
		return
	}

	// 根据媒体类型动态生成HTML内容
	var mediaElement string
	if resource.MediaType == "video" {
		// 如果是视频，生成 <video> 标签
		mediaElement = fmt.Sprintf(`<video src="%s" controls autoplay muted loop playsinline></video>`, resource.SignedURL)
	} else {
		// 默认是图片，生成 <img> 标签
		mediaElement = fmt.Sprintf(`<img src="%s" alt="分享的内容">`, resource.SignedURL)
	}

	// 构建完整的HTML字符串
	htmlContent := fmt.Sprintf(`
		<!DOCTYPE html>
		<html lang="zh">
		<head>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1.0">
			<title>分享内容</title>
			<style>
				body { margin: 0; background: #000; display: flex; justify-content: center; align-items: center; height: 100vh; overflow: hidden; }
				img, video { max-width: 100%%; max-height: 100%%; object-fit: contain; }
			</style>
		</head>
		<body>
			%s
		</body>
		</html>
	`, mediaElement)

	// 设置正确的 Content-Type Header 并返回HTML响应
	c.Header("Content-Type", "text/html; charset=utf-8")
	c.String(http.StatusOK, htmlContent)
}

