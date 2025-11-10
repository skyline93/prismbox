package auth

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	tokenTypeAccess  = "access"
	tokenTypeRefresh = "refresh"
)

// GenerateAccessToken 生成访问令牌。
func GenerateAccessToken(userID uint, secretKey []byte, ttl time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"sub":  userID,
		"type": tokenTypeAccess,
		"exp":  time.Now().Add(ttl).Unix(),
		"iat":  time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secretKey)
}

// GenerateRefreshToken 生成刷新令牌。
func GenerateRefreshToken(userID uint, secretKey []byte, ttl time.Duration) (string, error) {
	claims := jwt.MapClaims{
		"sub":  userID,
		"type": tokenTypeRefresh,
		"exp":  time.Now().Add(ttl).Unix(),
		"iat":  time.Now().Unix(),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(secretKey)
}

// ValidateToken 验证访问令牌并返回用户 ID。
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
		if tokenType, ok := claims["type"].(string); !ok || tokenType != tokenTypeAccess {
			return 0, fmt.Errorf("invalid token type")
		}

		userIDFloat, ok := claims["sub"].(float64)
		if !ok {
			return 0, fmt.Errorf("invalid token claims")
		}
		return uint(userIDFloat), nil
	}

	return 0, fmt.Errorf("invalid token")
}
