// auth/jwt.go
package auth

import (
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// GenerateJWT 为指定用户ID生成一个新的JWT Token
func GenerateJWT(userID uint, secretKey []byte) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": userID,
		"exp": time.Now().Add(time.Hour * 24 * 7).Unix(),
		"iat": time.Now().Unix(),
	})

	return token.SignedString(secretKey)
}

// ValidateToken 解析并验证JWT Token，如果有效则返回用户ID
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
		userIDFloat, ok := claims["sub"].(float64)
		if !ok {
			return 0, fmt.Errorf("invalid token claims: 'sub' is not a valid user ID")
		}
		return uint(userIDFloat), nil
	}

	return 0, fmt.Errorf("invalid token")
}
