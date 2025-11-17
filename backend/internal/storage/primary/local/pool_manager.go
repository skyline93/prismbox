package local

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"sync"
	"time"

	"github.com/album/backend/internal/config/modules"
	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage/interfaces"
	"github.com/album/backend/pkg/logger"
)

const (
	defaultDeltaChannelSize     = 1024
	defaultDeltaBatchSize       = 128
	defaultFlushInterval        = 2 * time.Second
	defaultCacheRefreshInterval = 5 * time.Minute
)

// PoolManager 管理本地/云存储池：内存缓存 + 可靠串行持久化
type PoolManager struct {
	repo        repository.StoragePoolRepository
	storageType string

	cache   map[string]*StoragePool
	cacheMu sync.RWMutex

	deltaCh   chan PoolDelta
	batchSize int

	flushInterval        time.Duration
	cacheRefreshInterval time.Duration
	reconcileInterval    time.Duration

	stopCh  chan struct{}
	flushCh chan struct{}
	wg      sync.WaitGroup

	log logger.Logger
}

// StoragePool 缓存中的存储池
type StoragePool struct {
	UUID                 string
	Name                 string
	Path                 string
	MaxSize              int64
	CurrentSize          int64
	Priority             int
	Enabled              bool
	AutoDisableThreshold float64
	Status               string
	LastCheckedAt        *time.Time

	mu sync.RWMutex
}

// PoolDelta 使用量增量
type PoolDelta struct {
	PoolUUID string
	Delta    int64
	Occurred time.Time
}

// NewPoolManager 创建存储池管理器
func NewPoolManager(cfg *modules.PoolManagerConfig, storageType string, repo repository.StoragePoolRepository) (*PoolManager, error) {
	settings := normalizePoolManagerConfig(cfg)

	pm := &PoolManager{
		repo:        repo,
		storageType: storageType,
		cache:       make(map[string]*StoragePool),
		deltaCh:     make(chan PoolDelta, settings.deltaChannelSize),
		batchSize:   settings.deltaBatchSize,

		flushInterval:        settings.flushInterval,
		cacheRefreshInterval: settings.cacheRefreshInterval,
		reconcileInterval:    settings.reconcileInterval,

		stopCh:  make(chan struct{}),
		flushCh: make(chan struct{}, 1),
		log:     logger.New("storage.pool_manager"),
	}

	if err := pm.refreshCache(context.Background()); err != nil {
		return nil, err
	}

	// 检查缓存是否为空，记录警告
	pm.cacheMu.RLock()
	cacheEmpty := len(pm.cache) == 0
	pm.cacheMu.RUnlock()
	if cacheEmpty {
		pm.log.Warn("pool manager initialized with no storage pools",
			logger.String("storage_type", storageType),
			logger.String("message", "storage operations will fail until pools are created and enabled"),
		)
	}

	pm.startDeltaWorker()
	pm.startCacheRefresher()
	pm.startReconciler()

	return pm, nil
}

// Close 关闭所有后台协程
func (pm *PoolManager) Close() {
	select {
	case <-pm.stopCh:
		return
	default:
		close(pm.stopCh)
	}
	pm.wg.Wait()
}

// SelectPool 根据策略选择可用的存储池
func (pm *PoolManager) SelectPool(requiredSize int64) (*StoragePool, error) {
	pools := pm.snapshotPools()
	if len(pools) == 0 {
		return nil, fmt.Errorf("no available storage pools for type %s", pm.storageType)
	}

	available := filterAvailablePools(pools, requiredSize)
	if len(available) == 0 {
		return nil, fmt.Errorf("no available pool for size %d", requiredSize)
	}

	sort.Slice(available, func(i, j int) bool {
		return available[i].Priority < available[j].Priority
	})

	return selectLeastLoadedPool(available), nil
}

