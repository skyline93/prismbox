// auth/middleware.go
package auth

import (
	"server/core"
	"server/urlsigner"
	"strings"

	"github.com/gin-gonic/gin"
)

func Middleware(secretKey []byte) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			core.ErrorAuth(c, "Authorization header is required")
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			core.ErrorAuth(c, "Authorization header format must be Bearer {token}")
			c.Abort()
			return
		}

		tokenString := parts[1]
		userID, err := ValidateToken(tokenString, secretKey)
		if err != nil {
			core.ErrorAuth(c, "Invalid or expired token")
			c.Abort()
			return
		}

		c.Set("userID", userID)
		c.Next()
	}
}

func FlexibleAuthMiddleware(secretKey []byte, signer *urlsigner.Signer) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. 尝试JWT认证
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				userID, err := ValidateToken(parts[1], secretKey)
				if err == nil {
					c.Set("userID", userID)
					c.Next()
					return
				}
			}
		}

		// 2. 如果JWT认证失败，尝试签名URL认证
		fullURL := c.Request.URL.String()
		if signer.Validate(fullURL) {
			// 签名URL有效，允许访问，但我们不知道具体用户ID
			// 如果需要，可以在签名中包含用户ID
			c.Next()
			return
		}

		// 3. 所有认证方式都失败
		core.ErrorAuth(c, "Authentication required")
		c.Abort()
	}
}
