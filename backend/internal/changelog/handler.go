package changelog

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// changelogHandler 封装了与变更日志相关的 API 接口
type changelogHandler struct {
	service *changelogService
	config  *Config
}

func newChangelogHandler(service *changelogService, config *Config) *changelogHandler {
	return &changelogHandler{
		service: service,
		config:  config,
	}
}

func (h *changelogHandler) registerRoutes(router *gin.RouterGroup) {
	changelogGroup := router.Group("/changelog")
	{
		changelogGroup.GET("", h.handleIncrementalChanges)
		changelogGroup.GET("/full_init", h.handleFullChangelogInit)
		changelogGroup.GET("/full_data", h.handleFullChangelogData)
	}

	// 向后兼容：/sync (保持与旧架构server一致)
	syncGroup := router.Group("/sync")
	{
		syncGroup.GET("", h.handleIncrementalChanges)
		syncGroup.GET("/full_init", h.handleFullChangelogInit)
		syncGroup.GET("/full_data", h.handleFullChangelogData)
	}
}

// handleIncrementalChanges 处理增量变更日志请求
func (h *changelogHandler) handleIncrementalChanges(c *gin.Context) {
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
	limit, err := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(h.config.DefaultChangelogPageLimit)))
	if err != nil || limit <= 0 {
		limit = h.config.DefaultChangelogPageLimit
	}

	// 构建查询条件
	query := &ChangelogQuery{
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

// handleFullChangelogInit 处理全量变更日志初始化请求
func (h *changelogHandler) handleFullChangelogInit(c *gin.Context) {
	tables, snapshotSeqID, err := h.service.GetFullChangelogSnapshotInfo()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get snapshot info"})
		return
	}
	c.JSON(http.StatusOK, gin.H{
		"tables_to_sync":  tables,
		"snapshot_seq_id": snapshotSeqID,
	})
}

// handleFullChangelogData 处理全量变更日志数据请求
func (h *changelogHandler) handleFullChangelogData(c *gin.Context) {
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

	limit, err := strconv.Atoi(c.DefaultQuery("limit", strconv.Itoa(h.config.DefaultChangelogPageLimit)))
	if err != nil || limit <= 0 {
		limit = h.config.DefaultChangelogPageLimit
	}

	pageToken := c.Query("page_token")

	// 构建查询条件
	query := &ChangelogQuery{
		IsolationKey:   isolationKey,
		IsolationValue: isolationValue,
		TableName:      tableName,
	}

	changes, nextToken, err := h.service.GetFullChangelogDataForTable(query, tableName, pageToken, limit)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch full data"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"changes":         changes,
		"next_page_token": nextToken,
	})
}