// RecordUsage 记录使用量增量（内存更新 + 异步持久化）
func (pm *PoolManager) RecordUsage(poolUUID string, delta int64) {
	if delta == 0 {
		return
	}

	pool := pm.getPool(poolUUID)
	if pool == nil {
		pm.log.Warn("pool not found in cache", logger.String("pool_uuid", poolUUID))
		return
	}

	pool.applyDelta(delta)

	select {
	case pm.deltaCh <- PoolDelta{PoolUUID: poolUUID, Delta: delta, Occurred: time.Now()}:
	case <-pm.stopCh:
	}
}

// GetPoolInfo 获取存储池信息
func (pm *PoolManager) GetPoolInfo(poolUUID string) (*interfaces.PoolInfo, error) {
	pool := pm.getPool(poolUUID)
	if pool == nil {
		return nil, fmt.Errorf("pool not found: %s", poolUUID)
	}

	pool.mu.RLock()
	defer pool.mu.RUnlock()

	return &interfaces.PoolInfo{
		ID:          pool.UUID,
		Path:        pool.Path,
		MaxSize:     pool.MaxSize,
		CurrentSize: pool.CurrentSize,
		Priority:    pool.Priority,
		Enabled:     pool.Enabled,
	}, nil
}

// RefreshCache 手动刷新缓存
func (pm *PoolManager) RefreshCache(ctx context.Context) error {
	if ctx == nil {
		ctx = context.Background()
	}
	return pm.refreshCache(ctx)
}

// Reconcile 执行一次对账，可选指定单个存储池
func (pm *PoolManager) Reconcile(ctx context.Context, poolUUID string, dryRun bool) error {
	if ctx == nil {
		ctx = context.Background()
	}

	targets := pm.snapshotPools()
	if poolUUID != "" {
		filtered := make([]*StoragePool, 0, 1)
		for _, pool := range targets {
			if pool.UUID == poolUUID {
				filtered = append(filtered, pool)
				break
			}
		}
		if len(filtered) == 0 {
			return fmt.Errorf("pool not found: %s", poolUUID)
		}
		targets = filtered
	}

	for _, pool := range targets {
		if err := pool.refreshActualUsage(); err != nil {
			return err
		}
		if dryRun {
			continue
		}
		now := time.Now()
		if err := pm.repo.UpdateState(ctx, pool.UUID, pool.Enabled, pool.Status, pool.CurrentSize, &now); err != nil {
			return err
		}
	}
	return nil
}

// CheckAndUpdatePools 手动触发检查（主要用于测试）
func (pm *PoolManager) CheckAndUpdatePools(ctx context.Context) error {
	pools := pm.snapshotPools()
	for _, pool := range pools {
		if err := pool.refreshActualUsage(); err != nil {
			return err
		}
		now := time.Now()
		if err := pm.repo.UpdateState(ctx, pool.UUID, pool.Enabled, pool.Status, pool.CurrentSize, &now); err != nil {
			return err
		}
	}
	return nil
}

// snapshotPools 拷贝缓存
func (pm *PoolManager) snapshotPools() []*StoragePool {
	pm.cacheMu.RLock()
	defer pm.cacheMu.RUnlock()

	pools := make([]*StoragePool, 0, len(pm.cache))
	for _, pool := range pm.cache {
		pools = append(pools, pool)
	}
	return pools
}

// getPool 获取缓存中的存储池
func (pm *PoolManager) getPool(uuid string) *StoragePool {
	pm.cacheMu.RLock()
	defer pm.cacheMu.RUnlock()
	return pm.cache[uuid]
}

// refreshCache 从数据库加载存储池
func (pm *PoolManager) refreshCache(ctx context.Context) error {
	pools, err := pm.repo.FindEnabledByStorageType(ctx, pm.storageType)
	if err != nil {
		return fmt.Errorf("load storage pools: %w", err)
	}

	// 没有存储池时记录警告，但不返回错误，允许服务继续启动
	if len(pools) == 0 {
		pm.log.Warn("no enabled storage pools found",
			logger.String("storage_type", pm.storageType),
			logger.String("message", "service will start but storage operations may fail until pools are configured"),
		)
		// 清空缓存，允许服务继续启动
		pm.cacheMu.Lock()
		pm.cache = make(map[string]*StoragePool)
		pm.cacheMu.Unlock()
		return nil
	}

	newCache := make(map[string]*StoragePool, len(pools))
	for _, pool := range pools {
		localPool, err := convertModelToPool(pool)
		if err != nil {
			return err
		}
		newCache[localPool.UUID] = localPool
	}

	pm.cacheMu.Lock()
	pm.cache = newCache
	pm.cacheMu.Unlock()

	pm.log.Info("storage pools cache refreshed",
		logger.Int("count", len(newCache)),
		logger.String("storage_type", pm.storageType),
	)
	return nil
}

