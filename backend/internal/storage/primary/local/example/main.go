package main

import (
	"context"
	"fmt"
	"io"
	"path/filepath"
	"strings"
	"time"

	"github.com/album/backend/internal/config/types"
	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/internal/storage/config"
	"github.com/album/backend/internal/storage/primary/local"
	"github.com/album/backend/pkg/logger"
)

func main() {
	// 初始化日志
	logger.Init(&logger.Config{
		Level:  "info",
		Format: "console",
		Output: "stdout",
	})

	// 创建配置（使用 storage/config 唯一定义；DataDir 须为绝对路径）
	dataDir, _ := filepath.Abs("./data")
	cfg := &config.LocalStorageConfig{
		DataDir: dataDir,
		PoolManager: &config.PoolManagerConfig{
			DeltaChannelSize:     16,
			DeltaBatchSize:       4,
			FlushInterval:        types.Duration(1 * time.Second),
			CacheRefreshInterval: types.Duration(10 * time.Second),
			ReconcileInterval:    types.Duration(0),
		},
		Temp: &config.TempFileConfig{
			BasePath:        "./data/temp",
			MaxAge:          types.Duration(24 * time.Hour),
			MaxSize:         types.Size(10 * 1024 * 1024), // 10MB
			CleanupInterval: types.Duration(1 * time.Hour),
		},
		Performance: &config.PerformanceConfig{
			CacheEnabled: true,
			CacheSize:    types.Size(100 * 1024 * 1024), // 100MB
			CacheTTL:     types.Duration(24 * time.Hour),
		},
	}

	// 创建本地存储
	mockRepo := newMockPoolRepo()

	localStorage, err := local.NewLocalStorage(cfg, mockRepo)
	if err != nil {
		panic(fmt.Sprintf("创建本地存储失败: %v", err))
	}

	// 创建存储管理器
	storageManager := storage.NewStorageManager(localStorage)

	// 示例1: 上传文件
	demonstratePut(storageManager)

	// 示例2: 获取文件
	demonstrateGet(storageManager)

	// 示例3: 检查文件是否存在
	demonstrateExists(storageManager)

	// 示例4: 获取文件信息
	demonstrateStat(storageManager)

	// 示例5: 删除文件
	demonstrateDelete(storageManager)

	// 示例6: 存储池管理
	demonstratePoolManagement(localStorage)
}

// mockPoolRepo 是一个简单的内存实现，方便示例运行
type mockPoolRepo struct {
	pools map[string]*models.StoragePool
}

func newMockPoolRepo() *mockPoolRepo {
	return &mockPoolRepo{
		pools: map[string]*models.StoragePool{
			"pool-1": {
				UUID:                 "pool-1",
				Name:                 "pool-1",
				StorageType:          "local",
				Location:             "local:///./pool-1-path",
				MaxSize:              1024 * 1024 * 1024,
				CurrentSize:          0,
				Priority:             1,
				Enabled:              true,
				AutoDisableThreshold: 0.9,
				Status:               "active",
			},
		},
	}
}

func (m *mockPoolRepo) FindEnabledByStorageType(ctx context.Context, storageType string) ([]*models.StoragePool, error) {
	var result []*models.StoragePool
	for _, pool := range m.pools {
		if pool.StorageType == storageType && pool.Enabled && pool.Status == "active" {
			result = append(result, pool)
		}
	}
	return result, nil
}

func (m *mockPoolRepo) List(ctx context.Context, filter repository.StoragePoolFilter) ([]*models.StoragePool, error) {
	var result []*models.StoragePool
	for _, pool := range m.pools {
		if filter.StorageType != "" && pool.StorageType != filter.StorageType {
			continue
		}
		if filter.Status != "" && pool.Status != filter.Status {
			continue
		}
		result = append(result, pool)
	}
	return result, nil
}

func (m *mockPoolRepo) FindByUUID(ctx context.Context, uuid string) (*models.StoragePool, error) {
	pool, ok := m.pools[uuid]
	if !ok {
		return nil, fmt.Errorf("pool not found: %s", uuid)
	}
	return pool, nil
}

func (m *mockPoolRepo) Create(ctx context.Context, pool *models.StoragePool) error {
	m.pools[pool.UUID] = pool
	return nil
}

func (m *mockPoolRepo) UpdateByUUID(ctx context.Context, uuid string, updates map[string]interface{}) error {
	pool, ok := m.pools[uuid]
	if !ok {
		return fmt.Errorf("pool not found: %s", uuid)
	}
	for k, v := range updates {
		switch k {
		case "name":
			pool.Name = v.(string)
		case "location":
			pool.Location = v.(string)
		case "description":
			pool.Description = v.(string)
		case "max_size":
			pool.MaxSize = v.(int64)
		case "priority":
			pool.Priority = v.(int)
		case "enabled":
			pool.Enabled = v.(bool)
		case "auto_disable_threshold":
			pool.AutoDisableThreshold = v.(float64)
		}
	}
	return nil
}

func (m *mockPoolRepo) SetEnabled(ctx context.Context, uuid string, enabled bool) error {
	pool, ok := m.pools[uuid]
	if !ok {
		return fmt.Errorf("pool not found: %s", uuid)
	}
	pool.Enabled = enabled
	return nil
}

func (m *mockPoolRepo) IncrementCurrentSize(ctx context.Context, poolUUID string, delta int64) error {
	pool, ok := m.pools[poolUUID]
	if !ok {
		return fmt.Errorf("pool not found: %s", poolUUID)
	}
	pool.CurrentSize += delta
	return nil
}

