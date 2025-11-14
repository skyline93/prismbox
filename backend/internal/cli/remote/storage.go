package remote

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

// StoragePool 存储池信息
type StoragePool struct {
	UUID                 string                 `json:"uuid"`
	Name                 string                 `json:"name"`
	Description          string                 `json:"description"`
	StorageType          string                 `json:"storage_type"`
	LocalPath            string                 `json:"local_path"`
	CloudConfig          map[string]interface{} `json:"cloud_config"`
	MaxSize              int64                  `json:"max_size"`
	CurrentSize          int64                  `json:"current_size"`
	Priority             int                    `json:"priority"`
	Enabled              bool                   `json:"enabled"`
	Status               string                 `json:"status"`
	AutoDisableThreshold float64                `json:"auto_disable_threshold"`
	LastCheckedAt        *time.Time             `json:"last_checked_at"`
	ErrorMessage         string                 `json:"error_message"`
}

// StoragePoolListRequest 列表查询参数
type StoragePoolListRequest struct {
	StorageType string
	Status      string
}

// StoragePoolRefreshRequest 缓存刷新请求
type StoragePoolRefreshRequest struct {
	Node  string `json:"node,omitempty"`
	Async bool   `json:"async"`
}

// StoragePoolReconcileRequest 对账请求
type StoragePoolReconcileRequest struct {
	PoolUUID string `json:"pool_uuid,omitempty"`
	DryRun   bool   `json:"dry_run"`
	Parallel int    `json:"parallel,omitempty"`
}

// StoragePoolUsageRequest 容量查询参数
type StoragePoolUsageRequest struct {
	PoolUUID string
}

// StoragePoolUsage 容量对比结果
type StoragePoolUsage struct {
	UUID          string  `json:"uuid"`
	DatabaseSize  int64   `json:"database_size"`
	ActualSize    int64   `json:"actual_size"`
	DriftPercent  float64 `json:"drift_percent"`
	LastCheckedAt string  `json:"last_checked_at"`
}

// StoragePoolOperationResult 通用操作响应
type StoragePoolOperationResult struct {
	Message string `json:"message"`
	TaskID  string `json:"task_id,omitempty"`
}

// ListStoragePools 查询存储池列表
func (c *Client) ListStoragePools(ctx context.Context, req StoragePoolListRequest) ([]StoragePool, error) {
	path := "/api/v1/storage/pools"
	query := url.Values{}
	if req.StorageType != "" {
		query.Set("storage_type", req.StorageType)
	}
	if req.Status != "" {
		query.Set("status", req.Status)
	}
	if encoded := query.Encode(); encoded != "" {
		path = fmt.Sprintf("%s?%s", path, encoded)
	}

	var pools []StoragePool
	if err := c.doJSON(ctx, http.MethodGet, path, nil, &pools); err != nil {
		return nil, err
	}
	return pools, nil
}

// GetStoragePool 查询单个存储池
func (c *Client) GetStoragePool(ctx context.Context, uuid string) (*StoragePool, error) {
	var pool StoragePool
	if err := c.doJSON(ctx, http.MethodGet, fmt.Sprintf("/api/v1/storage/pools/%s", uuid), nil, &pool); err != nil {
		return nil, err
	}
	return &pool, nil
}

// CreateStoragePool 新建存储池
func (c *Client) CreateStoragePool(ctx context.Context, payload map[string]interface{}) (*StoragePool, error) {
	var pool StoragePool
	if err := c.doJSON(ctx, http.MethodPost, "/api/v1/storage/pools", payload, &pool); err != nil {
		return nil, err
	}
	return &pool, nil
}

// UpdateStoragePool 更新存储池
func (c *Client) UpdateStoragePool(ctx context.Context, uuid string, payload map[string]interface{}) (*StoragePool, error) {
	var pool StoragePool
	if err := c.doJSON(ctx, http.MethodPatch, fmt.Sprintf("/api/v1/storage/pools/%s", uuid), payload, &pool); err != nil {
		return nil, err
	}
	return &pool, nil
}

// SetStoragePoolEnabled 启用/禁用存储池
func (c *Client) SetStoragePoolEnabled(ctx context.Context, uuid string, enabled bool) error {
	action := "disable"
	if enabled {
		action = "enable"
	}
	return c.doJSON(ctx, http.MethodPost, fmt.Sprintf("/api/v1/storage/pools/%s/%s", uuid, action), nil, nil)
}

// RefreshStoragePools 触发缓存刷新
func (c *Client) RefreshStoragePools(ctx context.Context, req StoragePoolRefreshRequest) (*StoragePoolOperationResult, error) {
	var result StoragePoolOperationResult
	if err := c.doJSON(ctx, http.MethodPost, "/api/v1/storage/pools/refresh", req, &result); err != nil {
		return nil, err
	}
	return &result, nil
}

// ReconcileStoragePools 触发对账
func (c *Client) ReconcileStoragePools(ctx context.Context, req StoragePoolReconcileRequest) (*StoragePoolOperationResult, error) {
	var result StoragePoolOperationResult
	if err := c.doJSON(ctx, http.MethodPost, "/api/v1/storage/pools/reconcile", req, &result); err != nil {
		return nil, err
	}
	return &result, nil
}

// GetStoragePoolUsage 获取容量对比
func (c *Client) GetStoragePoolUsage(ctx context.Context, req StoragePoolUsageRequest) ([]StoragePoolUsage, error) {
	path := "/api/v1/storage/pools/usage"
	if strings.TrimSpace(req.PoolUUID) != "" {
		path = fmt.Sprintf("%s?pool_uuid=%s", path, url.QueryEscape(req.PoolUUID))
	}
	var usage []StoragePoolUsage
	if err := c.doJSON(ctx, http.MethodGet, path, nil, &usage); err != nil {
		return nil, err
	}
	return usage, nil
}

func (c *Client) doJSON(ctx context.Context, method, path string, payload interface{}, out interface{}) error {
	var body io.Reader
	if payload != nil {
		data, err := json.Marshal(payload)
		if err != nil {
			return fmt.Errorf("序列化请求失败: %w", err)
		}
		body = bytes.NewReader(data)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.resolve(path), body)
	if err != nil {
		return fmt.Errorf("构建请求失败: %w", err)
	}
	if payload != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.authToken != "" {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.authToken))
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("请求失败: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("读取响应失败: %w", err)
	}

	if resp.StatusCode >= 400 {
		return fmt.Errorf("请求失败（HTTP %d）: %s", resp.StatusCode, bytes.TrimSpace(respBody))
	}

	var apiResp apiResponse
	if err := json.Unmarshal(respBody, &apiResp); err != nil {
		return fmt.Errorf("解析响应失败: %w", err)
	}
	if apiResp.Code != 0 {
		return fmt.Errorf("请求失败: %s", apiResp.Message)
	}

	if out != nil && len(apiResp.Data) > 0 && string(apiResp.Data) != "null" {
		if err := json.Unmarshal(apiResp.Data, out); err != nil {
			return fmt.Errorf("解析数据失败: %w", err)
		}
	}
	return nil
}
