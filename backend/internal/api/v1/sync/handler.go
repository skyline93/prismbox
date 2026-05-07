package sync

import (
	"net/http"

	"github.com/album/backend/internal/api/dto"
	"github.com/album/backend/internal/api/middleware"
	apiresponse "github.com/album/backend/internal/api/response"
	appctx "github.com/album/backend/internal/app"
	syncservice "github.com/album/backend/internal/service/sync"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
)

// Handler 同步处理器
type Handler struct {
	syncService syncservice.Service
	app         *appctx.App
	log         logger.Logger
}

// NewHandler 创建同步处理器
func NewHandler(syncService syncservice.Service, app *appctx.App) *Handler {
	return &Handler{
		syncService: syncService,
		app:         app,
		log:         logger.New("api.v1.sync"),
	}
}

// StreamSyncAssets streams asset sync events as JSON Lines.
// @Summary      Stream asset sync
// @Description  Full or incremental sync. On incremental sync the server may emit `asset_delete_v1` after asset rows so clients can set deletedAt locally. Example delete event: {"type":"asset_delete_v1","ids":["uuid1"],"data":{}}.
// @Tags         Sync
// @Accept       json
// @Produce      application/jsonlines+json
// @Security     BearerAuth
// @Param        request body dto.SyncStreamRequest true "Sync request"
// @Success      200 "JSON Lines stream: asset_v1, asset_delete_v1, sync_complete_v1"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /sync/assets/stream [post]
func (h *Handler) StreamSyncAssets(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 1. 解析请求体
	var req dto.SyncStreamRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresponse.Error(c, "Invalid request body")
		return
	}

	// 2. 验证同步类型
	if len(req.Types) == 0 {
		apiresponse.Error(c, "Types cannot be empty")
		return
	}

	// 3. 解析 updated_after 时间戳
	updatedAfter, err := req.ParseUpdatedAfter()
	if err != nil {
		h.log.Warn("Invalid updated_after format",
			logger.Uint("user_id", userID),
			logger.Error(err),
		)
		apiresponse.Error(c, "Invalid 'updated_after' format. Must be RFC3339 format")
		return
	}

	// 4. 获取设备ID（从中间件，已保证存在）
	deviceID := middleware.MustGetDeviceID(c)
	deviceType := middleware.MustGetDeviceType(c)

	h.log.Info("Starting stream sync assets",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.String("device_type", deviceType),
		logger.Int("types_count", len(req.Types)),
		logger.Bool("reset", req.Reset),
	)

	// 5. 设置响应头
	c.Header("Content-Type", "application/jsonlines+json")
	c.Status(http.StatusOK)

	// 6. 调用服务层，流式写入响应
	if err := h.syncService.StreamAssets(c.Request.Context(), c.Writer, &syncservice.StreamAssetsRequest{
		UserID:       userID,
		Types:        convertSyncTypes(req.Types),
		Reset:        req.Reset,
		UpdatedAfter: updatedAfter,
		DeviceID:     deviceID,
	}); err != nil {
		h.log.Error("failed to stream sync assets",
			logger.Error(err),
			logger.Uint("user_id", userID),
			logger.String("device_id", deviceID),
			logger.String("device_type", deviceType),
		)
		// 如果响应已经开始写入，无法返回错误响应
		if !c.Writer.Written() {
			apiresponse.Error(c, "Failed to stream sync")
		}
		return
	}

	h.log.Info("Stream sync assets completed",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
	)
}

// GetCheckpoint returns sync checkpoints for the device.
// @Summary      Get checkpoints
// @Description  Checkpoints for the current user and device
// @Tags         Sync
// @Produce      json
// @Security     BearerAuth
// @Success      200 {object} response.ApiResponse{data=dto.GetCheckpointResponse} "OK"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /sync/checkpoint [get]
func (h *Handler) GetCheckpoint(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 1. 获取设备ID（从中间件，已保证存在）
	deviceID := middleware.MustGetDeviceID(c)
	deviceType := middleware.MustGetDeviceType(c)

	h.log.Debug("Getting checkpoint",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.String("device_type", deviceType),
	)

	// 2. 检查 CheckpointRepo 是否可用
	if h.app == nil || h.app.CheckpointRepo == nil {
		h.log.Error("checkpoint repository not available")
		apiresponse.Error(c, "Checkpoint service unavailable")
		return
	}

	// 3. 获取所有支持的同步类型的检查点
	// 目前只支持 assets_v1，后续可以扩展
	syncTypes := []string{"assets_v1"}
	checkpoints := make([]dto.CheckpointDto, 0, len(syncTypes))

	for _, syncType := range syncTypes {
		checkpoint, err := h.app.CheckpointRepo.GetCheckpoint(c.Request.Context(), userID, deviceID, syncType)
		if err != nil {
			h.log.Error("failed to get checkpoint",
				logger.Error(err),
				logger.Uint("user_id", userID),
				logger.String("device_id", deviceID),
				logger.String("sync_type", syncType),
			)
			// 继续处理其他类型，不中断
			continue
		}

		if checkpoint != nil {
			checkpoints = append(checkpoints, dto.CheckpointDto{
				Type: syncType,
				Ack:  checkpoint.Ack,
			})
		}
	}

	response := &dto.GetCheckpointResponse{
		Checkpoints: checkpoints,
	}

	h.log.Info("Get checkpoint completed",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.Int("checkpoints_count", len(checkpoints)),
	)

	apiresponse.Success(c, "Success", response)
}

