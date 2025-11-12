package remote

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net"
	"net/http"
	"net/url"
	"path"
	"strings"
	"time"
)

// Config 远程客户端配置
type Config struct {
	BaseURL    string
	SocketPath string
	AuthToken  string
	Timeout    time.Duration
}

// Client CLI 到后端的远程调用客户端
type Client struct {
	baseURL    *url.URL
	httpClient *http.Client
	authToken  string
}

// UploadMediaInput 上传媒体请求
type UploadMediaInput struct {
	Hash             string
	ItemType         string
	OriginalFilename string
	CloudUUID        string
	MediaTakenAt     *time.Time
	FileSize         int64
	FileName         string
	File             io.Reader
}

// UploadMediaResponse 上传媒体响应
type UploadMediaResponse struct {
	Message string
	Media   *Media
}

// Media 远程媒体信息
type Media struct {
	UUID             string `json:"uuid"`
	UserID           uint   `json:"user_id"`
	Hash             string `json:"hash"`
	ItemType         string `json:"item_type"`
	OriginalFilename string `json:"original_filename"`
	Filename         string `json:"filename"`
	FileSize         int64  `json:"file_size"`
	MimeType         string `json:"mime_type"`
	ProcessingStatus string `json:"processing_status"`
	LocalPath        string `json:"local_path"`
	BackupStatus     string `json:"backup_status"`
	CreatedAt        string `json:"created_at"`
}

type apiResponse struct {
	Code    int             `json:"code"`
	Message string          `json:"message"`
	Data    json.RawMessage `json:"data"`
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type loginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

// NewClient 创建远程客户端
func NewClient(cfg Config) (*Client, error) {
	if cfg.Timeout <= 0 {
		cfg.Timeout = 2 * time.Minute
	}

	baseURL := cfg.BaseURL
	if baseURL == "" {
		baseURL = "http://unix"
	}

	parsed, err := url.Parse(baseURL)
	if err != nil {
		return nil, fmt.Errorf("解析 base-url 失败: %w", err)
	}

	transport := &http.Transport{
		Proxy: http.ProxyFromEnvironment,
	}

	if cfg.SocketPath != "" {
		transport.DialContext = func(ctx context.Context, network, addr string) (net.Conn, error) {
			return (&net.Dialer{}).DialContext(ctx, "unix", cfg.SocketPath)
		}
		if parsed.Scheme == "http" && parsed.Host == "" {
			parsed.Host = "unix"
		}
	}

	client := &http.Client{
		Timeout:   cfg.Timeout,
		Transport: transport,
	}

	return &Client{
		baseURL:    parsed,
		httpClient: client,
		authToken:  cfg.AuthToken,
	}, nil
}

// UploadMedia 上传媒体文件
func (c *Client) UploadMedia(ctx context.Context, input *UploadMediaInput) (*UploadMediaResponse, error) {
	if input == nil {
		return nil, fmt.Errorf("上传请求不能为空")
	}

	pr, pw := io.Pipe()
	writer := multipart.NewWriter(pw)

	go func() {
		defer pw.Close()
		defer writer.Close()

		if err := writer.WriteField("hash", input.Hash); err != nil {
			_ = pw.CloseWithError(err)
			return
		}
		if err := writer.WriteField("item_type", input.ItemType); err != nil {
			_ = pw.CloseWithError(err)
			return
		}
		if err := writer.WriteField("original_filename", input.OriginalFilename); err != nil {
			_ = pw.CloseWithError(err)
			return
		}
		if err := writer.WriteField("cloud_uuid", input.CloudUUID); err != nil {
			_ = pw.CloseWithError(err)
			return
		}
		if input.MediaTakenAt != nil {
			if err := writer.WriteField("media_taken_at", input.MediaTakenAt.Format(time.RFC3339)); err != nil {
				_ = pw.CloseWithError(err)
				return
			}
		}

		part, err := writer.CreateFormFile("file", input.FileName)
		if err != nil {
			_ = pw.CloseWithError(err)
			return
		}
		if input.File != nil {
			if _, err := io.Copy(part, input.File); err != nil {
				_ = pw.CloseWithError(err)
				return
			}
		}
	}()

	requestURL := c.resolve("/api/v1/media/upload-stream")
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, requestURL, pr)
	if err != nil {
		return nil, fmt.Errorf("构建请求失败: %w", err)
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())
	if c.authToken != "" {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.authToken))
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("请求上传接口失败: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("读取响应失败: %w", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("上传失败（HTTP %d）: %s", resp.StatusCode, bytes.TrimSpace(body))
	}

	var apiResp apiResponse
	if err := json.Unmarshal(body, &apiResp); err != nil {
		return nil, fmt.Errorf("解析响应失败: %w", err)
	}
	if apiResp.Code != 0 {
		return nil, fmt.Errorf("上传失败: %s", apiResp.Message)
	}

	var media Media
	if len(apiResp.Data) > 0 && string(apiResp.Data) != "null" {
		if err := json.Unmarshal(apiResp.Data, &media); err != nil {
			return nil, fmt.Errorf("解析媒体数据失败: %w", err)
		}
	}

	return &UploadMediaResponse{
		Message: apiResp.Message,
		Media:   &media,
	}, nil
}

