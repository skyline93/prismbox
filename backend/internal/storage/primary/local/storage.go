package local

import (
	"context"
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"

	"github.com/album/backend/internal/config/modules"
	"github.com/album/backend/internal/storage/interfaces"
	"github.com/album/backend/internal/storage/primary/local/processor"
	"github.com/album/backend/pkg/logger"
	"github.com/google/uuid"
)

// LocalStorage 本地存储实现
type LocalStorage struct {
	basePath     string
	pathResolver *PathResolver
	poolManager  *PoolManager
	cacheManager *CacheManager
	tempManager  *TempFileManager
	pipeline     *processor.ProcessingPipeline
	log          logger.Logger
}

// NewLocalStorage 创建本地存储（公开函数，供factory调用）
func NewLocalStorage(cfg *modules.LocalStorageConfig) (interfaces.PrimaryStorage, error) {
	// 创建路径解析器
	pathResolver := NewPathResolver(cfg.BasePath)

	// 创建存储池管理器
	poolManager, err := NewPoolManager(cfg.Pools)
	if err != nil {
		return nil, fmt.Errorf("create pool manager: %w", err)
	}

	// 创建缓存管理器
	cacheManager, err := NewCacheManager(cfg.Performance)
	if err != nil {
		return nil, fmt.Errorf("create cache manager: %w", err)
	}

	// 创建临时文件管理器
	tempManager, err := NewTempFileManager(cfg.Temp)
	if err != nil {
		return nil, fmt.Errorf("create temp manager: %w", err)
	}

	// 创建处理管道
	var processors []processor.Processor
	if cfg.Processing != nil {
		if cfg.Processing.EnableCompression {
			processors = append(processors, processor.NewCompressionProcessor(cfg.Processing.CompressionLevel))
		}
		if cfg.Processing.EnableEncryption {
			processors = append(processors, processor.NewEncryptionProcessor(cfg.Processing.EncryptionKeyPath))
		}
	}
	pipeline := processor.NewProcessingPipeline(processors...)

	// 创建日志记录器
	log := logger.New("storage.primary.local")

	return &LocalStorage{
		basePath:     cfg.BasePath,
		pathResolver: pathResolver,
		poolManager:  poolManager,
		cacheManager: cacheManager,
		tempManager:  tempManager,
		pipeline:     pipeline,
		log:          log,
	}, nil
}

// Put 上传文件
func (ls *LocalStorage) Put(ctx context.Context, key string, data io.Reader, size int64, opts *interfaces.PutOptions) error {
	// 1. 选择存储池
	pool, err := ls.poolManager.SelectPool(size)
	if err != nil {
		return fmt.Errorf("select pool: %w", err)
	}

	// 2. 解析路径（从key中提取uuid和hash，或生成新的）
	uuid, hash, fileType, err := ls.pathResolver.ResolveKey(key)
	if err != nil {
		// 如果key格式不正确，生成新的uuid和hash
		uuid = generateUUID()
		// 需要先读取数据来计算hash，但数据流只能读取一次
		// 所以我们需要先读取到临时文件
		tempFile, err := os.CreateTemp("", "hash_*.tmp")
		if err != nil {
			return fmt.Errorf("create temp file for hash: %w", err)
		}
		defer os.Remove(tempFile.Name())
		defer tempFile.Close()

		written, err := io.Copy(tempFile, data)
		if err != nil {
			return fmt.Errorf("copy data for hash: %w", err)
		}

		// 计算hash
		tempFile.Seek(0, 0)
		hash = generateHash(tempFile)

		// 重置文件指针
		tempFile.Seek(0, 0)
		data = tempFile

		fileType = interfaces.FileTypeOriginal
		if opts != nil {
			fileType = opts.FileType
		}
		size = written
	}

	// 3. 解析文件路径
	filePath, err := ls.pathResolver.ResolveFilePath(uuid, hash, fileType)
	if err != nil {
		return fmt.Errorf("resolve file path: %w", err)
	}

	// 4. 处理数据（如果需要）
	var processedData io.ReadCloser
	if opts != nil && len(opts.Processors) > 0 {
		processedData, err = ls.pipeline.Process(ctx, data)
		if err != nil {
			return fmt.Errorf("process data: %w", err)
		}
		defer processedData.Close()
		data = processedData
	}

	// 5. 确保目录存在
	fullPath := filepath.Join(pool.Path, filePath)
	if err := os.MkdirAll(filepath.Dir(fullPath), 0755); err != nil {
		return fmt.Errorf("create directory: %w", err)
	}

	// 6. 写入文件
	file, err := os.Create(fullPath)
	if err != nil {
		return fmt.Errorf("create file: %w", err)
	}
	defer file.Close()

	written, err := io.Copy(file, data)
	if err != nil {
		os.Remove(fullPath)
		return fmt.Errorf("write file: %w", err)
	}

	// 7. 更新存储池使用量
	pool.AddSize(written)

	ls.log.Info("file uploaded",
		logger.String("key", key),
		logger.String("path", fullPath),
		logger.Int64("size", written),
		logger.String("pool_id", pool.ID),
	)

	return nil
}

