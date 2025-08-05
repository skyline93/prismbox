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

type Signer struct {
	secretKey []byte
}

func NewSigner(secret []byte) *Signer {
	return &Signer{secretKey: secret}
}

// Generate 生成签名URL。如果 userID 为空字符串，则生成一个公开链接。
func (s *Signer) Generate(rawURL string, userID uint, duration time.Duration) (string, error) {

	parsedURL, err := url.Parse(rawURL)
	if err != nil {
		return "", fmt.Errorf("无法解析原始URL: %w", err)
	}

	expires := time.Now().Add(duration).Unix()
	queryParams := parsedURL.Query()
	queryParams.Set("expires", strconv.FormatInt(expires, 10))

	// 关键改动：只有当 userID 非空时，才将其添加到查询参数中
	if userID != 0 {
		queryParams.Set("uid", fmt.Sprint(userID))
	}

	// 签名逻辑保持不变，它会自动处理 uid 是否存在的情况
	// url.Values.Encode() 会对所有存在的参数（包括可能存在的uid）进行排序和编码
	dataToSign := fmt.Sprintf("%s\n%s", parsedURL.Path, queryParams.Encode())

	signature := s.calculateSignature(dataToSign)
	queryParams.Set("signature", signature)

	parsedURL.RawQuery = queryParams.Encode()
	return parsedURL.String(), nil
}

// Validate 验证URL，并在成功时返回 userID（如果存在）
// 对于公开链接，返回的 userID 会是空字符串 ""
// 返回值: (userID string, ok bool)
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

	// 如果uid参数不存在，queryParams.Get("uid") 会安全地返回空字符串 ""
	userID := queryParams.Get("uid")

	expires, err := strconv.ParseInt(expiresStr, 10, 64)
	if err != nil {
		return "", false
	}

	if time.Now().Unix() > expires {
		return "", false
	}

	queryParams.Del("signature")

	// 重建待签名数据的逻辑与 Generate 完全一致，这至关重要
	dataToSign := fmt.Sprintf("%s\n%s", parsedURL.Path, queryParams.Encode())

	expectedSignature := s.calculateSignature(dataToSign)

	if hmac.Equal([]byte(providedSignature), []byte(expectedSignature)) {
		// 验证成功，返回从URL中提取的用户ID（可能为空）
		return userID, true
	}

	return "", false
}

func (s *Signer) calculateSignature(data string) string {
	h := hmac.New(sha256.New, s.secretKey)
	h.Write([]byte(data))
	return hex.EncodeToString(h.Sum(nil))
}