func (c *Client) resolve(p string) string {
	if !strings.HasPrefix(p, "/") {
		p = "/" + p
	}
	rel := &url.URL{Path: path.Join(c.baseURL.Path, p)}
	return c.baseURL.ResolveReference(rel).String()
}

// LoginWithPassword 使用邮箱和密码登录以获取访问令牌。
func (c *Client) LoginWithPassword(ctx context.Context, email, password string) error {
	payload, err := json.Marshal(loginRequest{
		Email:    email,
		Password: password,
	})
	if err != nil {
		return fmt.Errorf("构建登录请求失败: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.resolve("/api/v1/auth/login"), bytes.NewReader(payload))
	if err != nil {
		return fmt.Errorf("构建登录请求失败: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("调用登录接口失败: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取登录响应失败: %w", err)
	}

	if resp.StatusCode >= 400 {
		return fmt.Errorf("登录失败（HTTP %d）: %s", resp.StatusCode, bytes.TrimSpace(body))
	}

	var apiResp apiResponse
	if err := json.Unmarshal(body, &apiResp); err != nil {
		return fmt.Errorf("解析登录响应失败: %w", err)
	}
	if apiResp.Code != 0 {
		return fmt.Errorf("登录失败: %s", apiResp.Message)
	}

	var login loginResponse
	if len(apiResp.Data) > 0 && string(apiResp.Data) != "null" {
		if err := json.Unmarshal(apiResp.Data, &login); err != nil {
			return fmt.Errorf("解析登录数据失败: %w", err)
		}
	}

	if login.AccessToken == "" {
		return fmt.Errorf("登录响应未返回访问令牌")
	}

	c.authToken = login.AccessToken
	return nil
}

// DownloadOriginal 下载原始文件
func (c *Client) DownloadOriginal(ctx context.Context, uuid string, output io.Writer) error {
	return c.downloadMedia(ctx, uuid, "original", output)
}

// DownloadPreview 下载预览文件
func (c *Client) DownloadPreview(ctx context.Context, uuid string, output io.Writer) error {
	return c.downloadMedia(ctx, uuid, "preview", output)
}

// DownloadThumbnail 下载缩略图
func (c *Client) DownloadThumbnail(ctx context.Context, uuid string, output io.Writer) error {
	return c.downloadMedia(ctx, uuid, "thumbnail", output)
}

// downloadMedia 通用的下载方法
func (c *Client) downloadMedia(ctx context.Context, uuid, downloadType string, output io.Writer) error {
	if uuid == "" {
		return fmt.Errorf("媒体 UUID 不能为空")
	}
	if output == nil {
		return fmt.Errorf("输出目标不能为空")
	}

	requestURL := c.resolve(fmt.Sprintf("/api/v1/media/%s/download/%s", uuid, downloadType))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, requestURL, nil)
	if err != nil {
		return fmt.Errorf("构建请求失败: %w", err)
	}

	if c.authToken != "" {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.authToken))
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("请求下载接口失败: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		body, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("下载失败（HTTP %d）: %s", resp.StatusCode, bytes.TrimSpace(body))
	}

	// 检查 Content-Type 是否为 JSON（表示错误响应）
	contentType := resp.Header.Get("Content-Type")
	if strings.HasPrefix(contentType, "application/json") {
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			return fmt.Errorf("读取错误响应失败: %w", err)
		}
		var apiResp apiResponse
		if err := json.Unmarshal(body, &apiResp); err == nil && apiResp.Code != 0 {
			return fmt.Errorf("下载失败: %s", apiResp.Message)
		}
		return fmt.Errorf("下载失败: %s", bytes.TrimSpace(body))
	}

	// 将文件内容写入输出
	if _, err := io.Copy(output, resp.Body); err != nil {
		return fmt.Errorf("写入文件失败: %w", err)
	}

	return nil
}
