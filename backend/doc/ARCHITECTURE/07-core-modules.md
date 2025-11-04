# 7. 核心模块设计

## 7.1 分层存储架构

### 7.1.1 设计原则

**核心设计理念：主存储与次存储完全解耦**

- **主存储（Primary Storage）**：用户上传文件的本地存储，同步操作，必须成功
- **次存储（Secondary Storage）**：云存储备份，异步操作，可选功能
- **完全解耦**：用户上传流程与云存储备份流程完全独立，通过后台调度器统一处理
- **延迟调度**：不在用户上传时触发备份，而是在系统空闲时批量处理

### 7.1.2 存储接口设计

#### 主存储接口（同步操作）

```go
// 主存储接口：同步操作，必须成功
type PrimaryStorage interface {
    // 基础操作
    Put(ctx context.Context, key string, data io.Reader, size int64, opts *PutOptions) error
    Get(ctx context.Context, key string) (io.ReadCloser, error)
    Delete(ctx context.Context, key string) error
    Exists(ctx context.Context, key string) (bool, error)
    GetSignedURL(ctx context.Context, key string, duration time.Duration) (string, error)
    
    // 高级操作
    Copy(ctx context.Context, srcKey, dstKey string) error
    Move(ctx context.Context, srcKey, dstKey string) error
    Stat(ctx context.Context, key string) (*FileInfo, error)
    
    // 存储池管理
    SelectPool(size int64) (string, error)  // 返回池ID
    GetPoolInfo(poolID string) (*PoolInfo, error)
}
```

#### 次存储接口（异步操作）

```go
// 次存储接口：异步操作，用于备份
type SecondaryStorage interface {
    // 异步上传（不阻塞）
    UploadAsync(ctx context.Context, key string, data io.Reader, size int64, opts *PutOptions) error
    
    // 同步上传（用于恢复等场景）
    Upload(ctx context.Context, key string, data io.Reader, size int64, opts *PutOptions) error
    
    // 下载
    Download(ctx context.Context, key string) (io.ReadCloser, error)
    
    // 删除
    Delete(ctx context.Context, key string) error
    
    // 检查上传状态
    GetUploadStatus(ctx context.Context, key string) (*UploadStatus, error)
    
    // 存储池管理
    SelectPool(size int64) (string, error)
    GetPoolInfo(poolID string) (*PoolInfo, error)
}
```

#### 存储管理器

```go
// 存储管理器：只负责主存储，不涉及云存储
type StorageManager struct {
    primary   PrimaryStorage  // 本地存储
    // 不包含 secondary 和 taskQueue
    // 云存储备份通过独立的调度器处理
}

// 用户上传流程：只写入本地存储
func (sm *StorageManager) Put(ctx context.Context, key string, data io.Reader, size int64, opts *PutOptions) error {
    // 只写入本地存储，立即返回
    return sm.primary.Put(ctx, key, data, size, opts)
}
```

### 7.1.3 存储实现

#### 主存储实现

- **local**：本地文件系统存储（主要存储）

#### 次存储实现

- **openlist**：通过 OpenList/AList 对接的云存储（备份存储）
- **s3**：AWS S3 存储（直接对接，可选）
- **oss**：阿里云 OSS 存储（直接对接，可选）
- **cos**：腾讯云 COS 存储（直接对接，可选）

### 7.1.4 存储工厂

