package local

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// CacheManager 缓存管理器
type CacheManager struct {
	memoryCache     *MemoryCache
	diskCachePath   string
	maxDiskSize     int64
	currentDiskSize int64
	ttl             time.Duration
	mu              sync.RWMutex
}

// MemoryCache 内存缓存（简单的LRU实现）
type MemoryCache struct {
	cache   map[string]*CacheEntry
	maxSize int
	mu      sync.RWMutex
}

// CacheEntry 缓存条目
type CacheEntry struct {
	Data      []byte
	Timestamp time.Time
}

// NewCacheManager 创建缓存管理器。磁盘缓存路径来自配置 performance.cache_path，未配置时使用默认 "./data/cache"。
func NewCacheManager(cfg *PerformanceConfig) (*CacheManager, error) {
	if cfg == nil || !cfg.CacheEnabled {
		return nil, nil // 缓存未启用
	}

	diskPath := cfg.CachePath
	if diskPath == "" {
		diskPath = "./data/cache"
	}

	cm := &CacheManager{
		memoryCache: &MemoryCache{
			cache:   make(map[string]*CacheEntry),
			maxSize: 100,
		},
		diskCachePath: diskPath,
		maxDiskSize:   cfg.CacheSize.Int64(),
		ttl:           cfg.CacheTTL.Duration(),
	}

	// 确保磁盘缓存目录存在
	if err := os.MkdirAll(cm.diskCachePath, 0755); err != nil {
		return nil, fmt.Errorf("create cache directory: %w", err)
	}

	// 计算当前磁盘缓存大小
	if err := cm.updateDiskSize(); err != nil {
		return nil, fmt.Errorf("update disk cache size: %w", err)
	}

	return cm, nil
}

// Get 获取缓存（先查内存，再查磁盘，最后返回nil）
func (cm *CacheManager) Get(key string) (io.ReadCloser, error) {
	if cm == nil {
		return nil, nil // 缓存未启用
	}

	// 1. 内存缓存
	cm.memoryCache.mu.RLock()
	if entry, ok := cm.memoryCache.cache[key]; ok {
		// 检查是否过期
		if time.Since(entry.Timestamp) < cm.ttl {
			// 返回内存缓存的数据
			data := make([]byte, len(entry.Data))
			copy(data, entry.Data)
			cm.memoryCache.mu.RUnlock()
			return io.NopCloser(bytes.NewReader(data)), nil
		}
		// 已过期，删除
		delete(cm.memoryCache.cache, key)
	}
	cm.memoryCache.mu.RUnlock()

	// 2. 磁盘缓存
	cachePath := filepath.Join(cm.diskCachePath, key)
	info, err := os.Stat(cachePath)
	if err == nil {
		// 检查是否过期
		if time.Since(info.ModTime()) < cm.ttl {
			file, err := os.Open(cachePath)
			if err == nil {
				return file, nil
			}
		} else {
			// 已过期，删除
			os.Remove(cachePath)
		}
	}

	return nil, nil
}

// Put 写入缓存
func (cm *CacheManager) Put(key string, data []byte) error {
	if cm == nil {
		return nil // 缓存未启用
	}

	// 1. 写入内存缓存
	cm.memoryCache.mu.Lock()
	if len(cm.memoryCache.cache) >= cm.memoryCache.maxSize {
		// 删除最旧的条目
		cm.evictOldest()
	}
	cm.memoryCache.cache[key] = &CacheEntry{
		Data:      data,
		Timestamp: time.Now(),
	}
	cm.memoryCache.mu.Unlock()

	// 2. 写入磁盘缓存
	cachePath := filepath.Join(cm.diskCachePath, key)
	if err := os.MkdirAll(filepath.Dir(cachePath), 0755); err != nil {
		return fmt.Errorf("create cache directory: %w", err)
	}

	if err := os.WriteFile(cachePath, data, 0644); err != nil {
		return fmt.Errorf("write cache file: %w", err)
	}

	// 更新磁盘缓存大小
	cm.mu.Lock()
	cm.currentDiskSize += int64(len(data))
	cm.mu.Unlock()

	// 检查是否需要清理
	if cm.currentDiskSize > cm.maxDiskSize {
		go cm.cleanup()
	}

	return nil
}

// evictOldest 删除最旧的条目
func (cm *CacheManager) evictOldest() {
	var oldestKey string
	var oldestTime time.Time

	for key, entry := range cm.memoryCache.cache {
		if oldestKey == "" || entry.Timestamp.Before(oldestTime) {
			oldestKey = key
			oldestTime = entry.Timestamp
		}
	}

	if oldestKey != "" {
		delete(cm.memoryCache.cache, oldestKey)
	}
}

// cleanup 清理过期缓存
func (cm *CacheManager) cleanup() {
	cm.mu.Lock()
	defer cm.mu.Unlock()

	now := time.Now()
	var totalSize int64

	err := filepath.Walk(cm.diskCachePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		// 检查是否过期
		if now.Sub(info.ModTime()) >= cm.ttl {
			os.Remove(path)
		} else {
			totalSize += info.Size()
		}

		return nil
	})

	if err == nil {
		cm.currentDiskSize = totalSize
	}
}

// updateDiskSize 更新磁盘缓存大小
func (cm *CacheManager) updateDiskSize() error {
	var totalSize int64
	err := filepath.Walk(cm.diskCachePath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			totalSize += info.Size()
		}
		return nil
	})

	cm.mu.Lock()
	cm.currentDiskSize = totalSize
	cm.mu.Unlock()

	return err
}
