package urlsigner

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"net/url"
	"strconv"
	"time"
)

// Signer 用于生成和验证签名 URL。
type Signer struct {
	secretKey []byte
}

// NewSigner 创建新的签名器。
func NewSigner(secret []byte) *Signer {
	return &Signer{secretKey: secret}
}

// Generate 生成签名 URL。如果 userID 为 0，则视为公开链接。
func (s *Signer) Generate(rawURL string, userID uint, duration time.Duration) (string, error) {
	parsedURL, err := url.Parse(rawURL)
	if err != nil {
		return "", fmt.Errorf("parse url: %w", err)
	}

	expires := time.Now().Add(duration).Unix()
	queryParams := parsedURL.Query()
	queryParams.Set("expires", strconv.FormatInt(expires, 10))

	if userID != 0 {
		queryParams.Set("uid", fmt.Sprint(userID))
	}

	dataToSign := fmt.Sprintf("%s\n%s", parsedURL.Path, queryParams.Encode())

	signature := s.calculateSignature(dataToSign)
	queryParams.Set("signature", signature)

	parsedURL.RawQuery = queryParams.Encode()
	return parsedURL.String(), nil
}

// Validate 验证签名 URL，返回用户 ID（公开链接时返回空字符串）及验证结果。
func (s *Signer) Validate(fullURL string) (string, bool) {
	parsedURL, err := url.Parse(fullURL)
	if err != nil {
		return "", false
	}

	queryParams := parsedURL.Query()
	providedSignature := queryParams.Get("signature")
	expiresStr := queryParams.Get("expires")

	if providedSignature == "" || expiresStr == "" {
		return "", false
	}

	userID := queryParams.Get("uid")

	expires, err := strconv.ParseInt(expiresStr, 10, 64)
	if err != nil {
		return "", false
	}

	if time.Now().Unix() > expires {
		return "", false
	}

	queryParams.Del("signature")

	dataToSign := fmt.Sprintf("%s\n%s", parsedURL.Path, queryParams.Encode())
	expectedSignature := s.calculateSignature(dataToSign)

	if hmac.Equal([]byte(providedSignature), []byte(expectedSignature)) {
		return userID, true
	}

	return "", false
}

func (s *Signer) calculateSignature(data string) string {
	h := hmac.New(sha256.New, s.secretKey)
	h.Write([]byte(data))
	return hex.EncodeToString(h.Sum(nil))
}
