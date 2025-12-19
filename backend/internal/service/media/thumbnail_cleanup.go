package media

import (
	"context"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/album/backend/internal/storage"
	"github.com/album/backend/pkg/logger"
)

// ThumbnailAccessRecord 缩略图访问记录
type ThumbnailAccessRecord struct {
	Key         string
	LastAccess  time.Time
	AccessCount int64
}

// ThumbnailCleanupService 动态缩略图清理服务
type ThumbnailCleanupService struct {
	accessRecords  map[string]*ThumbnailAccessRecord // key -> 访问记录
	mu             sync.RWMutex
	storageManager *storage.StorageManager
	storageAdapter *StorageAdapter
	log            logger.Logger

	// 清理配置
	maxAge          time.Duration // 最大未访问时间（超过此时间的动态缩略图将被清理）
	cleanupInterval time.Duration // 清理任务执行间隔
	maxCount        int64         // 最大访问次数阈值（低于此值的动态缩略图优先清理）
}

// NewThumbnailCleanupService 创建清理服务
func NewThumbnailCleanupService(
	storageManager *storage.StorageManager,
	storageAdapter *StorageAdapter,
	maxAge time.Duration,
	cleanupInterval time.Duration,
) *ThumbnailCleanupService {
	return &ThumbnailCleanupService{
		accessRecords:   make(map[string]*ThumbnailAccessRecord),
		storageManager:  storageManager,
		storageAdapter:  storageAdapter,
		log:             logger.New("service.media.thumbnail_cleanup"),
		maxAge:          maxAge,
		cleanupInterval: cleanupInterval,
		maxCount:        5, // 默认：访问次数少于5次的动态缩略图优先清理
	}
}

// RecordAccess 记录动态缩略图访问
func (s *ThumbnailCleanupService) RecordAccess(key string) {
	// 检查是否是动态缩略图（包含 thumbnail_ 且不是固定的 thumbnail 或 preview）
	if !s.isDynamicThumbnail(key) {
		return
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	record, exists := s.accessRecords[key]
	if !exists {
		record = &ThumbnailAccessRecord{
			Key:         key,
			LastAccess:  time.Now(),
			AccessCount: 1,
		}
		s.accessRecords[key] = record
		s.log.Debug("new dynamic thumbnail access recorded",
			logger.String("storage_key", key),
		)
	} else {
		record.LastAccess = time.Now()
		record.AccessCount++
		if record.AccessCount%10 == 0 {
			// 每10次访问记录一次日志，避免日志过多
			s.log.Debug("dynamic thumbnail access count updated",
				logger.String("storage_key", key),
				logger.Int64("access_count", record.AccessCount),
			)
		}
	}
}

// isDynamicThumbnail 判断是否是动态缩略图
func (s *ThumbnailCleanupService) isDynamicThumbnail(key string) bool {
	// 解析 key，检查 variant
	parts := strings.Split(key, "/")
	if len(parts) < 3 {
		return false
	}

	filename := parts[len(parts)-1]
	// 检查是否包含 thumbnail_ 且不是固定的 thumbnail 或 preview
	if strings.Contains(filename, "_thumbnail_") {
		// 提取 variant 部分
		base := strings.TrimSuffix(filename, filepath.Ext(filename))
		if idx := strings.LastIndex(base, "_"); idx > 0 {
			variant := base[idx+1:]
			// 动态 variant 格式：thumbnail_{width}x{height}
			if strings.HasPrefix(variant, "thumbnail_") {
				sizePart := strings.TrimPrefix(variant, "thumbnail_")
				// 检查是否是尺寸格式（如 200x200）
				if strings.Contains(sizePart, "x") {
					return true
				}
			}
		}
	}

	return false
}

// StartCleanup 启动定期清理任务
func (s *ThumbnailCleanupService) StartCleanup(ctx context.Context) {
	ticker := time.NewTicker(s.cleanupInterval)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				if err := s.Cleanup(ctx); err != nil {
					s.log.Error("thumbnail cleanup failed",
						logger.Error(err),
					)
				}
			}
		}
	}()
}

