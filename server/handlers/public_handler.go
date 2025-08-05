package handlers

import (
	"fmt"
	"net/http"
	"server/constant"
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

	// 1. 获取分享记录及其关联的照片
	var share models.Share
	// 使用 Preload("Media") 一次性加载关联的照片信息
	err := h.DB.Preload("Media").Where("share_token = ?", shareToken).First(&share).Error
	if err != nil {
		core.Error(c, "Share link not found")
		return
	}

	// 2. 校验分享链接的有效性
	if share.IsRevoked {
		core.Error(c, "This share link has been revoked.")
		return
	}
	if time.Now().After(share.ExpiresAt) {
		core.Error(c, "This share link has expired.")
		return
	}

	// 3. 为资源生成一个临时的、不记名的签名URL
	// 决定是分享预览图还是原始图，通常分享预览图更快更合适
	resourcePath := h.URLBuilder.BuildMediaPreviewPath(share.Media.UUID)

	//【修复】为公开链接生成签名时，userID应传入空字符串 ""，而不是整数 0
	signedURL, err := h.URLSigner.Generate(resourcePath, 0, h.SignedURLLoadTTL)
	if err != nil {
		core.Error(c, "Failed to generate temporary resource URL")
		return
	}

	// 4. 【最佳实践优化】根据媒体类型动态生成HTML内容
	var mediaElement string
	if share.Media.ItemType == constant.TypeVideo {
		// 如果是视频，生成 <video> 标签
		mediaElement = fmt.Sprintf(`<video src="%s" controls autoplay muted loop playsinline></video>`, signedURL)
	} else {
		// 默认是图片，生成 <img> 标签
		mediaElement = fmt.Sprintf(`<img src="%s" alt="分享的内容">`, signedURL)
	}

	// 5. 【修复】使用 fmt.Sprintf 预先、安全地构建完整的HTML字符串
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
	`, mediaElement) // 将预先格式化好的 mediaElement 放入最终的HTML模板

	// 6. 【修复】设置正确的 Content-Type Header 并返回HTML响应
	c.Header("Content-Type", "text/html; charset=utf-8") // 修正了 utf-h.8 -> utf-8
	c.String(http.StatusOK, htmlContent)
}