// Get 获取文件
func (ls *LocalStorage) Get(ctx context.Context, key string) (io.ReadCloser, error) {
	// 1. 解析key
	uuid, hash, fileType, err := ls.pathResolver.ResolveKey(key)
	if err != nil {
		return nil, fmt.Errorf("resolve key: %w", err)
	}

	// 2. 解析文件路径
	filePath, err := ls.pathResolver.ResolveFilePath(uuid, hash, fileType)
	if err != nil {
		return nil, fmt.Errorf("resolve file path: %w", err)
	}

	// 3. 查找文件（在所有存储池中）
	for _, pool := range ls.poolManager.pools {
		fullPath := filepath.Join(pool.Path, filePath)
		if _, err := os.Stat(fullPath); err == nil {
			file, err := os.Open(fullPath)
			if err != nil {
				continue
			}
			return file, nil
		}
	}

	return nil, fmt.Errorf("file not found: %s", key)
}

// Delete 删除文件
func (ls *LocalStorage) Delete(ctx context.Context, key string) error {
	// 1. 解析key
	uuid, hash, fileType, err := ls.pathResolver.ResolveKey(key)
	if err != nil {
		return fmt.Errorf("resolve key: %w", err)
	}

	// 2. 解析文件路径
	filePath, err := ls.pathResolver.ResolveFilePath(uuid, hash, fileType)
	if err != nil {
		return fmt.Errorf("resolve file path: %w", err)
	}

	// 3. 查找并删除文件（在所有存储池中）
	var deleted bool
	for _, pool := range ls.poolManager.pools {
		fullPath := filepath.Join(pool.Path, filePath)
		info, err := os.Stat(fullPath)
		if err != nil {
			continue
		}

		if err := os.Remove(fullPath); err != nil {
			return fmt.Errorf("remove file: %w", err)
		}

		// 更新存储池使用量
		pool.SubtractSize(info.Size())
		deleted = true
		break
	}

	if !deleted {
		return fmt.Errorf("file not found: %s", key)
	}

	ls.log.Info("file deleted",
		logger.String("key", key),
	)

	return nil
}

// Exists 检查文件是否存在
func (ls *LocalStorage) Exists(ctx context.Context, key string) (bool, error) {
	// 1. 解析key
	uuid, hash, fileType, err := ls.pathResolver.ResolveKey(key)
	if err != nil {
		return false, fmt.Errorf("resolve key: %w", err)
	}

	// 2. 解析文件路径
	filePath, err := ls.pathResolver.ResolveFilePath(uuid, hash, fileType)
	if err != nil {
		return false, fmt.Errorf("resolve file path: %w", err)
	}

	// 3. 查找文件（在所有存储池中）
	for _, pool := range ls.poolManager.pools {
		fullPath := filepath.Join(pool.Path, filePath)
		if _, err := os.Stat(fullPath); err == nil {
			return true, nil
		}
	}

	return false, nil
}