```go
// 创建主存储
func NewPrimaryStorage(cfg StorageConfig) (PrimaryStorage, error) {
    switch cfg.Primary.Type {
    case "local":
        return local.NewStorage(cfg.Primary.Local)
    default:
        return nil, fmt.Errorf("unsupported primary storage type: %s", cfg.Primary.Type)
    }
}

// 创建次存储（可选）
func NewSecondaryStorage(cfg StorageConfig) (SecondaryStorage, error) {
    if !cfg.Secondary.Enabled {
        return nil, nil  // 未启用次存储
    }
    
    switch cfg.Secondary.Type {
    case "openlist":
        return openlist.NewStorage(cfg.Secondary.OpenList)
    case "s3":
        return s3.NewStorage(cfg.Secondary.S3)
    case "oss":
        return oss.NewStorage(cfg.Secondary.OSS)
    case "cos":
        return cos.NewStorage(cfg.Secondary.COS)
    default:
        return nil, fmt.Errorf("unsupported secondary storage type: %s", cfg.Secondary.Type)
    }
}

type PutOptions struct {
    UserID      uint
    FileType    FileType  // original, thumbnail, preview
    Processors  []string  // 处理步骤：compression, encryption
    PoolID      string    // 指定存储池
    Metadata    map[string]string
}

type FileType string
const (
    FileTypeOriginal  FileType = "original"
    FileTypeThumbnail FileType = "thumbnail"
    FileTypePreview   FileType = "preview"
    FileTypeEncrypted FileType = "encrypted"
    FileTypeCompressed FileType = "compressed"
)
```

## 7.2 存储目录结构设计（Hash-based + 用户元数据）

### 7.2.1 设计原则

**核心设计理念：文件与用户解耦，支持跨用户共享**

- **文件存储与用户解耦**：文件路径基于文件本身（UUID/Hash），不基于用户
- **权限控制在应用层**：用户关联和权限检查在数据库层和应用层实现
- **去重存储**：相同内容的文件只存储一份，支持秒传优化
- **支持跨用户共享**：用户A分享给用户B的资源，在文件系统层面是同一份文件

### 7.2.2 为什么选择 Hash-based 策略？

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

### 7.2.3 存储目录结构

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

### 7.2.4 路径解析策略

```go
// internal/storage/local/path_resolver.go
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

### 7.2.5 用户资源隔离（数据库层）

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

### 7.2.6 存储空间统计

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

## 7.3 多存储盘支持（存储池管理）

### 7.3.1 存储池配置

```yaml
storage:
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

### 7.3.2 存储池管理器

```go
// internal/storage/local/pool_manager.go
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

### 7.3.3 存储池选择策略

1. **优先级策略**：优先使用优先级高的池
2. **负载均衡**：在相同优先级下，选择最空闲的池
3. **自动禁用**：当池使用率超过阈值时，自动禁用
4. **故障转移**：当池不可用时，自动切换到其他池

## 7.4 性能优化策略

### 7.4.1 目录分区优化

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

### 7.4.2 缓存策略

```go
// internal/storage/cache/cache_manager.go
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

### 7.4.3 读写优化

- **分片读写**：大文件分片读写，避免内存占用过大
- **异步预加载**：提前加载可能访问的文件
- **批量操作**：批量上传/下载，减少网络开销
- **CDN 加速**：对于访问频繁的文件，使用 CDN 加速

## 7.5 临时文件管理

### 7.5.1 临时文件分类

```
temp/
├── uploads/      # 上传过程中的临时文件
├── processing/   # 处理过程中的临时文件
└── encryption/   # 加密处理临时文件
```

### 7.5.2 临时文件管理器

```go
// internal/storage/temp/manager.go
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

### 7.5.3 临时文件清理策略

- **自动清理**：定期清理过期文件（默认24小时）
- **空间限制**：临时目录总大小限制（默认10GB）
- **分类清理**：不同类别的临时文件可以有不同的保留时间

## 7.6 上传前处理流程

### 7.6.1 处理管道设计

```go
// internal/storage/processor/pipeline.go
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

### 7.6.2 处理步骤

1. **压缩处理**（可选）：
   - 图片压缩：降低文件大小
   - 视频压缩：降低码率

2. **加密处理**（可选）：
   - 文件加密：保护隐私
   - 密钥管理：安全存储密钥

3. **元数据提取**：
   - EXIF 信息提取
   - 媒体信息提取

### 7.6.3 处理流程

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
Storage.Put (写入最终位置)
    ↓
清理临时文件
```

## 7.7 存储层配置示例

```yaml
storage:
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

## 7.8 存储层设计总结

