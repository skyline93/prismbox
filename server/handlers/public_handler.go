package handlers

import (
	"net/http"
	"server/core"
	"server/models"
	"server/routing"
	"server/urlsigner"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type PublicHandler struct {
	DB               *gorm.DB
	URLSigner        *urlsigner.Signer
	URLBuilder       *routing.URLBuilder
	SignedURLLoadTTL time.Duration
}

// GetSharedResource godoc
// @Summary      访问分享的资源
// @Description  通过一个公开的分享令牌访问媒体资源。服务器会返回一个包含临时签名URL的HTML页面。
// @Tags         Public
// @Produce      html
// @Param        share_token path string true "分享令牌"
// @Success      200 {string} html "包含媒体资源的HTML页面"
// @Failure      404 {object} core.ApiResponse "分享链接不存在"
// @Failure      410 {object} core.ApiResponse "分享链接已过期或被撤销"
// @Router       /s/{share_token} [get]
func (h *PublicHandler) GetSharedResource(c *gin.Context) {
	shareToken := c.Param("share_token")

	var share models.Share
	err := h.DB.Preload("Photo").Where("share_token = ?", shareToken).First(&share).Error
	if err != nil {
		core.Error(c, "Share link not found")
		return
	}

	if share.IsRevoked {
		core.Error(c, "This share link has been revoked.")
		return
	}
	if time.Now().After(share.ExpiresAt) {
		core.Error(c, "This share link has expired.")
		return
	}

	resourcePath := h.URLBuilder.BuildPhotoPreviewPath(share.Photo.UUID)
	signedURL, err := h.URLSigner.Generate(resourcePath, h.SignedURLLoadTTL)
	if err != nil {
		core.Error(c, "Failed to generate temporary resource URL")
		return
	}

	// 4. 返回一个HTML页面，由浏览器来加载这个临时的、安全的URL
	c.Header("Content-Type", "text/html; charset=utf-h.8")
	c.String(http.StatusOK, `
		<!DOCTYPE html>
		<html lang="zh">
		<head>
			<meta charset="UTF-8">
			<meta name="viewport" content="width=device-width, initial-scale=1.0">
			<title>分享内容</title>
			<style>
				body { margin: 0; background: #000; display: flex; justify-content: center; align-items: center; height: 100vh; }
				img, video { max-width: 100%; max-height: 100%; object-fit: contain; }
			</style>
		</head>
		<body>
			<img src="%s" alt="分享的图片">
		</body>
		</html>
	`, signedURL)
}