// Cleanup 执行清理任务
func (s *ThumbnailCleanupService) Cleanup(ctx context.Context) error {
	cleanupStartTime := time.Now()
	s.mu.Lock()
	defer s.mu.Unlock()

	now := time.Now()
	var toDelete []string
	var totalSize int64
	totalRecords := len(s.accessRecords)

	s.log.Debug("starting thumbnail cleanup",
		logger.Int("total_records", totalRecords),
		logger.Duration("max_age", s.maxAge),
	)

	// 找出需要清理的动态缩略图
	for key, record := range s.accessRecords {
		// 检查是否超过最大未访问时间
		age := now.Sub(record.LastAccess)
		if age > s.maxAge {
			toDelete = append(toDelete, key)
			continue
		}

		// 检查访问次数是否低于阈值
		if record.AccessCount < s.maxCount && age > s.maxAge/2 {
			toDelete = append(toDelete, key)
		}
	}

	// 删除需要清理的缩略图
	deletedCount := 0
	failedCount := 0
	for _, key := range toDelete {
		record := s.accessRecords[key]
		age := now.Sub(record.LastAccess)

		// 检查文件是否存在
		exists, err := s.storageManager.Exists(ctx, key)
		if err != nil {
			s.log.Warn("failed to check thumbnail existence during cleanup",
				logger.String("storage_key", key),
				logger.Duration("age", age),
				logger.Int64("access_count", record.AccessCount),
				logger.Error(err),
			)
			failedCount++
			// 即使检查失败，也删除访问记录
			delete(s.accessRecords, key)
			continue
		}

		if exists {
			// 获取文件信息以计算大小
			stat, err := s.storageManager.Stat(ctx, key)
			if err == nil && stat != nil {
				totalSize += stat.Size
			}

			// 删除文件
			if err := s.storageManager.Delete(ctx, key); err != nil {
				s.log.Warn("failed to delete thumbnail during cleanup",
					logger.String("storage_key", key),
					logger.Duration("age", age),
					logger.Int64("access_count", record.AccessCount),
					logger.Error(err),
				)
				failedCount++
				// 删除失败时保留访问记录，下次清理时重试
				continue
			}

			deletedCount++
			s.log.Debug("dynamic thumbnail deleted during cleanup",
				logger.String("storage_key", key),
				logger.Duration("age", age),
				logger.Int64("access_count", record.AccessCount),
				logger.Int64("file_size_bytes", func() int64 {
					if stat != nil {
						return stat.Size
					}
					return 0
				}()),
			)
		}

		// 删除访问记录
		delete(s.accessRecords, key)
	}

	cleanupLatency := time.Since(cleanupStartTime)
	if len(toDelete) > 0 {
		s.log.Info("thumbnail cleanup completed",
			logger.Int("candidates_count", len(toDelete)),
			logger.Int("deleted_count", deletedCount),
			logger.Int("failed_count", failedCount),
			logger.Int64("freed_size_bytes", totalSize),
			logger.Int("remaining_records", len(s.accessRecords)),
			logger.Duration("cleanup_latency_ms", cleanupLatency),
		)
	} else {
		s.log.Debug("thumbnail cleanup completed, no thumbnails to delete",
			logger.Int("total_records", totalRecords),
			logger.Duration("cleanup_latency_ms", cleanupLatency),
		)
	}

	return nil
}

// GetStats 获取清理服务统计信息
func (s *ThumbnailCleanupService) GetStats() map[string]interface{} {
	s.mu.RLock()
	defer s.mu.RUnlock()

	return map[string]interface{}{
		"total_records":    len(s.accessRecords),
		"max_age":          s.maxAge.String(),
		"cleanup_interval": s.cleanupInterval.String(),
	}
}