**核心优势**：
- ✅ **分层存储架构**：主存储与次存储完全解耦，职责清晰
- ✅ **Hash-based 存储**：文件与用户解耦，支持跨用户共享
- ✅ **多存储盘支持**：存储池管理，自动切换和故障转移
- ✅ **性能优化**：目录分区、缓存策略、读写优化
- ✅ **临时文件管理**：统一管理，自动清理，空间控制
- ✅ **上传前处理**：管道化处理，支持压缩、加密等
- ✅ **权限管理**：应用层实现，灵活可控
- ✅ **去重存储**：相同内容的文件只存储一份，节省空间
- ✅ **完全解耦**：用户上传流程与云存储备份流程完全独立
- ✅ **延迟调度**：系统空闲时批量处理，不占用高峰资源
- ✅ **OpenList 对接**：统一接入多种云存储服务，维护成本低

## 7.9 任务队列集成

### 7.9.1 任务类型

- **media:process:image**：图片处理（生成缩略图、预览图）
- **media:process:video**：视频处理（生成缩略图、预览视频）
- **media:upload:cloud**：上传到云端存储

### 7.9.2 任务处理流程

```
用户上传媒体 → 保存到本地存储 → 创建数据库记录 → 
入队处理任务 → Worker 处理（生成缩略图/预览） → 
更新数据库状态 → 入队云端上传任务 → 
Worker 上传到云端 → 更新存储位置
```

### 7.9.3 任务处理器注册

```go
// internal/worker/handler.go
func RegisterMediaProcessors(mux *gq.ServeMux, app *app.App) {
    mux.HandleFunc("media:process:image", processImageHandler(app))
    mux.HandleFunc("media:process:video", processVideoHandler(app))
    mux.HandleFunc("media:upload:cloud", uploadToCloudHandler(app))
}
```

## 7.10 媒体处理流程

### 7.10.1 图片处理

1. 读取原始图片
2. 提取 EXIF 元数据
3. 生成缩略图（400x400）
4. 生成预览图（1280px 宽度）
5. 更新数据库记录

### 7.10.2 视频处理

1. 读取原始视频
2. 提取元数据
3. 生成缩略图（从第 1 秒提取帧）
4. 生成预览视频（1280px 宽度）
5. 更新数据库记录

## 7.11 OpenList/AList 云存储对接模块

### 7.11.1 概述

OpenList/AList 存储对接模块提供了通过 OpenList/AList 统一接入多种云存储服务的能力。该模块作为次存储的一个实现，将 OpenList/AList 的 API 适配为标准的 SecondaryStorage 接口。

### 7.11.2 优缺点分析

#### 优点

1. **统一接入**：通过 OpenList/AList 统一管理多种云存储服务（S3、百度网盘、阿里云盘、OneDrive、Google Drive 等）
2. **维护成本低**：无需维护各云存储的 SDK 和认证逻辑，由 OpenList/AList 统一处理
3. **灵活性高**：支持动态添加/移除存储，配置变更无需重启
4. **轻量高效**：资源占用较低，响应速度较好
5. **开源透明**：代码可审查，降低安全风险
6. **迁移友好**：支持从 Alist 导入配置，便于迁移

#### 缺点

1. **依赖外部服务**：OpenList/AList 服务异常会影响备份功能
2. **性能损耗**：多一层 HTTP 调用，增加延迟
3. **API 兼容性**：需要适配 OpenList/AList 的 API，可能受其版本变更影响
4. **功能限制**：受限于 OpenList/AList 的能力，高级特性可能受限
5. **社区维护风险**：项目较新，长期维护需要观察

### 7.11.3 架构设计

#### 模块结构

```
internal/storage/secondary/openlist/
├── client.go          # OpenList API 客户端
├── storage.go         # SecondaryStorage 接口实现
├── adapter.go         # 路径和参数适配器
├── pool_manager.go    # 存储池管理器
├── cache.go          # 缓存管理
├── retry.go          # 重试机制
└── config.go         # 配置结构
```

#### 核心组件

**OpenListClient**：负责与 OpenList/AList 服务的 HTTP 通信

