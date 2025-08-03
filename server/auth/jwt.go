package auth

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

type TypeToken string

const (
	TypeTokenAccess  = "access"
	TypeTokenRefresh = "refresh"
)

// GenerateAccessToken 为指定用户ID生成一个新的短寿命访问令牌
func GenerateAccessToken(userID uint, secretKey []byte, AccessTokenExpiresIn time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"sub":  userID,
		"type": TypeTokenAccess,
		"exp":  time.Now().Add(AccessTokenExpiresIn).Unix(),
		"iat":  time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secretKey)
}

// GenerateRefreshToken 为指定用户ID生成一个新的长寿命刷新令牌
func GenerateRefreshToken(userID uint, secretKey []byte, refreshTokenExpiresIn time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"sub":  userID,
		"type": TypeTokenRefresh,
		"exp":  time.Now().Add(refreshTokenExpiresIn).Unix(),
		"iat":  time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secretKey)
}

// ValidateToken 解析并验证JWT Token，如果有效则返回用户ID
// 这个函数现在主要由中间件使用，用于验证访问令牌
func ValidateToken(tokenString string, secretKey []byte) (uint, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return secretKey, nil
	})

	if err != nil {
		return 0, err
	}

	if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
		// 确保这是个访问令牌
		if tokenType, ok := claims["type"].(string); !ok || tokenType != TypeTokenAccess {
			return 0, fmt.Errorf("invalid token type: not an access token")
		}

		userIDFloat, ok := claims["sub"].(float64)
		if !ok {
			return 0, fmt.Errorf("invalid token claims: 'sub' is not a valid user ID")
		}
		return uint(userIDFloat), nil
	}

	return 0, fmt.Errorf("invalid token")
}
