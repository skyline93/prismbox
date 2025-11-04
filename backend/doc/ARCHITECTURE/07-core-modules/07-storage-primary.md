# 7.2 主存储设计（本地存储）

## 7.2.1 存储目录结构设计（Hash-based + 用户元数据）

### 设计原则

**核心设计理念：文件与用户解耦，支持跨用户共享**

- **文件存储与用户解耦**：文件路径基于文件本身（UUID/Hash），不基于用户
- **权限控制在应用层**：用户关联和权限检查在数据库层和应用层实现
- **去重存储**：相同内容的文件只存储一份，支持秒传优化
- **支持跨用户共享**：用户A分享给用户B的资源，在文件系统层面是同一份文件

### 为什么选择 Hash-based 策略？

**问题场景**：
- 用户A上传了 photo1.jpg，分享给用户B
- 如果按用户ID目录隔离，文件在 `user_1/` 下，用户B需要跨目录访问
- 需要处理权限、软链接、重复存储等问题

**Hash-based 策略的优势**：
1. ✅ **支持跨用户共享**：文件路径不包含用户ID，支持多用户访问同一文件
2. ✅ **秒传优化**：相同Hash的文件在同一位置，易于实现秒传
3. ✅ **目录分布均匀**：避免单目录文件过多，提高文件系统性能
4. ✅ **权限管理简单**：在应用层实现，不依赖文件系统权限
5. ✅ **去重存储**：相同内容的文件只存储一份，节省空间

### 存储目录结构

```
uploads/
├── files/                    # 文件存储根目录（Hash-based，与用户解耦）
│   ├── {hash[0:2]}/         # Hash前2位（00-ff，共256个目录）
│   │   ├── {hash[2:4]}/     # Hash 3-4位（00-ff，共256个目录）
│   │   │   ├── {uuid}.jpg              # 原始文件
│   │   │   ├── {uuid}_thumb.jpg       # 缩略图
│   │   │   └── {uuid}_prev.jpg        # 预览图
│   │   │
│   ├── ab/                   # 示例：hash前缀为 "ab"
│   │   ├── cd/               # hash 3-4位为 "cd"
│   │   │   ├── abc-123.jpg
│   │   │   ├── abc-123_thumb.jpg
│   │   │   └── abc-123_prev.jpg
│
├── temp/                     # 临时文件目录
│   ├── uploads/              # 上传过程中的临时文件
│   │   └── {upload_id}.tmp
│   ├── processing/           # 处理过程中的临时文件
│   │   └── {uuid}_processing.tmp
│   └── encryption/           # 加密处理临时文件
│       └── {uuid}_encrypted.tmp
│
├── staging/                   # 待上传到云端的文件
│   ├── {hash[0:2]}/
│   │   └── {uuid}.jpg
│
└── cache/                     # 缓存目录（可选）
    ├── thumbnails/            # 缩略图缓存
    └── previews/              # 预览图缓存
```

**目录结构说明**：
- `files/`：实际文件存储，使用Hash前缀分区（2级目录，共65536个目录）
- `temp/`：临时文件，按用途分类（uploads、processing、encryption）
- `staging/`：待上传到云端的文件，使用Hash前缀分区
- `cache/`：缓存文件，用于性能优化

### 路径解析策略