```go
type OpenListClient struct {
    baseURL    string
    apiKey     string
    httpClient *http.Client
    cache      *Cache
    retry      *RetryPolicy
}

// 核心方法
func (c *OpenListClient) ListDrivers(ctx context.Context) ([]Driver, error)
func (c *OpenListClient) GetStorage(ctx context.Context, driverID string) (*StorageInfo, error)
func (c *OpenListClient) UploadFile(ctx context.Context, driverID, path string, data io.Reader) error
func (c *OpenListClient) DownloadFile(ctx context.Context, driverID, path string) (io.ReadCloser, error)
func (c *OpenListClient) DeleteFile(ctx context.Context, driverID, path string) error
func (c *OpenListClient) ListFiles(ctx context.Context, driverID, path string) ([]FileInfo, error)
```

**OpenListStorage**：实现 SecondaryStorage 接口，适配 OpenList/AList API

```go
type OpenListStorage struct {
    client     *OpenListClient
    poolMgr    *PoolManager
    adapter    *PathAdapter
    config     *Config
}

func (s *OpenListStorage) Upload(ctx context.Context, key string, data io.Reader, size int64, opts *PutOptions) error {
    // 1. 选择存储池（驱动）
    poolID, err := s.poolMgr.SelectPool(size)
    if err != nil {
        return err
    }
    
    // 2. 路径适配
    openlistPath := s.adapter.AdaptPath(key, opts)
    
    // 3. 上传文件
    return s.client.UploadFile(ctx, poolID, openlistPath, data)
}
```

**PathAdapter**：路径适配器，处理内部路径与 OpenList/AList 路径的转换

```go
type PathAdapter struct {
    basePath string
    mapping  map[string]string  // 虚拟路径映射
}

func (a *PathAdapter) AdaptPath(internalPath string, opts *PutOptions) string {
    // Hash-based 路径转换为 OpenList 路径
    // 例如: files/ab/cd/uuid.jpg -> /album/files/ab/cd/uuid.jpg
    return filepath.Join(a.basePath, internalPath)
}

func (a *PathAdapter) ResolvePath(openlistPath string) string {
    // OpenList 路径转换为内部路径
    return strings.TrimPrefix(openlistPath, a.basePath)
}
```

**PoolManager**：存储池管理器，管理 OpenList/AList 的多个存储驱动

```go
type PoolManager struct {
    pools     map[string]*StoragePool
    mu        sync.RWMutex
    selector  PoolSelector
}

type StoragePool struct {
    ID          string      // 对应 OpenList 的 Driver ID
    Name        string
    Type        string      // 存储类型：s3, baidu, aliyun, etc.
    MaxSize     int64
    CurrentSize int64
    Priority    int
    Enabled     bool
    Config      *DriverConfig
}

func (pm *PoolManager) SelectPool(requiredSize int64) (string, error) {
    // 根据大小、优先级、负载均衡策略选择存储池
}
```

### 7.11.4 对接重点难点

#### 重点

1. **API 接口适配**
   - 理解 OpenList/AList 的 REST API
   - 适配现有的 SecondaryStorage 接口规范
   - 处理认证和授权

2. **存储池映射**
   - 将 OpenList/AList 的存储驱动映射为存储池
   - 支持多存储池配置
   - 实现存储池选择策略

3. **路径映射**
   - 内部 Hash-based 路径与 OpenList/AList 路径的转换
   - 虚拟路径与实际路径的映射
   - 跨存储的文件操作

4. **错误处理与重试**
   - 网络异常处理
   - OpenList/AList 服务异常处理
   - 重试机制

#### 难点

1. **路径映射复杂性**
   - OpenList/AList 路径与内部 Hash-based 路径映射
   - 虚拟路径与实际路径转换
   - 跨存储的文件操作

2. **认证与授权**
   - OpenList/AList 的认证机制
   - Token 管理与刷新
   - 权限传递与检查

3. **数据一致性**
   - 多存储服务的数据同步
   - 文件元数据一致性
   - 删除操作的级联处理

4. **异常恢复**
   - OpenList/AList 服务中断后的恢复
   - 文件上传失败的处理
   - 数据一致性修复

