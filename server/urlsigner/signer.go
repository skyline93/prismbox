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

// Signer 负责生成和验证签名URL
type Signer struct {
	secretKey []byte
}

// NewSigner 创建一个新的签名器实例
func NewSigner(secret []byte) *Signer {
	return &Signer{secretKey: secret}
}

// Generate 生成一个带签名的URL
// path: 原始的受保护路径, e.g., "/api/v1/photos/uuid-123/download/preview"
// duration: 链接的有效时长
func (s *Signer) Generate(path string, duration time.Duration) (string, error) {
	expires := time.Now().Add(duration).Unix()

	// 准备要签名的数据
	dataToSign := fmt.Sprintf("%s:%d", path, expires)

	// 使用HMAC-SHA256算法生成签名
	h := hmac.New(sha256.New, s.secretKey)
	_, err := h.Write([]byte(dataToSign))
	if err != nil {
		return "", err
	}
	signature := hex.EncodeToString(h.Sum(nil))

	// 构建最终的URL
	queryParams := url.Values{}
	queryParams.Set("expires", strconv.FormatInt(expires, 10))
	queryParams.Set("signature", signature)

	return fmt.Sprintf("%s?%s", path, queryParams.Encode()), nil
}

// Validate 验证一个签名URL是否有效
func (s *Signer) Validate(fullURL string) bool {
	parsedURL, err := url.Parse(fullURL)
	if err != nil {
		return false
	}

	queryParams := parsedURL.Query()
	expiresStr := queryParams.Get("expires")
	providedSignature := queryParams.Get("signature")

	if expiresStr == "" || providedSignature == "" {
		return false
	}

	expires, err := strconv.ParseInt(expiresStr, 10, 64)
	if err != nil {
		return false
	}

	// 1. 检查是否过期
	if time.Now().Unix() > expires {
		return false
	}

	// 2. 重新计算签名并比较
	path := parsedURL.Path
	dataToSign := fmt.Sprintf("%s:%d", path, expires)

	h := hmac.New(sha256.New, s.secretKey)
	h.Write([]byte(dataToSign))
	expectedSignature := hex.EncodeToString(h.Sum(nil))

	// 使用 hmac.Equal 进行固定时间的比较，防止时序攻击
	return hmac.Equal([]byte(providedSignature), []byte(expectedSignature))
}
