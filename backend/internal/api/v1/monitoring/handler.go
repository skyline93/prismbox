package monitoring

import (
	"time"

	apiresponse "github.com/album/backend/internal/api/response"
	"github.com/album/backend/internal/monitoring"
	mediaservice "github.com/album/backend/internal/service/media"
	"github.com/album/backend/pkg/logger"
	"github.com/gin-gonic/gin"
)

// Handler 监控处理器
type Handler struct {
	mediaService mediaservice.Service
	log          logger.Logger
}

// NewHandler 创建监控处理器
func NewHandler(mediaService mediaservice.Service) *Handler {
	return &Handler{
		mediaService: mediaService,
		log:          logger.New("api.v1.monitoring"),
	}
}

// GetThumbnailMetrics returns thumbnail service metrics.
// @Summary      Thumbnail metrics
// @Description  Request counts, latencies, queue state, etc.
// @Tags         Monitoring
// @Produce      json
// @Security     BearerAuth
// @Success      200 {object} response.ApiResponse{data=object} "Metrics payload"
// @Router       /monitoring/thumbnail [get]
func (h *Handler) GetThumbnailMetrics(c *gin.Context) {
	h.log.Debug("thumbnail metrics request received")
	metrics := monitoring.GetThumbnailMetrics()

	// 计算平均延迟
	avgCacheLatency := time.Duration(0)
	avgStorageLatency := time.Duration(0)
	avgGenerationTime := time.Duration(0)
	avgPlaceholderTime := time.Duration(0)

	if metrics.CacheHits > 0 {
		avgCacheLatency = metrics.TotalCacheLatency / time.Duration(metrics.CacheHits)
	}
	if metrics.StorageHits > 0 {
		avgStorageLatency = metrics.TotalStorageLatency / time.Duration(metrics.StorageHits)
	}
	if metrics.GenerationSuccess > 0 {
		avgGenerationTime = metrics.TotalGenerationTime / time.Duration(metrics.GenerationSuccess)
	}
	if metrics.PlaceholderReturns > 0 {
		avgPlaceholderTime = metrics.TotalPlaceholderTime / time.Duration(metrics.PlaceholderReturns)
	}

	// 获取队列统计
	queueStats := h.mediaService.GetThumbnailQueueStats()
	cleanupStats := h.mediaService.GetCleanupStats()

	response := map[string]interface{}{
		"requests": map[string]interface{}{
			"total":               metrics.TotalRequests,
			"cache_hits":          metrics.CacheHits,
			"storage_hits":        metrics.StorageHits,
			"placeholder_returns": metrics.PlaceholderReturns,
			"generation_starts":   metrics.GenerationStarts,
			"generation_success":  metrics.GenerationSuccess,
			"generation_failures": metrics.GenerationFailures,
		},
		"performance": map[string]interface{}{
			"avg_cache_latency_ms":    avgCacheLatency.Milliseconds(),
			"avg_storage_latency_ms":  avgStorageLatency.Milliseconds(),
			"avg_generation_time_ms":  avgGenerationTime.Milliseconds(),
			"avg_placeholder_time_ms": avgPlaceholderTime.Milliseconds(),
		},
		"rates": map[string]interface{}{
			"cache_hit_rate":   metrics.CacheHitRate,
			"storage_hit_rate": metrics.StorageHitRate,
		},
		"queue":   queueStats,
		"cleanup": cleanupStats,
	}

	h.log.Debug("thumbnail metrics retrieved successfully",
		logger.Int64("total_requests", metrics.TotalRequests),
		logger.Int64("cache_hits", metrics.CacheHits),
		logger.Int64("storage_hits", metrics.StorageHits),
		logger.Int64("generation_success", metrics.GenerationSuccess),
	)

	apiresponse.Success(c, "Metrics retrieved", response)
}
