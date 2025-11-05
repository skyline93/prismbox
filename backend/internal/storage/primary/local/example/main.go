package main

import (
	"context"
	"fmt"
	"io"
	"strings"
	"time"

	"github.com/album/backend/internal/config/modules"
	"github.com/album/backend/internal/storage"
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

	// 创建配置
	cfg := &modules.LocalStorageConfig{
		BasePath: "./uploads",
		Pools: []*modules.StoragePoolConfig{
			{
				ID:                   "pool-1",
				Path:                 "./pool-1-path",
				MaxSize:              modules.Size(1024 * 1024 * 1024), // 1GB
				Priority:             1,
				Enabled:              true,
				AutoDisableThreshold: 0.9,
			},
		},
		Temp: &modules.TempFileConfig{
			BasePath:        "./temp",
			MaxAge:          modules.Duration(24 * time.Hour),
			MaxSize:         modules.Size(10 * 1024 * 1024), // 10MB
			CleanupInterval: modules.Duration(1 * time.Hour),
		},
		Performance: &modules.PerformanceConfig{
			CacheEnabled:    true,
			CacheSize:       modules.Size(100 * 1024 * 1024), // 100MB
			CacheTTL:        modules.Duration(24 * time.Hour),
			ReadBufferSize:  modules.Size(64 * 1024), // 64KB
			WriteBufferSize: modules.Size(64 * 1024), // 64KB
		},
	}

	// 创建本地存储
	localStorage, err := local.NewLocalStorage(cfg)
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

// demonstratePut 演示上传文件
func demonstratePut(sm *storage.StorageManager) {
	fmt.Println("\n=== 示例1: 上传文件 ===")

	ctx := context.Background()
	key := "ab/cd/test-uuid.jpg"
	data := strings.NewReader("这是测试文件内容")
	size := int64(len("这是测试文件内容"))

	opts := &storage.PutOptions{
		UserID:   1,
		FileType: storage.FileTypeOriginal,
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