### 7.11.5 配置设计

```yaml
storage:
  secondary:
    enabled: true
    type: "openlist"
    openlist:
      # OpenList 服务配置
      base_url: "http://openlist:5244"
      api_key: "your-api-key"
      
      # 连接配置
      timeout: 30s
      max_retries: 3
      retry_backoff: 1s
      
      # 连接池配置
      max_connections: 100
      idle_timeout: 90s
      
      # 缓存配置
      cache:
        enabled: true
        ttl: 5m
        max_size: 100MB
      
      # 存储池配置（对应 OpenList 的 Drivers）
      pools:
        - id: "s3-backup"
          name: "S3 备份存储"
          driver_id: "s3-driver-1"
          type: "s3"
          max_size: "10TB"
          priority: 1
          enabled: true
        - id: "baidu-cloud"
          name: "百度网盘"
          driver_id: "baidu-driver-1"
          type: "baidu"
          max_size: "2TB"
          priority: 2
          enabled: true
        - id: "aliyun-drive"
          name: "阿里云盘"
          driver_id: "aliyun-driver-1"
          type: "aliyun"
          max_size: "1TB"
          priority: 3
          enabled: true
      
      # 路径映射
      path_mapping:
        base_path: "/album"
        virtual_paths:
          - virtual: "/files"
            physical: "/album/files"
```

## 7.12 备份调度器模块

### 7.12.1 概述

备份调度器模块负责在系统空闲时批量处理待备份文件，将本地存储的文件上传到云存储。该模块与用户上传流程完全解耦，通过后台调度器统一处理。

### 7.12.2 设计原则

- **完全解耦**：用户上传流程与云存储备份流程完全独立
- **延迟调度**：不在用户上传时触发备份，而是在系统空闲时批量处理
- **批量处理**：在系统空闲时批量处理多个文件，提高效率
- **状态管理**：通过数据库记录文件的备份状态

### 7.12.3 数据库模型设计

```go
// 媒体文件模型（扩展）
type Media struct {
    gorm.Model
    
    UUID        string
    Hash        string
    UserID      uint
    FileSize    int64
    
    // 存储信息
    LocalPath   string  // 本地存储路径
    CloudPath   string  // 云存储路径（备份完成后）
    
    // 备份状态
    BackupStatus    string  // pending, processing, completed, failed
    BackupStartedAt *time.Time
    BackupCompletedAt *time.Time
    BackupError     string
    
    // 其他字段...
}
```

### 7.12.4 架构设计

#### 备份调度器

```go
// 备份调度器：独立的后台服务
type BackupScheduler struct {
    db          *gorm.DB
    cloudStorage SecondaryStorage
    taskQueue   *gq.Client
    
    // 调度配置
    scanInterval    time.Duration  // 扫描间隔
    batchSize       int            // 批量处理大小
    idleThreshold   float64        // 系统空闲阈值
    maxConcurrency  int            // 最大并发数
    
    // 系统监控
    systemMonitor   *SystemMonitor
}

// 调度器运行
func (bs *BackupScheduler) Run(ctx context.Context) {
    ticker := time.NewTicker(bs.scanInterval)
    defer ticker.Stop()
    
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            // 检查系统是否空闲
            if bs.isSystemIdle() {
                // 系统空闲时，批量处理待备份文件
                bs.processBatch(ctx)
            }
        }
    }
}

// 批量处理待备份文件
func (bs *BackupScheduler) processBatch(ctx context.Context) error {
    // 1. 查询待备份的文件（按优先级、时间排序）
    var medias []Media
    err := bs.db.WithContext(ctx).
        Where("backup_status = ?", "pending").
        Order("created_at ASC").  // 优先处理旧文件
        Limit(bs.batchSize).
        Find(&medias).Error
    
    if err != nil {
        return err
    }
    
    if len(medias) == 0 {
        return nil  // 没有待备份文件
    }
    
    // 2. 批量创建备份任务（低优先级）
    for _, media := range medias {
        // 更新状态为 processing
        bs.db.Model(&media).Update("backup_status", "processing")
        
        // 创建备份任务
        task := &gq.Task{
            Type: "storage:backup:upload",
            Payload: marshalBackupPayload(&media),
        }
        
        // 低优先级，延迟执行
        bs.taskQueue.Enqueue(ctx, task,
            gq.Queue("backup"),
            gq.Priority(1),  // 低优先级
            gq.ProcessAt(time.Now().Add(5*time.Minute)),  // 延迟5分钟执行
        )
    }
    
    return nil
}
```

