package local

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"sync"

	"github.com/album/backend/internal/config/modules"
	"github.com/album/backend/internal/storage/interfaces"
)

// PoolManager 存储池管理器
type PoolManager struct {
	pools []*StoragePool
	mu    sync.RWMutex
}

// StoragePool 存储池
type StoragePool struct {
	ID                   string
	Path                 string
	MaxSize              int64
	CurrentSize          int64
	Priority             int
	Enabled              bool
	AutoDisableThreshold float64
	mu                   sync.RWMutex
}

// NewPoolManager 创建存储池管理器
func NewPoolManager(poolConfigs []*modules.StoragePoolConfig) (*PoolManager, error) {
	pm := &PoolManager{
		pools: make([]*StoragePool, 0, len(poolConfigs)),
	}

	for _, cfg := range poolConfigs {
		pool := &StoragePool{
			ID:                   cfg.ID,
			Path:                 cfg.Path,
			MaxSize:              cfg.MaxSize.Int64(),
			CurrentSize:          0,
			Priority:             cfg.Priority,
			Enabled:              cfg.Enabled,
			AutoDisableThreshold: cfg.AutoDisableThreshold,
		}

		// 确保目录存在
		if err := os.MkdirAll(pool.Path, 0755); err != nil {
			return nil, fmt.Errorf("create pool directory %s: %w", pool.Path, err)
		}

		// 计算当前使用量
		if err := pool.updateCurrentSize(); err != nil {
			return nil, fmt.Errorf("update pool size %s: %w", pool.ID, err)
		}

		pm.pools = append(pm.pools, pool)
	}

	return pm, nil
}

// SelectPool 根据策略选择可用的存储池
func (pm *PoolManager) SelectPool(requiredSize int64) (*StoragePool, error) {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	// 1. 过滤可用的池（启用且空间充足）
	availablePools := pm.filterAvailablePools(requiredSize)

	if len(availablePools) == 0 {
		return nil, fmt.Errorf("no available pool for size %d", requiredSize)
	}

	// 2. 按优先级排序
	sort.Slice(availablePools, func(i, j int) bool {
		return availablePools[i].Priority < availablePools[j].Priority
	})

	// 3. 选择最空闲的池（负载均衡）
	return pm.selectLeastLoadedPool(availablePools), nil
}

// filterAvailablePools 过滤可用的存储池
func (pm *PoolManager) filterAvailablePools(requiredSize int64) []*StoragePool {
	var available []*StoragePool

	for _, pool := range pm.pools {
		pool.mu.RLock()
		enabled := pool.Enabled
		availableSize := pool.MaxSize - pool.CurrentSize
		pool.mu.RUnlock()

		if enabled && availableSize >= requiredSize {
			// 检查是否超过阈值
			usedRatio := float64(pool.CurrentSize) / float64(pool.MaxSize)
			if usedRatio < pool.AutoDisableThreshold {
				available = append(available, pool)
			}
		}
	}

	return available
}

// selectLeastLoadedPool 选择最空闲的池
func (pm *PoolManager) selectLeastLoadedPool(pools []*StoragePool) *StoragePool {
	if len(pools) == 0 {
		return nil
	}

	bestPool := pools[0]
	bestRatio := float64(bestPool.CurrentSize) / float64(bestPool.MaxSize)

	for _, pool := range pools[1:] {
		pool.mu.RLock()
		ratio := float64(pool.CurrentSize) / float64(pool.MaxSize)
		pool.mu.RUnlock()

		if ratio < bestRatio {
			bestPool = pool
			bestRatio = ratio
		}
	}

	return bestPool
}

// GetPool 获取存储池
func (pm *PoolManager) GetPool(poolID string) (*StoragePool, error) {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	for _, pool := range pm.pools {
		if pool.ID == poolID {
			return pool, nil
		}
	}

	return nil, fmt.Errorf("pool not found: %s", poolID)
}

// GetPoolInfo 获取存储池信息
func (pm *PoolManager) GetPoolInfo(poolID string) (*interfaces.PoolInfo, error) {
	pool, err := pm.GetPool(poolID)
	if err != nil {
		return nil, err
	}

	pool.mu.RLock()
	defer pool.mu.RUnlock()

	return &interfaces.PoolInfo{
		ID:          pool.ID,
		Path:        pool.Path,
		MaxSize:     pool.MaxSize,
		CurrentSize: pool.CurrentSize,
		Priority:    pool.Priority,
		Enabled:     pool.Enabled,
	}, nil
}

// CheckAndUpdatePools 定期检查存储池状态
func (pm *PoolManager) CheckAndUpdatePools() error {
	pm.mu.RLock()
	defer pm.mu.RUnlock()

	for _, pool := range pm.pools {
		// 更新当前使用量
		if err := pool.updateCurrentSize(); err != nil {
			return fmt.Errorf("update pool size %s: %w", pool.ID, err)
		}

		pool.mu.RLock()
		usedRatio := float64(pool.CurrentSize) / float64(pool.MaxSize)
		enabled := pool.Enabled
		pool.mu.RUnlock()

		// 检查是否超过阈值
		if usedRatio >= pool.AutoDisableThreshold && enabled {
			pool.Disable()
		} else if usedRatio < pool.AutoDisableThreshold && !enabled {
			pool.Enable()
		}
	}

	return nil
}

// Enable 启用存储池
func (sp *StoragePool) Enable() {
	sp.mu.Lock()
	defer sp.mu.Unlock()
	sp.Enabled = true
}

// Disable 禁用存储池
func (sp *StoragePool) Disable() {
	sp.mu.Lock()
	defer sp.mu.Unlock()
	sp.Enabled = false
}

// AddSize 增加使用量
func (sp *StoragePool) AddSize(size int64) {
	sp.mu.Lock()
	defer sp.mu.Unlock()
	sp.CurrentSize += size
}

// SubtractSize 减少使用量
func (sp *StoragePool) SubtractSize(size int64) {
	sp.mu.Lock()
	defer sp.mu.Unlock()
	if sp.CurrentSize > size {
		sp.CurrentSize -= size
	} else {
		sp.CurrentSize = 0
	}
}

// updateCurrentSize 更新当前使用量
func (sp *StoragePool) updateCurrentSize() error {
	sp.mu.Lock()
	defer sp.mu.Unlock()

	var totalSize int64
	err := filepath.Walk(sp.Path, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			totalSize += info.Size()
		}
		return nil
	})

	if err != nil {
		return err
	}

	sp.CurrentSize = totalSize
	return nil
}