func (m *mockPoolRepo) UpdateCurrentSize(ctx context.Context, poolUUID string, size int64) error {
	pool, ok := m.pools[poolUUID]
	if !ok {
		return fmt.Errorf("pool not found: %s", poolUUID)
	}
	pool.CurrentSize = size
	return nil
}

func (m *mockPoolRepo) UpdateState(ctx context.Context, poolUUID string, enabled bool, status string, currentSize int64, lastCheckedAt *time.Time) error {
	pool, ok := m.pools[poolUUID]
	if !ok {
		return fmt.Errorf("pool not found: %s", poolUUID)
	}
	pool.Enabled = enabled
	pool.Status = status
	pool.CurrentSize = currentSize
	pool.LastCheckedAt = lastCheckedAt
	return nil
}

func (m *mockPoolRepo) FindUsage(ctx context.Context, poolUUID string) ([]repository.StoragePoolUsageRow, error) {
	var rows []repository.StoragePoolUsageRow
	for _, pool := range m.pools {
		if poolUUID != "" && pool.UUID != poolUUID {
			continue
		}
		rows = append(rows, repository.StoragePoolUsageRow{
			UUID:          pool.UUID,
			DatabaseSize:  pool.CurrentSize,
			ActualSize:    pool.CurrentSize,
			LastCheckedAt: pool.LastCheckedAt,
		})
	}
	return rows, nil
}

// demonstratePut 演示上传文件
func demonstratePut(sm *storage.StorageManager) {
	fmt.Println("\n=== 示例1: 上传文件 ===")

	ctx := context.Background()
	key := "ab/cd/test-uuid.jpg"
	data := strings.NewReader("这是测试文件内容")
	size := int64(len("这是测试文件内容"))

	opts := &storage.PutOptions{
		UserID:    1,
		Extension: "jpg",
		Variant:   "", // 原始文件，无变体
		Metadata: map[string]string{
			"content_type": "image/jpeg",
			"upload_time":  time.Now().Format(time.RFC3339),
		},
	}

	if err := sm.Put(ctx, key, data, size, opts); err != nil {
		fmt.Printf("上传失败: %v\n", err)
		return
	}

	fmt.Printf("文件上传成功: %s\n", key)
}

// demonstrateGet 演示获取文件
func demonstrateGet(sm *storage.StorageManager) {
	fmt.Println("\n=== 示例2: 获取文件 ===")

	ctx := context.Background()
	key := "ab/cd/test-uuid.jpg"

	reader, err := sm.Get(ctx, key)
	if err != nil {
		fmt.Printf("获取文件失败: %v\n", err)
		return
	}
	defer reader.Close()

	data, err := io.ReadAll(reader)
	if err != nil {
		fmt.Printf("读取文件失败: %v\n", err)
		return
	}

	fmt.Printf("文件内容: %s\n", string(data))
}

// demonstrateExists 演示检查文件是否存在
func demonstrateExists(sm *storage.StorageManager) {
	fmt.Println("\n=== 示例3: 检查文件是否存在 ===")

	ctx := context.Background()
	key := "ab/cd/test-uuid.jpg"

	exists, err := sm.Exists(ctx, key)
	if err != nil {
		fmt.Printf("检查文件失败: %v\n", err)
		return
	}

	fmt.Printf("文件是否存在: %v\n", exists)
}

// demonstrateStat 演示获取文件信息
func demonstrateStat(sm *storage.StorageManager) {
	fmt.Println("\n=== 示例4: 获取文件信息 ===")

	ctx := context.Background()
	key := "ab/cd/test-uuid.jpg"

	info, err := sm.Stat(ctx, key)
	if err != nil {
		fmt.Printf("获取文件信息失败: %v\n", err)
		return
	}

	fmt.Printf("文件信息:\n")
	fmt.Printf("  Key: %s\n", info.Key)
	fmt.Printf("  Size: %d bytes\n", info.Size)
	fmt.Printf("  ModTime: %s\n", info.ModTime.Format(time.RFC3339))
	fmt.Printf("  ContentType: %s\n", info.ContentType)
}

// demonstrateDelete 演示删除文件
func demonstrateDelete(sm *storage.StorageManager) {
	fmt.Println("\n=== 示例5: 删除文件 ===")

	ctx := context.Background()
	key := "ab/cd/test-uuid.jpg"

	if err := sm.Delete(ctx, key); err != nil {
		fmt.Printf("删除文件失败: %v\n", err)
		return
	}

	fmt.Printf("文件删除成功: %s\n", key)
}

// demonstratePoolManagement 演示存储池管理
func demonstratePoolManagement(ps storage.PrimaryStorage) {
	fmt.Println("\n=== 示例6: 存储池管理 ===")

	// 选择存储池
	poolID, err := ps.SelectPool(1024 * 1024) // 1MB
	if err != nil {
		fmt.Printf("选择存储池失败: %v\n", err)
		return
	}

	fmt.Printf("选择的存储池: %s\n", poolID)

	// 获取存储池信息
	poolInfo, err := ps.GetPoolInfo(poolID)
	if err != nil {
		fmt.Printf("获取存储池信息失败: %v\n", err)
		return
	}

	fmt.Printf("存储池信息:\n")
	fmt.Printf("  ID: %s\n", poolInfo.ID)
	fmt.Printf("  Path: %s\n", poolInfo.Path)
	fmt.Printf("  MaxSize: %d bytes\n", poolInfo.MaxSize)
	fmt.Printf("  CurrentSize: %d bytes\n", poolInfo.CurrentSize)
	fmt.Printf("  Priority: %d\n", poolInfo.Priority)
	fmt.Printf("  Enabled: %v\n", poolInfo.Enabled)
}
