package storage

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/album/backend/internal/api/response"
	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	storagepoolservice "github.com/album/backend/internal/service/storagepool"
	"github.com/album/backend/internal/storage/interfaces"
)

// Handler 存储池处理器
type Handler struct {
	service storagepoolservice.Service
}

// NewHandler 创建处理器
func NewHandler(service storagepoolservice.Service) *Handler {
	return &Handler{service: service}
}

// ListPools 列出存储池
func (h *Handler) ListPools(c *gin.Context) {
	filter := repository.StoragePoolFilter{
		StorageType: c.Query("storage_type"),
		Status:      c.Query("status"),
	}
	pools, err := h.service.List(c.Request.Context(), filter)
	if err != nil {
		writeError(c, http.StatusInternalServerError, err.Error())
		return
	}
	response.Success(c, "storage pools retrieved", serializePools(pools))
}

// GetPool 读取单个存储池详情
func (h *Handler) GetPool(c *gin.Context) {
	pool, err := h.service.Get(c.Request.Context(), c.Param("uuid"))
	if err != nil {
		writeError(c, http.StatusNotFound, err.Error())
		return
	}
	response.Success(c, "storage pool retrieved", serializePool(pool))
}

// CreatePool 创建存储池
func (h *Handler) CreatePool(c *gin.Context) {
	var req createPoolRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	input := req.toCreateInput()
	pool, err := h.service.Create(c.Request.Context(), input)
	if err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool created", serializePool(pool))
}

// UpdatePool 更新存储池
func (h *Handler) UpdatePool(c *gin.Context) {
	var req updatePoolRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	input, err := req.toUpdateInput()
	if err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	pool, err := h.service.Update(c.Request.Context(), c.Param("uuid"), input)
	if err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool updated", serializePool(pool))
}

// EnablePool 启用存储池
func (h *Handler) EnablePool(c *gin.Context) {
	if err := h.service.SetEnabled(c.Request.Context(), c.Param("uuid"), true); err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool enabled", nil)
}

// DisablePool 禁用存储池
func (h *Handler) DisablePool(c *gin.Context) {
	if err := h.service.SetEnabled(c.Request.Context(), c.Param("uuid"), false); err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool disabled", nil)
}

// RefreshPools 刷新缓存
func (h *Handler) RefreshPools(c *gin.Context) {
	result, err := h.service.Refresh(c.Request.Context())
	if err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool cache refreshed", result)
}

