package storage

import (
	"context"
	"io"
	"time"

	"github.com/album/backend/internal/storage/interfaces"
	"github.com/album/backend/internal/storage/primary/local"
)

// StorageManager 存储管理器（只负责主存储，不涉及云存储）
type StorageManager struct {
	primary interfaces.PrimaryStorage
}

// NewStorageManager 创建存储管理器
func NewStorageManager(primary interfaces.PrimaryStorage) *StorageManager {
	return &StorageManager{
		primary: primary,
	}
}

// Put 上传文件（只写入本地存储）
func (sm *StorageManager) Put(ctx context.Context, key string, data io.Reader, size int64, opts *interfaces.PutOptions) error {
	// 只写入本地存储，立即返回
	return sm.primary.Put(ctx, key, data, size, opts)
}

// Get 获取文件
func (sm *StorageManager) Get(ctx context.Context, key string) (io.ReadCloser, error) {
	return sm.primary.Get(ctx, key)
}

// Delete 删除文件
func (sm *StorageManager) Delete(ctx context.Context, key string) error {
	return sm.primary.Delete(ctx, key)
}

// Exists 检查文件是否存在
func (sm *StorageManager) Exists(ctx context.Context, key string) (bool, error) {
	return sm.primary.Exists(ctx, key)
}

// GetSignedURL 获取签名URL
func (sm *StorageManager) GetSignedURL(ctx context.Context, key string, duration time.Duration) (string, error) {
	return sm.primary.GetSignedURL(ctx, key, duration)
}

// Copy 复制文件
func (sm *StorageManager) Copy(ctx context.Context, srcKey, dstKey string) error {
	return sm.primary.Copy(ctx, srcKey, dstKey)
}

// Move 移动文件
func (sm *StorageManager) Move(ctx context.Context, srcKey, dstKey string) error {
	return sm.primary.Move(ctx, srcKey, dstKey)
}

// Stat 获取文件信息
func (sm *StorageManager) Stat(ctx context.Context, key string) (*interfaces.FileInfo, error) {
	return sm.primary.Stat(ctx, key)
}

// SelectPool 选择存储池
func (sm *StorageManager) SelectPool(size int64) (string, error) {
	return sm.primary.SelectPool(size)
}

// GetPoolInfo 获取存储池信息
func (sm *StorageManager) GetPoolInfo(poolID string) (*interfaces.PoolInfo, error) {
	return sm.primary.GetPoolInfo(poolID)
}

// GetCacheManager 获取缓存管理器（如果可用）
func (sm *StorageManager) GetCacheManager() *local.CacheManager {
	// 尝试获取 LocalStorage 的 CacheManager
	if ls, ok := sm.primary.(*local.LocalStorage); ok {
		return ls.GetCacheManager()
	}
	return nil
}
