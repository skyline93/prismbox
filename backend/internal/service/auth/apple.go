package auth

import "github.com/golang-jwt/jwt/v5"

// AppleClaims 定义 Apple Identity Token 的声明。
type AppleClaims struct {
	jwt.RegisteredClaims
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	IsPrivate     bool   `json:"is_private_email"`
}