// startDeltaWorker 串行持久化增量
func (pm *PoolManager) startDeltaWorker() {
	pm.wg.Add(1)
	go func() {
		defer pm.wg.Done()

		ticker := time.NewTicker(pm.flushInterval)
		defer ticker.Stop()

		pending := make(map[string]int64)

		flush := func() {
			if len(pending) == 0 {
				return
			}
			if err := pm.persistDeltas(pending); err != nil {
				pm.log.Error("persist pool deltas failed", logger.Error(err))
				// 重试：将待写增量重新放回通道
				for poolUUID, delta := range pending {
					if delta != 0 {
						select {
						case pm.deltaCh <- PoolDelta{PoolUUID: poolUUID, Delta: delta, Occurred: time.Now()}:
						case <-pm.stopCh:
							return
						}
					}
				}
			}
			pending = make(map[string]int64)
		}

		for {
			select {
			case delta := <-pm.deltaCh:
				pending[delta.PoolUUID] += delta.Delta
				if pm.batchSize > 0 && len(pending) >= pm.batchSize {
					flush()
				}
			case <-pm.flushCh:
				flush()
			case <-ticker.C:
				flush()
			case <-pm.stopCh:
				flush()
				return
			}
		}
	}()
}

// startCacheRefresher 定期刷新缓存
func (pm *PoolManager) startCacheRefresher() {
	pm.wg.Add(1)
	go func() {
		defer pm.wg.Done()

		ticker := time.NewTicker(pm.cacheRefreshInterval)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
				if err := pm.refreshCache(ctx); err != nil {
					pm.log.Error("refresh storage pool cache failed", logger.Error(err))
				}
				cancel()
			case <-pm.stopCh:
				return
			}
		}
	}()
}

// startReconciler 定期对账
func (pm *PoolManager) startReconciler() {
	if pm.reconcileInterval <= 0 {
		return
	}

	pm.wg.Add(1)
	go func() {
		defer pm.wg.Done()

		ticker := time.NewTicker(pm.reconcileInterval)
		defer ticker.Stop()

		for {
			select {
			case <-ticker.C:
				pm.reconcileOnce()
			case <-pm.stopCh:
				return
			}
		}
	}()
}

func (pm *PoolManager) reconcileOnce() {
	ctx, cancel := context.WithTimeout(context.Background(), pm.reconcileInterval)
	defer cancel()

	pools := pm.snapshotPools()
	for _, pool := range pools {
		if err := pool.refreshActualUsage(); err != nil {
			pm.log.Warn("refresh pool usage failed",
				logger.String("pool_uuid", pool.UUID),
				logger.Error(err),
			)
			continue
		}
		now := time.Now()
		if err := pm.repo.UpdateState(ctx, pool.UUID, pool.Enabled, pool.Status, pool.CurrentSize, &now); err != nil {
			pm.log.Warn("update pool state failed",
				logger.String("pool_uuid", pool.UUID),
				logger.Error(err),
			)
		}
	}
}

// persistDeltas 将增量落库
func (pm *PoolManager) persistDeltas(deltas map[string]int64) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	for poolUUID, delta := range deltas {
		if delta == 0 {
			continue
		}
		if err := pm.repo.IncrementCurrentSize(ctx, poolUUID, delta); err != nil {
			return fmt.Errorf("increment pool %s: %w", poolUUID, err)
		}
	}
	return nil
}