```go
// internal/storage/primary/local/path_resolver.go
type PathResolver struct {
    basePath string
}

// ResolveFilePath 解析文件路径（基于Hash，不基于用户）
func (pr *PathResolver) ResolveFilePath(uuid string, hash string, fileType FileType) string {
    // 使用Hash前缀分区（2级目录）
    hashPrefix := hash[:2]   // 前2位（00-ff）
    hashNext := hash[2:4]   // 3-4位（00-ff）
    
    basePath := filepath.Join(pr.basePath, "files", hashPrefix, hashNext)
    
    var filename string
    switch fileType {
    case FileTypeOriginal:
        filename = uuid + ".jpg"
    case FileTypeThumbnail:
        filename = uuid + "_thumb.jpg"
    case FileTypePreview:
        filename = uuid + "_prev.jpg"
    case FileTypeEncrypted:
        filename = uuid + "_encrypted.jpg"
    case FileTypeCompressed:
        filename = uuid + "_compressed.jpg"
    }
    
    return filepath.Join(basePath, filename)
}

// ResolveTempPath 解析临时文件路径（基于上传ID）
func (pr *PathResolver) ResolveTempPath(uploadID string, category string) string {
    return filepath.Join(pr.basePath, "temp", category, uploadID+".tmp")
}

// ResolveStagingPath 解析待上传文件路径（基于Hash）
func (pr *PathResolver) ResolveStagingPath(uuid string, hash string) string {
    hashPrefix := hash[:2]
    return filepath.Join(pr.basePath, "staging", hashPrefix, uuid+".jpg")
}
```

**路径解析示例**：
```
UUID: abc-123
Hash: abcd1234...
Hash前缀: ab
Hash 3-4位: cd

原始文件: files/ab/cd/abc-123.jpg
缩略图:   files/ab/cd/abc-123_thumb.jpg
预览图:   files/ab/cd/abc-123_prev.jpg
```

### 用户资源隔离（数据库层）

**关键设计**：用户关联存储在数据库层，不在文件系统层

```go
// 数据库模型
type Media struct {
    UUID string
    Hash string
    UserID uint  // 文件所有者（在数据库层）
    FileSize int64
    // ...
}

type Share struct {
    MediaID uint
    OwnerID uint      // 分享创建者
    TargetUserID *uint  // 分享目标用户（NULL表示公开分享）
    // ...
}

// 权限检查在应用层
func (s *MediaService) CanAccess(userID uint, mediaUUID string) (bool, error) {
    media, err := s.repo.FindByUUID(mediaUUID)
    if err != nil {
        return false, err
    }
    
    // 1. 是文件所有者
    if media.UserID == userID {
        return true, nil
    }
    
    // 2. 有共享关系（数据库查询）
    share, err := s.shareRepo.FindActiveShare(media.ID, userID)
    if err == nil && share != nil {
        return true, nil
    }
    
    return false, nil
}
```

**优势**：
- ✅ 文件路径不包含用户ID，支持跨用户共享
- ✅ 权限检查在应用层，灵活性高
- ✅ 共享关系在数据库层，易于管理和查询
- ✅ 删除文件时，只需检查数据库中的关联关系

### 存储空间统计

**由于文件不按用户存储，需要从数据库统计**

```go
// 用户存储空间统计（从数据库查询）
func (s *MediaService) GetUserStorageUsage(userID uint) (int64, error) {
    // 查询用户拥有的所有媒体文件
    medias, err := s.repo.FindByUserID(userID)
    if err != nil {
        return 0, err
    }
    
    var totalSize int64
    for _, media := range medias {
        totalSize += media.FileSize
    }
    
    return totalSize, nil
}

// 文件实际存储空间（从文件系统统计）
func (s *StorageService) GetStorageUsage() (int64, error) {
    // 遍历文件系统，统计实际占用空间
    // 注意：由于去重存储，可能小于数据库统计的总和
}
```

## 7.2.2 多存储盘支持（存储池管理）

### 存储池配置

```yaml
storage:
  primary:
    local:
      pools:
        - id: "pool-1"
          path: "/data/storage1"
          max_size: "1TB"
          current_size: "500GB"
          priority: 1
          enabled: true
          auto_disable_threshold: 0.9  # 90% 时自动禁用
        - id: "pool-2"
          path: "/data/storage2"
          max_size: "2TB"
          current_size: "1.5TB"
          priority: 2
          enabled: true
          auto_disable_threshold: 0.9
```

### 存储池管理器

