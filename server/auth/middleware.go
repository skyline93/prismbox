// auth/middleware.go
package auth

import (
	"server/core"
	"server/urlsigner"
	"strconv"
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

		c.Set("userID", uint(userID))
		c.Next()
	}
}

func FlexibleAuthMiddleware(secretKey []byte, signer *urlsigner.Signer) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 1. 尝试JWT认证 (保持不变)
		authHeader := c.GetHeader("Authorization")
		if authHeader != "" {
			parts := strings.Split(authHeader, " ")
			if len(parts) == 2 && parts[0] == "Bearer" {
				// 假设 ValidateToken 返回 (userID, error)
				userID, err := ValidateToken(parts[1], secretKey)
				if err == nil {
					c.Set("userID", uint(userID))
					c.Next()
					return
				}
			}
		}

		// 2. 如果JWT认证失败，尝试签名URL认证 (进行修改)
		// 注意：c.Request.URL.String() 包含路径和查询参数，正是我们需要的
		fullURL := c.Request.URL.String()

		// 使用我们新的、更灵活的 Validate 函数
		if userID, ok := signer.Validate(fullURL); ok {
			// 签名URL有效！

			// 关键：检查返回的 userID 是否非空
			if userID != "" {
				// 这是一个私有链接，我们将 userID 存入上下文
				if uid, err := strconv.ParseUint(userID, 10, 64); err == nil {
					c.Set("userID", uint(uid))
				} else {
					core.ErrorAuth(c, "Invalid userID in signed URL")
					c.Abort()
					return
				}
			}
			// 如果 userID 为空，说明这是一个有效的公开链接。
			// 我们不设置 userID，但仍然允许请求通过。

			c.Next() // 继续处理请求
			return
		}

		// 3. 所有认证方式都失败
		core.ErrorAuth(c, "Authentication required")
		c.Abort()
	}
}