#### 系统空闲检测

```go
// 系统监控器
type SystemMonitor struct {
    cpuUsage    float64
    memoryUsage float64
    diskIO      float64
    networkIO   float64
}

// 判断系统是否空闲
func (bs *BackupScheduler) isSystemIdle() bool {
    monitor := bs.systemMonitor
    
    // 检查系统资源使用率
    return monitor.CPUUsage < bs.idleThreshold &&
           monitor.MemoryUsage < bs.idleThreshold &&
           monitor.DiskIO < bs.idleThreshold &&
           monitor.NetworkIO < bs.idleThreshold
}

// 定时收集系统指标
func (sm *SystemMonitor) CollectMetrics(ctx context.Context) {
    ticker := time.NewTicker(10 * time.Second)
    defer ticker.Stop()
    
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            sm.cpuUsage = getCPUUsage()
            sm.memoryUsage = getMemoryUsage()
            sm.diskIO = getDiskIO()
            sm.networkIO = getNetworkIO()
        }
    }
}
```

#### 备份任务处理器

```go
// 备份任务处理器
func BackupUploadHandler(ctx context.Context, task *gq.Task) error {
    var payload BackupTaskPayload
    if err := json.Unmarshal(task.Payload, &payload); err != nil {
        return err
    }
    
    // 1. 查询媒体文件信息
    var media Media
    if err := db.First(&media, "uuid = ?", payload.MediaUUID).Error; err != nil {
        return err
    }
    
    // 2. 从本地存储读取文件
    localStorage := getLocalStorage()
    reader, err := localStorage.Get(ctx, media.LocalPath)
    if err != nil {
        return fmt.Errorf("failed to read from local storage: %w", err)
    }
    defer reader.Close()
    
    // 3. 上传到云存储
    cloudStorage := getCloudStorage()
    cloudPath := adaptPath(media.LocalPath)
    
    if err := cloudStorage.Upload(ctx, cloudPath, reader, media.FileSize, nil); err != nil {
        // 更新状态为 failed
        db.Model(&media).Updates(map[string]interface{}{
            "backup_status": "failed",
            "backup_error":  err.Error(),
        })
        return err
    }
    
    // 4. 更新状态为 completed
    now := time.Now()
    db.Model(&media).Updates(map[string]interface{}{
        "backup_status":      "completed",
        "cloud_path":          cloudPath,
        "backup_completed_at": &now,
    })
    
    return nil
}
```

### 7.12.5 配置设计

```yaml
storage:
  backup:
    enabled: true
    scheduler:
      scan_interval: "5m"        # 扫描间隔：5分钟
      batch_size: 100            # 批量处理大小：100个文件
      idle_threshold: 0.3        # 系统空闲阈值：30%
      max_concurrency: 5         # 最大并发数：5
      delay_execution: "5m"      # 延迟执行：5分钟
    
    # 备份策略
    strategy:
      priority: 1                # 低优先级
      retry_times: 3             # 重试次数
      retry_interval: "10m"      # 重试间隔：10分钟
      max_age: "24h"              # 最大等待时间：24小时
```

### 7.12.6 监控和日志

```go
// 监控指标
type BackupMetrics struct {
    PendingCount    prometheus.Gauge    // 待备份文件数
    ProcessingCount prometheus.Gauge    // 处理中文件数
    CompletedCount  prometheus.Counter  // 已完成文件数
    FailedCount     prometheus.Counter  // 失败文件数
    UploadDuration  prometheus.Histogram // 上传耗时
    UploadSize      prometheus.Histogram // 上传大小
}
```