```go
// internal/storage/primary/local/pool_manager.go
type PoolManager struct {
    pools []StoragePool
    mu    sync.RWMutex
}

type StoragePool struct {
    ID          string
    Path        string
    MaxSize     int64
    CurrentSize int64
    Priority    int
    Enabled     bool
    AutoDisableThreshold float64
}

// SelectPool 根据策略选择可用的存储池
func (pm *PoolManager) SelectPool(requiredSize int64) (*StoragePool, error) {
    pm.mu.RLock()
    defer pm.mu.RUnlock()
    
    // 1. 过滤可用的池（启用且空间充足）
    availablePools := pm.filterAvailablePools(requiredSize)
    
    if len(availablePools) == 0 {
        return nil, ErrNoAvailablePool
    }
    
    // 2. 按优先级排序
    sort.Slice(availablePools, func(i, j int) bool {
        return availablePools[i].Priority < availablePools[j].Priority
    })
    
    // 3. 选择最空闲的池（负载均衡）
    return pm.selectLeastLoadedPool(availablePools), nil
}

// CheckAndUpdatePools 定期检查存储池状态
func (pm *PoolManager) CheckAndUpdatePools() {
    for _, pool := range pm.pools {
        usedRatio := float64(pool.CurrentSize) / float64(pool.MaxSize)
        if usedRatio >= pool.AutoDisableThreshold {
            pm.DisablePool(pool.ID)
            log.Printf("Pool %s disabled due to capacity threshold", pool.ID)
        }
    }
}
```

### 存储池选择策略

1. **优先级策略**：优先使用优先级高的池
2. **负载均衡**：在相同优先级下，选择最空闲的池
3. **自动禁用**：当池使用率超过阈值时，自动禁用
4. **故障转移**：当池不可用时，自动切换到其他池

## 7.2.3 性能优化策略

### 目录分区优化

**Hash-based 分区优势**：
- 2级目录分区（256 × 256 = 65536个目录）
- 目录分布均匀，避免单目录文件过多
- 文件查找性能好（O(1) 目录查找）

**分区策略**：
```
Hash: abcd1234...
Level 1: ab (00-ff，256个目录)
Level 2: cd (00-ff，256个目录)
最终目录: files/ab/cd/
```

### 缓存策略

```go
// internal/storage/primary/local/cache/cache_manager.go
type CacheManager struct {
    // 内存缓存（LRU）
    memoryCache *lru.Cache
    
    // 磁盘缓存
    diskCachePath string
    maxDiskCacheSize int64
}

// Get 先查内存缓存，再查磁盘缓存，最后查原始文件
func (cm *CacheManager) Get(key string) (io.ReadCloser, error) {
    // 1. 内存缓存
    if data, ok := cm.memoryCache.Get(key); ok {
        return bytes.NewReader(data.([]byte)), nil
    }
    
    // 2. 磁盘缓存
    if data, err := cm.getFromDiskCache(key); err == nil {
        cm.memoryCache.Add(key, data)
        return bytes.NewReader(data), nil
    }
    
    // 3. 原始文件
    return cm.getFromOriginal(key)
}
```

### 读写优化

- **分片读写**：大文件分片读写，避免内存占用过大
- **异步预加载**：提前加载可能访问的文件
- **批量操作**：批量上传/下载，减少网络开销
- **CDN 加速**：对于访问频繁的文件，使用 CDN 加速

## 7.2.4 临时文件管理

### 临时文件分类

```
temp/
├── uploads/      # 上传过程中的临时文件
├── processing/   # 处理过程中的临时文件
└── encryption/   # 加密处理临时文件
```

### 临时文件管理器