// filterAvailablePools 过滤可用的存储池
func filterAvailablePools(pools []*StoragePool, requiredSize int64) []*StoragePool {
	var available []*StoragePool

	for _, pool := range pools {
		pool.mu.RLock()
		enabled := pool.Enabled
		availableSize := pool.MaxSize - pool.CurrentSize
		autoThreshold := pool.AutoDisableThreshold
		current := pool.CurrentSize
		maxSize := pool.MaxSize
		pool.mu.RUnlock()

		if enabled && availableSize >= requiredSize {
			usedRatio := float64(current) / float64(maxSize)
			if usedRatio < autoThreshold {
				available = append(available, pool)
			}
		}
	}

	return available
}

// selectLeastLoadedPool 选择负载最小的存储池
func selectLeastLoadedPool(pools []*StoragePool) *StoragePool {
	if len(pools) == 0 {
		return nil
	}

	bestPool := pools[0]
	bestPool.mu.RLock()
	bestRatio := float64(bestPool.CurrentSize) / float64(bestPool.MaxSize)
	bestPool.mu.RUnlock()

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

// applyDelta 更新内存中的使用量
func (sp *StoragePool) applyDelta(delta int64) {
	sp.mu.Lock()
	defer sp.mu.Unlock()

	sp.CurrentSize += delta
	if sp.CurrentSize < 0 {
		sp.CurrentSize = 0
	}
}

// refreshActualUsage 从文件系统重新计算使用量
func (sp *StoragePool) refreshActualUsage() error {
	if sp.Path == "" {
		return nil
	}

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

	sp.mu.Lock()
	sp.CurrentSize = totalSize
	sp.mu.Unlock()
	return nil
}

// convertModelToPool 将数据库模型转换为缓存对象
func convertModelToPool(model *models.StoragePool) (*StoragePool, error) {
	if model.StorageType == "local" && model.LocalPath == "" {
		return nil, fmt.Errorf("local storage pool %s missing local_path", model.UUID)
	}

	if model.StorageType == "local" {
		if err := os.MkdirAll(model.LocalPath, 0755); err != nil {
			return nil, fmt.Errorf("create pool directory %s: %w", model.LocalPath, err)
		}
	}

	return &StoragePool{
		UUID:                 model.UUID,
		Name:                 model.Name,
		Path:                 model.LocalPath,
		MaxSize:              model.MaxSize,
		CurrentSize:          model.CurrentSize,
		Priority:             model.Priority,
		Enabled:              model.Enabled,
		AutoDisableThreshold: model.AutoDisableThreshold,
		Status:               model.Status,
		LastCheckedAt:        model.LastCheckedAt,
	}, nil
}

type poolManagerSettings struct {
	deltaChannelSize     int
	deltaBatchSize       int
	flushInterval        time.Duration
	cacheRefreshInterval time.Duration
	reconcileInterval    time.Duration
}

func normalizePoolManagerConfig(cfg *modules.PoolManagerConfig) poolManagerSettings {
	if cfg == nil {
		return poolManagerSettings{
			deltaChannelSize:     defaultDeltaChannelSize,
			deltaBatchSize:       defaultDeltaBatchSize,
			flushInterval:        defaultFlushInterval,
			cacheRefreshInterval: defaultCacheRefreshInterval,
			reconcileInterval:    0,
		}
	}

	settings := poolManagerSettings{
		deltaChannelSize:     cfg.DeltaChannelSize,
		deltaBatchSize:       cfg.DeltaBatchSize,
		flushInterval:        cfg.FlushInterval.Duration(),
		cacheRefreshInterval: cfg.CacheRefreshInterval.Duration(),
		reconcileInterval:    cfg.ReconcileInterval.Duration(),
	}

	if settings.deltaChannelSize <= 0 {
		settings.deltaChannelSize = defaultDeltaChannelSize
	}
	if settings.deltaBatchSize <= 0 {
		settings.deltaBatchSize = defaultDeltaBatchSize
	}
	if settings.flushInterval <= 0 {
		settings.flushInterval = defaultFlushInterval
	}
	if settings.cacheRefreshInterval <= 0 {
		settings.cacheRefreshInterval = defaultCacheRefreshInterval
	}
	if settings.reconcileInterval < 0 {
		settings.reconcileInterval = 0
	}

	return settings
}
