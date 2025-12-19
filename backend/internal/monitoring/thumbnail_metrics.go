package monitoring

import (
	"sync"
	"time"
)

// ThumbnailMetrics 缩略图服务监控指标
type ThumbnailMetrics struct {
	mu sync.RWMutex

	// 请求统计
	TotalRequests      int64
	CacheHits          int64 // 缓存命中（L1/L2）
	StorageHits        int64 // 主存储命中（L3）
	PlaceholderReturns int64 // 返回占位符次数
	GenerationStarts   int64 // 开始生成次数
	GenerationSuccess  int64 // 生成成功次数
	GenerationFailures int64 // 生成失败次数

	// 性能指标
	TotalCacheLatency    time.Duration
	TotalStorageLatency  time.Duration
	TotalGenerationTime  time.Duration
	TotalPlaceholderTime time.Duration

	// 队列指标
	MaxQueueLength     int
	CurrentQueueLength int
	AverageWaitTime    time.Duration

	// 缓存指标
	CacheHitRate   float64
	StorageHitRate float64
}

var thumbnailMetrics = &ThumbnailMetrics{}

// GetThumbnailMetrics 获取缩略图监控指标
func GetThumbnailMetrics() *ThumbnailMetrics {
	thumbnailMetrics.mu.RLock()
	defer thumbnailMetrics.mu.RUnlock()

	// 计算命中率
	if thumbnailMetrics.TotalRequests > 0 {
		thumbnailMetrics.CacheHitRate = float64(thumbnailMetrics.CacheHits) / float64(thumbnailMetrics.TotalRequests) * 100
		thumbnailMetrics.StorageHitRate = float64(thumbnailMetrics.StorageHits) / float64(thumbnailMetrics.TotalRequests) * 100
	}

	return thumbnailMetrics
}

// RecordThumbnailRequest 记录缩略图请求
func RecordThumbnailRequest() {
	thumbnailMetrics.mu.Lock()
	defer thumbnailMetrics.mu.Unlock()
	thumbnailMetrics.TotalRequests++
}

// RecordThumbnailCacheHit 记录缩略图缓存命中
func RecordThumbnailCacheHit(latency time.Duration) {
	thumbnailMetrics.mu.Lock()
	defer thumbnailMetrics.mu.Unlock()
	thumbnailMetrics.CacheHits++
	thumbnailMetrics.TotalCacheLatency += latency
}

// RecordThumbnailStorageHit 记录缩略图主存储命中
func RecordThumbnailStorageHit(latency time.Duration) {
	thumbnailMetrics.mu.Lock()
	defer thumbnailMetrics.mu.Unlock()
	thumbnailMetrics.StorageHits++
	thumbnailMetrics.TotalStorageLatency += latency
}

// RecordThumbnailPlaceholder 记录返回缩略图占位符
func RecordThumbnailPlaceholder(latency time.Duration) {
	thumbnailMetrics.mu.Lock()
	defer thumbnailMetrics.mu.Unlock()
	thumbnailMetrics.PlaceholderReturns++
	thumbnailMetrics.TotalPlaceholderTime += latency
}

// RecordThumbnailGenerationStart 记录开始生成缩略图
func RecordThumbnailGenerationStart() {
	thumbnailMetrics.mu.Lock()
	defer thumbnailMetrics.mu.Unlock()
	thumbnailMetrics.GenerationStarts++
}

// RecordThumbnailGenerationSuccess 记录缩略图生成成功
func RecordThumbnailGenerationSuccess(duration time.Duration) {
	thumbnailMetrics.mu.Lock()
	defer thumbnailMetrics.mu.Unlock()
	thumbnailMetrics.GenerationSuccess++
	thumbnailMetrics.TotalGenerationTime += duration
}

// RecordThumbnailGenerationFailure 记录缩略图生成失败
func RecordThumbnailGenerationFailure() {
	thumbnailMetrics.mu.Lock()
	defer thumbnailMetrics.mu.Unlock()
	thumbnailMetrics.GenerationFailures++
}

// UpdateThumbnailQueueStats 更新缩略图队列统计
func UpdateThumbnailQueueStats(length int) {
	thumbnailMetrics.mu.Lock()
	defer thumbnailMetrics.mu.Unlock()
	thumbnailMetrics.CurrentQueueLength = length
	if length > thumbnailMetrics.MaxQueueLength {
		thumbnailMetrics.MaxQueueLength = length
	}
}