// ReconcilePools 触发对账
func (h *Handler) ReconcilePools(c *gin.Context) {
	var req reconcileRequest
	if err := c.ShouldBindJSON(&req); err != nil && err != io.EOF {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	result, err := h.service.Reconcile(c.Request.Context(), &interfaces.PoolReconcileRequest{
		PoolUUID: req.PoolUUID,
		DryRun:   req.DryRun,
		Parallel: req.Parallel,
	})
	if err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool reconcile triggered", result)
}

// GetUsage 容量对比
func (h *Handler) GetUsage(c *gin.Context) {
	rows, err := h.service.Usage(c.Request.Context(), c.Query("pool_uuid"))
	if err != nil {
		writeError(c, http.StatusInternalServerError, err.Error())
		return
	}
	resp := make([]storagePoolUsageResponse, 0, len(rows))
	for _, row := range rows {
		lastChecked := ""
		if row.LastCheckedAt != nil {
			lastChecked = row.LastCheckedAt.Format(time.RFC3339)
		}
		drift := 0.0
		if row.DatabaseSize > 0 {
			diff := float64(row.ActualSize-row.DatabaseSize) / float64(row.DatabaseSize)
			drift = diff * 100
		}
		resp = append(resp, storagePoolUsageResponse{
			UUID:          row.UUID,
			DatabaseSize:  row.DatabaseSize,
			ActualSize:    row.ActualSize,
			DriftPercent:  drift,
			LastCheckedAt: lastChecked,
		})
	}
	response.Success(c, "storage pool usage", resp)
}

func writeError(c *gin.Context, status int, msg string) {
	c.JSON(status, response.ApiResponse{
		Code:    1,
		Message: msg,
		Data:    nil,
	})
}

type createPoolRequest struct {
	Name                 string                 `json:"name" binding:"required"`
	StorageType          string                 `json:"storage_type" binding:"required"`
	LocalPath            string                 `json:"local_path"`
	CloudConfig          map[string]interface{} `json:"cloud_config"`
	MaxSize              int64                  `json:"max_size" binding:"required"`
	Priority             int                    `json:"priority"`
	Enabled              *bool                  `json:"enabled"`
	AutoDisableThreshold float64                `json:"auto_disable_threshold"`
	Description          string                 `json:"description"`
}

func (r createPoolRequest) toCreateInput() *storagepoolservice.CreateInput {
	enabled := true
	if r.Enabled != nil {
		enabled = *r.Enabled
	}
	return &storagepoolservice.CreateInput{
		Name:                 r.Name,
		StorageType:          r.StorageType,
		LocalPath:            r.LocalPath,
		CloudConfig:          r.CloudConfig,
		MaxSize:              r.MaxSize,
		Priority:             r.Priority,
		Enabled:              enabled,
		AutoDisableThreshold: r.AutoDisableThreshold,
		Description:          r.Description,
	}
}

type updatePoolRequest struct {
	Name                 *string                `json:"name"`
	LocalPath            *string                `json:"local_path"`
	CloudConfig          map[string]interface{} `json:"cloud_config"`
	MaxSize              *int64                 `json:"max_size"`
	Priority             *int                   `json:"priority"`
	Enabled              *bool                  `json:"enabled"`
	AutoDisableThreshold *float64               `json:"auto_disable_threshold"`
	Description          *string                `json:"description"`
}

func (r updatePoolRequest) toUpdateInput() (*storagepoolservice.UpdateInput, error) {
	return &storagepoolservice.UpdateInput{
		Name:                 r.Name,
		LocalPath:            r.LocalPath,
		CloudConfig:          r.CloudConfig,
		MaxSize:              r.MaxSize,
		Priority:             r.Priority,
		Enabled:              r.Enabled,
		AutoDisableThreshold: r.AutoDisableThreshold,
		Description:          r.Description,
	}, nil
}

type reconcileRequest struct {
	PoolUUID string `json:"pool_uuid"`
	DryRun   bool   `json:"dry_run"`
	Parallel int    `json:"parallel"`
}

type storagePoolResponse struct {
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
}

type storagePoolUsageResponse struct {
	UUID          string  `json:"uuid"`
	DatabaseSize  int64   `json:"database_size"`
	ActualSize    int64   `json:"actual_size"`
	DriftPercent  float64 `json:"drift_percent"`
	LastCheckedAt string  `json:"last_checked_at"`
}

func serializePools(pools []*models.StoragePool) []storagePoolResponse {
	resp := make([]storagePoolResponse, 0, len(pools))
	for _, pool := range pools {
		resp = append(resp, serializePool(pool))
	}
	return resp
}

func serializePool(pool *models.StoragePool) storagePoolResponse {
	return storagePoolResponse{
		UUID:                 pool.UUID,
		Name:                 pool.Name,
		Description:          pool.Description,
		StorageType:          pool.StorageType,
		LocalPath:            pool.LocalPath,
		CloudConfig:          decodeCloudConfig(pool.CloudConfig),
		MaxSize:              pool.MaxSize,
		CurrentSize:          pool.CurrentSize,
		Priority:             pool.Priority,
		Enabled:              pool.Enabled,
		Status:               pool.Status,
		AutoDisableThreshold: pool.AutoDisableThreshold,
		LastCheckedAt:        pool.LastCheckedAt,
	}
}

func decodeCloudConfig(data []byte) map[string]interface{} {
	if len(data) == 0 {
		return nil
	}
	var out map[string]interface{}
	if err := json.Unmarshal(data, &out); err != nil {
		return map[string]interface{}{
			"raw": string(data),
			"err": fmt.Sprintf("decode failed: %v", err),
		}
	}
	return out
}