// SetCheckpoint updates sync checkpoints.
// @Summary      Set checkpoints
// @Description  Upserts checkpoint ack values for the device
// @Tags         Sync
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body dto.SetCheckpointRequest true "Checkpoint payload"
// @Success      204 "No content"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /sync/checkpoint [post]
func (h *Handler) SetCheckpoint(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 1. 解析请求体
	var req dto.SetCheckpointRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresponse.Error(c, "Invalid request body")
		return
	}

	// 2. 验证请求参数
	if len(req.Checkpoints) == 0 {
		apiresponse.Error(c, "Checkpoints cannot be empty")
		return
	}

	// 3. 检查 CheckpointRepo 是否可用
	if h.app == nil || h.app.CheckpointRepo == nil {
		h.log.Error("checkpoint repository not available")
		apiresponse.Error(c, "Checkpoint service unavailable")
		return
	}

	// 4. 获取设备ID（从中间件，已保证存在）
	deviceID := middleware.MustGetDeviceID(c)
	deviceType := middleware.MustGetDeviceType(c)

	h.log.Info("Setting checkpoint",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.String("device_type", deviceType),
		logger.Int("checkpoints_count", len(req.Checkpoints)),
	)

	// 5. 批量设置检查点
	for _, checkpoint := range req.Checkpoints {
		if checkpoint.Type == "" {
			apiresponse.Error(c, "Checkpoint type cannot be empty")
			return
		}
		if checkpoint.Ack == "" {
			apiresponse.Error(c, "Checkpoint ack cannot be empty")
			return
		}

		if err := h.app.CheckpointRepo.SetCheckpoint(
			c.Request.Context(),
			userID,
			deviceID,
			checkpoint.Type,
			checkpoint.Ack,
		); err != nil {
			h.log.Error("failed to set checkpoint",
				logger.Error(err),
				logger.Uint("user_id", userID),
				logger.String("device_id", deviceID),
				logger.String("sync_type", checkpoint.Type),
			)
			apiresponse.Error(c, "Failed to set checkpoint")
			return
		}
	}

	c.Status(http.StatusNoContent)
}

// DeleteCheckpoint removes sync checkpoints by type.
// @Summary      Delete checkpoints
// @Description  Deletes checkpoints for the listed sync types on this device
// @Tags         Sync
// @Accept       json
// @Produce      json
// @Security     BearerAuth
// @Param        request body dto.DeleteCheckpointRequest true "Delete payload"
// @Success      204 "No content"
// @Failure      400 {object} response.ApiResponse "Bad request"
// @Failure      401 {object} response.ApiResponse "Unauthorized"
// @Router       /sync/checkpoint [delete]
func (h *Handler) DeleteCheckpoint(c *gin.Context) {
	userID := middleware.MustGetUserID(c)
	if c.IsAborted() {
		return
	}

	// 1. 解析请求体
	var req dto.DeleteCheckpointRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresponse.Error(c, "Invalid request body")
		return
	}

	// 2. 验证请求参数
	if len(req.Types) == 0 {
		apiresponse.Error(c, "Types cannot be empty")
		return
	}

	// 3. 检查 CheckpointRepo 是否可用
	if h.app == nil || h.app.CheckpointRepo == nil {
		h.log.Error("checkpoint repository not available")
		apiresponse.Error(c, "Checkpoint service unavailable")
		return
	}

	// 4. 获取设备ID（从中间件，已保证存在）
	deviceID := middleware.MustGetDeviceID(c)
	deviceType := middleware.MustGetDeviceType(c)

	h.log.Info("Deleting checkpoint",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.String("device_type", deviceType),
		logger.Int("types_count", len(req.Types)),
	)

	// 5. 批量删除检查点
	for _, syncType := range req.Types {
		if syncType == "" {
			apiresponse.Error(c, "Sync type cannot be empty")
			return
		}

		if err := h.app.CheckpointRepo.DeleteCheckpoint(
			c.Request.Context(),
			userID,
			deviceID,
			syncType,
		); err != nil {
			h.log.Error("failed to delete checkpoint",
				logger.Error(err),
				logger.Uint("user_id", userID),
				logger.String("device_id", deviceID),
				logger.String("sync_type", syncType),
			)
			apiresponse.Error(c, "Failed to delete checkpoint")
			return
		}
	}

	h.log.Info("Delete checkpoint completed",
		logger.Uint("user_id", userID),
		logger.String("device_id", deviceID),
		logger.Int("types_count", len(req.Types)),
	)

	c.Status(http.StatusNoContent)
}

// convertSyncTypes 转换同步类型
func convertSyncTypes(types []dto.SyncRequestType) []string {
	result := make([]string, len(types))
	for i, t := range types {
		result[i] = string(t)
	}
	return result
}
