package middleware

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/album/backend/internal/api/response"
	authservice "github.com/album/backend/internal/service/auth"
	"github.com/album/backend/internal/urlsigner"
	"github.com/gin-gonic/gin"
)

const userIDKey = "userID"

// AuthMiddleware 标准 JWT 认证中间件。
func AuthMiddleware(authService authservice.Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		if authService == nil {
			response.ErrorAuth(c, "Authentication service unavailable")
			c.Abort()
			return
		}

		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			response.ErrorAuth(c, "Authorization header is required")
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			response.ErrorAuth(c, "Authorization header format must be Bearer {token}")
			c.Abort()
			return
		}

		userID, err := authService.ValidateAccessToken(parts[1])
		if err != nil {
			response.ErrorAuth(c, "Invalid or expired token")
			c.Abort()
			return
		}

		c.Set(userIDKey, userID)
		c.Next()
	}
}

// FlexibleAuthMiddleware 支持 JWT 或签名 URL 的认证。
func FlexibleAuthMiddleware(authService authservice.Service, signer *urlsigner.Signer) gin.HandlerFunc {
	return func(c *gin.Context) {
		if authService != nil {
			authHeader := c.GetHeader("Authorization")
			if authHeader != "" {
				parts := strings.Split(authHeader, " ")
				if len(parts) == 2 && parts[0] == "Bearer" {
					if userID, err := authService.ValidateAccessToken(parts[1]); err == nil {
						c.Set(userIDKey, userID)
						c.Next()
						return
					}
				}
			}
		}

		if signer != nil {
			if userIDStr, ok := signer.Validate(c.Request.URL.String()); ok {
				if userIDStr != "" {
					uid, err := strconv.ParseUint(userIDStr, 10, 64)
					if err != nil {
						response.ErrorAuth(c, "Invalid userID in signed URL")
						c.Abort()
						return
					}
					c.Set(userIDKey, uint(uid))
				}
				c.Next()
				return
			}
		}

		response.ErrorAuth(c, "Authentication required")
		c.Abort()
	}
}

// MustGetUserID 从上下文获取用户ID。
func MustGetUserID(c *gin.Context) uint {
	if v, exists := c.Get(userIDKey); exists {
		if id, ok := v.(uint); ok {
			return id
		}
	}
	c.AbortWithStatus(http.StatusUnauthorized)
	return 0
}
