package middleware

import (
	"strings"

	"github.com/album/backend/internal/api/response"
	albumencryption "github.com/album/backend/internal/service/album_encryption"
	"github.com/gin-gonic/gin"
)

const albumIDKey = "albumID"

// AlbumSessionMiddleware 相册会话令牌验证中间件
// 验证 X-Session-Token 头中的会话令牌
func AlbumSessionMiddleware(albumEncryptionService albumencryption.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		if albumEncryptionService == nil {
			response.ErrorAuth(c, "Album encryption service unavailable")
			c.Abort()
			return
		}

		// 获取用户ID（必须已通过 AuthMiddleware）
		userID := MustGetUserID(c)
		if userID == 0 {
			response.ErrorAuth(c, "User authentication required")
			c.Abort()
			return
		}

		// 获取相册ID
		albumID := c.Param("albumId")
		if albumID == "" {
			response.Error(c, "Album ID is required")
			c.Abort()
			return
		}

		// 获取会话令牌
		sessionToken := c.GetHeader("X-Session-Token")
		if sessionToken == "" {
			// 也支持小写格式
			sessionToken = c.GetHeader("x-session-token")
		}
		if sessionToken == "" {
			response.ErrorAuth(c, "Session token is required")
			c.Abort()
			return
		}

		// 清理令牌（去除可能的空格）
		sessionToken = strings.TrimSpace(sessionToken)

		// 验证会话令牌
		ctx := c.Request.Context()
		if err := albumEncryptionService.ValidateSessionToken(ctx, albumID, userID, sessionToken); err != nil {
			response.ErrorWithStatus(c, 403, "Invalid or expired session token")
			c.Abort()
			return
		}

		// 将相册ID存储到上下文中，供后续处理使用
		c.Set(albumIDKey, albumID)
		c.Next()
	}
}

// MustGetAlbumID 从上下文获取相册ID
func MustGetAlbumID(c *gin.Context) string {
	if v, exists := c.Get(albumIDKey); exists {
		if id, ok := v.(string); ok {
			return id
		}
	}
	c.AbortWithStatus(400)
	return ""
}

