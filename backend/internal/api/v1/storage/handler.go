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

// ListPools lists storage pools.
// @Summary      List storage pools
// @Description  Lists all storage pools with optional filters by type and status (authentication required)
// @Tags         Storage
// @Produce      json
// @Security     BearerAuth
// @Param        storage_type query string false "Filter by storage type"
// @Param        status query string false "Filter by status"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Failure      500 {object} response.ApiResponse "Internal server error"
// @Router       /storage/pools [get]
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

// GetPool returns one storage pool by UUID.
// @Summary      Get storage pool
// @Description  Returns details for a specific storage pool (authentication required)
// @Tags         Storage
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Storage pool UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      404 {object} response.ApiResponse "Storage pool not found"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /storage/pools/{uuid} [get]
func (h *Handler) GetPool(c *gin.Context) {
	pool, err := h.service.Get(c.Request.Context(), c.Param("uuid"))
	if err != nil {
		writeError(c, http.StatusNotFound, err.Error())
		return
	}
	response.Success(c, "storage pool retrieved", serializePool(pool))
}

// CreatePool creates a storage pool.
// @Summary      Create storage pool
// @Description  Creates a new storage pool (authentication required)
// @Tags         Storage
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body createPoolRequest true "Storage pool payload"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /storage/pools [post]
func (h *Handler) CreatePool(c *gin.Context) {
	var req createPoolRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	input := req.toCreateInput()
	result, err := h.service.Create(c.Request.Context(), input)
	if err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}

	// Build response with pool and refresh info
	responseData := createPoolResponse{
		Pool: serializePool(result.Pool),
	}
	if result.RefreshInfo != nil {
		responseData.RefreshInfo = &refreshInfoResponse{
			Success: result.RefreshInfo.Success,
			Message: result.RefreshInfo.Message,
			Error:   result.RefreshInfo.Error,
			TaskID:  result.RefreshInfo.TaskID,
		}
	}

	response.Success(c, "storage pool created", responseData)
}

// UpdatePool updates a storage pool.
// @Summary      Update storage pool
// @Description  Updates storage pool configuration (authentication required)
// @Tags         Storage
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Storage pool UUID"
// @Param        input body updatePoolRequest true "Update payload"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /storage/pools/{uuid} [patch]
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

// EnablePool enables a storage pool.
// @Summary      Enable storage pool
// @Description  Enables the specified storage pool (authentication required)
// @Tags         Storage
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Storage pool UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Operation failed"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /storage/pools/{uuid}/enable [post]
func (h *Handler) EnablePool(c *gin.Context) {
	if err := h.service.SetEnabled(c.Request.Context(), c.Param("uuid"), true); err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool enabled", nil)
}

// DisablePool disables a storage pool.
// @Summary      Disable storage pool
// @Description  Disables the specified storage pool (authentication required)
// @Tags         Storage
// @Produce      json
// @Security     BearerAuth
// @Param        uuid path string true "Storage pool UUID"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Operation failed"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /storage/pools/{uuid}/disable [post]
func (h *Handler) DisablePool(c *gin.Context) {
	if err := h.service.SetEnabled(c.Request.Context(), c.Param("uuid"), false); err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool disabled", nil)
}

// RefreshPools refreshes pool metadata cache.
// @Summary      Refresh storage pool cache
// @Description  Refreshes cached information for all storage pools (authentication required)
// @Tags         Storage
// @Produce      json
// @Security     BearerAuth
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Operation failed"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /storage/pools/refresh [post]
func (h *Handler) RefreshPools(c *gin.Context) {
	result, err := h.service.Refresh(c.Request.Context())
	if err != nil {
		writeError(c, http.StatusBadRequest, err.Error())
		return
	}
	response.Success(c, "storage pool cache refreshed", result)
}

// ReconcilePools triggers reconciliation between DB and storage.
// @Summary      Reconcile storage pools
// @Description  Triggers reconciliation to verify database records against actual storage (authentication required)
// @Tags         Storage
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        input body reconcileRequest false "Reconciliation options"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      400 {object} response.ApiResponse "Operation failed"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /storage/pools/reconcile [post]
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

// GetUsage returns recorded vs actual usage per pool.
// @Summary      Get storage pool usage
// @Description  Returns usage comparing database size to actual storage (authentication required)
// @Tags         Storage
// @Produce      json
// @Security     BearerAuth
// @Param        pool_uuid query string false "Optional storage pool UUID; omit for all pools"
// @Success      200 {object} response.ApiResponse "OK"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Failure      500 {object} response.ApiResponse "Internal server error"
// @Router       /storage/pools/usage [get]
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
	Location             string                 `json:"location" binding:"required"` // Pool location URI (required), e.g. local:///absolute/path; type derived from scheme
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
		Location:             r.Location,
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
	Location             *string                `json:"location"`
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
		Location:             r.Location,
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
	Location             string                 `json:"location"` // Pool location URI, e.g. local:///absolute/path
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

type createPoolResponse struct {
	Pool        storagePoolResponse  `json:"pool"`
	RefreshInfo *refreshInfoResponse `json:"refresh_info,omitempty"`
}

type refreshInfoResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message,omitempty"`
	Error   string `json:"error,omitempty"`
	TaskID  string `json:"task_id,omitempty"`
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
		Location:             pool.Location,
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