```go
// internal/storage/primary/local/temp/manager.go
type TempFileManager struct {
    baseDir    string
    maxAge     time.Duration
    maxSize    int64
    currentSize int64
    mu         sync.Mutex
}

// CreateTempFile 创建临时文件
func (tm *TempFileManager) CreateTempFile(prefix string, category string) (*os.File, error) {
    tm.mu.Lock()
    defer tm.mu.Unlock()
    
    // 1. 清理过期文件
    tm.cleanupExpired()
    
    // 2. 检查空间
    if tm.currentSize > tm.maxSize {
        return nil, ErrTempDirFull
    }
    
    // 3. 创建临时文件
    tempDir := filepath.Join(tm.baseDir, category)
    os.MkdirAll(tempDir, 0755)
    
    file, err := os.CreateTemp(tempDir, prefix+"_*.tmp")
    if err != nil {
        return nil, err
    }
    
    // 4. 注册到管理器
    tm.registerFile(file.Name())
    
    return file, nil
}

// cleanupExpired 清理过期文件
func (tm *TempFileManager) cleanupExpired() {
    files, _ := os.ReadDir(tm.baseDir)
    for _, file := range files {
        info, _ := file.Info()
        if time.Since(info.ModTime()) > tm.maxAge {
            filePath := filepath.Join(tm.baseDir, file.Name())
            os.Remove(filePath)
            tm.currentSize -= info.Size()
        }
    }
}
```

### 临时文件清理策略

- **自动清理**：定期清理过期文件（默认24小时）
- **空间限制**：临时目录总大小限制（默认10GB）
- **分类清理**：不同类别的临时文件可以有不同的保留时间

## 7.2.5 上传前处理流程

### 处理管道设计

```go
// internal/storage/primary/local/processor/pipeline.go
type ProcessingPipeline struct {
    processors []Processor
}

type Processor interface {
    Process(ctx context.Context, input io.Reader, output io.Writer) error
    Name() string
}

// 处理步骤
type CompressionProcessor struct{}
type EncryptionProcessor struct{}
type MetadataExtractor struct{}

func (pp *ProcessingPipeline) Process(ctx context.Context, input io.Reader) (io.Reader, error) {
    var current io.Reader = input
    
    for _, processor := range pp.processors {
        // 1. 创建临时文件
        tempFile, err := createTempFile()
        if err != nil {
            return nil, err
        }
        defer os.Remove(tempFile.Name())
        
        // 2. 处理
        if err := processor.Process(ctx, current, tempFile); err != nil {
            return nil, err
        }
        
        // 3. 重置为新的输入
        tempFile.Seek(0, 0)
        current = tempFile
    }
    
    return current, nil
}
```

### 处理步骤

1. **压缩处理**（可选）：
   - 图片压缩：降低文件大小
   - 视频压缩：降低码率

2. **加密处理**（可选）：
   - 文件加密：保护隐私
   - 密钥管理：安全存储密钥

3. **元数据提取**：
   - EXIF 信息提取
   - 媒体信息提取

### 处理流程

```
客户端上传
    ↓
API Handler (接收文件)
    ↓
TempFileManager (创建临时文件)
    ↓
ProcessingPipeline (处理：压缩、加密等)
    ↓
PoolManager (选择存储池)
    ↓
PathResolver (解析路径：Hash-based)
    ↓
PrimaryStorage.Put (写入最终位置)
    ↓
清理临时文件
```

## 7.2.6 配置示例

```yaml
storage:
  primary:
    type: "local"
    local:
      base_path: "/data/uploads"
      
      # 存储池配置
      pools:
        - id: "pool-1"
          path: "/data/storage1"
          max_size: "1TB"
          priority: 1
          auto_disable_threshold: 0.9
        - id: "pool-2"
          path: "/data/storage2"
          max_size: "2TB"
          priority: 2
          auto_disable_threshold: 0.9
      
      # 临时文件配置
      temp:
        base_path: "/data/temp"
        max_age: "24h"
        max_size: "10GB"
        cleanup_interval: "1h"
      
      # 处理配置
      processing:
        enable_compression: true
        compression_level: 6
        enable_encryption: false
        encryption_key_path: "/etc/album/encryption.key"
      
      # 性能配置
      performance:
        cache_enabled: true
        cache_size: "1GB"
        cache_ttl: "24h"
        read_buffer_size: "64KB"
        write_buffer_size: "64KB"
```