// GetSignedURL 获取签名URL（本地存储不支持，返回文件路径）
func (ls *LocalStorage) GetSignedURL(ctx context.Context, key string, duration time.Duration) (string, error) {
	// 本地存储不支持签名URL，返回文件路径
	uuid, hash, fileType, err := ls.pathResolver.ResolveKey(key)
	if err != nil {
		return "", fmt.Errorf("resolve key: %w", err)
	}

	filePath, err := ls.pathResolver.ResolveFilePath(uuid, hash, fileType)
	if err != nil {
		return "", fmt.Errorf("resolve file path: %w", err)
	}

	// 返回第一个找到的文件路径
	for _, pool := range ls.poolManager.pools {
		fullPath := filepath.Join(pool.Path, filePath)
		if _, err := os.Stat(fullPath); err == nil {
			return fullPath, nil
		}
	}

	return "", fmt.Errorf("file not found: %s", key)
}

// Copy 复制文件
func (ls *LocalStorage) Copy(ctx context.Context, srcKey, dstKey string) error {
	// 1. 读取源文件
	srcFile, err := ls.Get(ctx, srcKey)
	if err != nil {
		return fmt.Errorf("get source file: %w", err)
	}
	defer srcFile.Close()

	// 2. 获取源文件信息
	srcInfo, err := ls.Stat(ctx, srcKey)
	if err != nil {
		return fmt.Errorf("stat source file: %w", err)
	}

	// 3. 写入目标文件
	opts := &interfaces.PutOptions{
		FileType: interfaces.FileTypeOriginal,
	}
	if err := ls.Put(ctx, dstKey, srcFile, srcInfo.Size, opts); err != nil {
		return fmt.Errorf("put destination file: %w", err)
	}

	return nil
}

// Move 移动文件
func (ls *LocalStorage) Move(ctx context.Context, srcKey, dstKey string) error {
	// 1. 复制文件
	if err := ls.Copy(ctx, srcKey, dstKey); err != nil {
		return fmt.Errorf("copy file: %w", err)
	}

	// 2. 删除源文件
	if err := ls.Delete(ctx, srcKey); err != nil {
		return fmt.Errorf("delete source file: %w", err)
	}

	return nil
}

// Stat 获取文件信息
func (ls *LocalStorage) Stat(ctx context.Context, key string) (*interfaces.FileInfo, error) {
	// 1. 解析key
	uuid, hash, fileType, err := ls.pathResolver.ResolveKey(key)
	if err != nil {
		return nil, fmt.Errorf("resolve key: %w", err)
	}

	// 2. 解析文件路径
	filePath, err := ls.pathResolver.ResolveFilePath(uuid, hash, fileType)
	if err != nil {
		return nil, fmt.Errorf("resolve file path: %w", err)
	}

	// 3. 查找文件（在所有存储池中）
	for _, pool := range ls.poolManager.pools {
		fullPath := filepath.Join(pool.Path, filePath)
		info, err := os.Stat(fullPath)
		if err != nil {
			continue
		}

		return &interfaces.FileInfo{
			Key:         key,
			Size:        info.Size(),
			ModTime:     info.ModTime(),
			ContentType: "", // TODO: 根据文件扩展名推断
			Metadata:    make(map[string]string),
		}, nil
	}

	return nil, fmt.Errorf("file not found: %s", key)
}

// SelectPool 选择存储池
func (ls *LocalStorage) SelectPool(size int64) (string, error) {
	pool, err := ls.poolManager.SelectPool(size)
	if err != nil {
		return "", err
	}
	return pool.ID, nil
}

// GetPoolInfo 获取存储池信息
func (ls *LocalStorage) GetPoolInfo(poolID string) (*interfaces.PoolInfo, error) {
	return ls.poolManager.GetPoolInfo(poolID)
}

// generateUUID 生成UUID
func generateUUID() string {
	return uuid.New().String()
}

// generateHash 生成Hash（简化实现）
func generateHash(data io.Reader) string {
	hash := sha256.New()
	io.Copy(hash, data)
	return fmt.Sprintf("%x", hash.Sum(nil))
}
