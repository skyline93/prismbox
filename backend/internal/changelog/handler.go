package changelog

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// syncHandler 封装了与同步相关的 API 接口
type syncHandler struct {
	service *syncService
	config  *Config
}

func newSyncHandler(service *syncService, config *Config) *syncHandler {
	return &syncHandler{
		service: service,
		config:  config,
	}
}

func (h *syncHandler) registerRoutes(router *gin.RouterGroup) {
	syncGroup := router.Group("/sync")
	{
		syncGroup.GET("", h.handleSync)
		syncGroup.GET("/full_init", h.handleFullSyncInit)
		syncGroup.GET("/full_data", h.handleFullSyncData)
	}
}

// handleSync 处理增量同步请求
func (h *syncHandler) handleSync(c *gin.Context) {
	// 获取隔离信息（从请求头或查询参数）
	// 这里使用通用的方式，不硬编码 user_id
	isolationKey := c.GetHeader("X-Isolation-Key")     // 如 "user_id"
	isolationValue := c.GetHeader("X-Isolation-Value") // 如 "123"
	deviceID := c.GetHeader("X-Device-ID")

	// 为了向后兼容，也支持旧的 X-User-ID header
	if isolationKey == "" && isolationValue == "" {
		userID := c.GetHeader("X-User-ID")
		if userID != "" {
			isolationKey = "user_id"
			isolationValue = userID
		}
	}

	if deviceID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "X-Device-ID header is required"})
		return
	}

	// 如果提供了隔离信息，则必须同时提供 key 和 value
	if (isolationKey != "" && isolationValue == "") || (isolationKey == "" && isolationValue != "") {
		c.JSON(http.StatusBadRequest, gin.H{"error": "X-Isolation-Key and X-Isolation-Value must be provided together"})
		return
	}

	lastSeqID, _ := strconv.ParseInt(c.Query("last_seq_id"), 10, 64)
	limit, err := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(h.config.DefaultSyncPageLimit)))
	if err != nil || limit <= 0 {
		limit = h.config.DefaultSyncPageLimit
	}

	// 构建查询条件
	query := &SyncQuery{
		IsolationKey:   isolationKey,
		IsolationValue: isolationValue,
	}

	changes, latestSeqID, hasMore, err := h.service.GetIncrementalChanges(query, lastSeqID, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch changes"})
		return
	}

	// 更新客户端状态（使用 isolationValue 作为 userID，用于向后兼容）
	userIDForStatus := isolationValue
	if userIDForStatus == "" {
		userIDForStatus = "unknown"
	}
	go h.service.UpdateClientStatus(deviceID, userIDForStatus, latestSeqID)

	c.JSON(http.StatusOK, gin.H{
		"changes":       changes,
		"latest_seq_id": latestSeqID,
		"has_more":      hasMore,
	})
}

// handleFullSyncInit 处理全量同步初始化请求
func (h *syncHandler) handleFullSyncInit(c *gin.Context) {
	tables, snapshotSeqID, err := h.service.GetFullSyncSnapshotInfo()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get snapshot info"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"tables_to_sync":  tables,
		"snapshot_seq_id": snapshotSeqID,
	})
}

// handleFullSyncData 处理全量同步数据请求
func (h *syncHandler) handleFullSyncData(c *gin.Context) {
	tableName := c.Query("table")
	if tableName == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "table query parameter is required"})
		return
	}

	// 获取隔离信息
	isolationKey := c.GetHeader("X-Isolation-Key")
	isolationValue := c.GetHeader("X-Isolation-Value")

	// 向后兼容
	if isolationKey == "" && isolationValue == "" {
		userID := c.GetHeader("X-User-ID")
		if userID != "" {
			isolationKey = "user_id"
			isolationValue = userID
		}
	}

	limit, err := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(h.config.DefaultSyncPageLimit)))
	if err != nil || limit <= 0 {
		limit = h.config.DefaultSyncPageLimit
	}

	pageToken := c.Query("page_token")

	// 构建查询条件
	query := &SyncQuery{
		IsolationKey:   isolationKey,
		IsolationValue: isolationValue,
		TableName:      tableName,
	}

	changes, nextToken, err := h.service.GetFullSyncDataForTable(query, tableName, pageToken, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch full data"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"changes":         changes,
		"next_page_token": nextToken,
	})
}
