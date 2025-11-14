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

> **命名原则：物理文件名只与内容绑定，不携带业务 UUID。**
>
> 使用文件内容的 Hash 作为最终文件名，可彻底实现“业务 ID ↔ 文件实体”的解耦，避免泄露业务信息，同时确保去重策略始终成立。

```
uploads/
├── files/                    # 文件存储根目录（Hash-based，与用户解耦）
│   ├── {hash[0:2]}/         # Hash前2位（00-ff，共256个目录）
│   │   ├── {hash[2:4]}/     # Hash 3-4位（00-ff，共256个目录）
│   │   │   ├── {hash}.{ext}              # 原始文件（支持任意扩展名）
│   │   │   ├── {hash}_thumb.{ext}       # 缩略图
│   │   │   ├── {hash}_prev.{ext}        # 预览图
│   │   │   ├── {hash}.arw               # RAW原始文件示例
│   │   │   ├── {hash}.mp4               # 视频原始文件示例
│   │   │   └── {hash}_thumb.jpg         # 视频缩略图（jpg格式）
│   │   │
│   ├── ab/                   # 示例：hash前缀为 "ab"
│   │   ├── cd/               # hash 3-4位为 "cd"
│   │   │   ├── abcd1234...jpg           # JPG图片
│   │   │   ├── abcd1234..._thumb.jpg    # JPG缩略图
│   │   │   ├── abcd1234..._prev.jpg     # JPG预览图
│   │   │   ├── abcd1234...arw           # RAW图片
│   │   │   ├── abcd1234...mp4           # MP4视频
│   │   │   └── abcd1234..._thumb.jpg    # 视频缩略图
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
│   │   └── {hash}.{ext}      # 支持任意扩展名
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

**核心设计：存储层完全解耦，只关心 Hash + 扩展名 + 变体**

存储层不再包含业务逻辑（如 original/thumbnail/preview 等业务概念），只处理：
- **Hash**：文件内容的哈希值
- **Extension**：文件扩展名（jpg, mp4, arw 等）
- **Variant**：文件变体标识（thumb, prev 等，可选）

业务层的文件类型语义由业务层适配器处理。

```go
// internal/storage/primary/local/path_resolver.go
type PathResolver struct {
    basePath string
}

// ResolveFilePath 解析文件路径（基于 Hash + 扩展名 + 变体）
// 格式：{hash}[_variant].{extension}
func (pr *PathResolver) ResolveFilePath(hash string, extension string, variant string) (string, error) {
    // 使用Hash前缀分区（2级目录）
    hashPrefix := hash[:2]   // 前2位（00-ff）
    hashNext := hash[2:4]    // 3-4位（00-ff）
    
    basePath := filepath.Join(pr.basePath, "files", hashPrefix, hashNext)
    
    // 构建文件名：{hash}[_variant].{extension}
    var filename string
    if variant == "" {
        filename = fmt.Sprintf("%s.%s", hash, extension)
    } else {
        filename = fmt.Sprintf("%s_%s.%s", hash, variant, extension)
    }
    
    return filepath.Join(basePath, filename), nil
}

// ResolveKey 从key解析出hash、扩展名和变体
// key格式：{hash[0:2]}/{hash[2:4]}/{hash}[_variant].{ext}
func (pr *PathResolver) ResolveKey(key string) (hash string, extension string, variant string, err error) {
    // 解析逻辑：从key中提取hash、扩展名和变体
    // ...
}

// ResolveStagingPath 解析待上传文件路径（基于Hash + 扩展名）
func (pr *PathResolver) ResolveStagingPath(hash string, extension string) (string, error) {
    hashPrefix := hash[:2]
    filename := fmt.Sprintf("%s.%s", hash, extension)
    return filepath.Join(pr.basePath, "staging", hashPrefix, filename), nil
}
```

**路径解析示例**：
```
Hash: abcd1234...
Hash前缀: ab
Hash 3-4位: cd

# 图片文件
原始JPG:     files/ab/cd/abcd1234....jpg
JPG缩略图:   files/ab/cd/abcd1234...._thumb.jpg
JPG预览图:   files/ab/cd/abcd1234...._prev.jpg

# RAW文件
原始ARW:     files/ab/cd/abcd1234....arw
ARW缩略图:   files/ab/cd/abcd1234...._thumb.jpg  (RAW的缩略图是JPG)

# 视频文件
原始MP4:     files/ab/cd/abcd1234....mp4
视频缩略图:  files/ab/cd/abcd1234...._thumb.jpg  (视频缩略图是JPG)
视频预览图:  files/ab/cd/abcd1234...._prev.jpg   (视频预览图是JPG)
```

**业务层适配器**：

业务层通过适配器将业务概念映射到存储层：

```go
// internal/service/media/storage_adapter.go
type StorageAdapter struct{}

// ToStorageOptions 将业务层选项转换为存储层选项
func (a *StorageAdapter) ToStorageOptions(itemType string, mediaType MediaFileType, originalExtension string) (*PutOptions, error) {
    // 图片类型：
    // - 原始文件：保持原扩展名（jpg, png, arw等）
    // - 缩略图/预览图：统一使用jpg格式
    
    // 视频类型：
    // - 原始文件：保持原扩展名（mp4, mov等）
    // - 缩略图/预览图：使用jpg格式（视频封面）
    // ...
}
```

> **与业务标识的关系**：`Media.UUID`、分享记录等业务标识只存在于数据库层，并通过字段如 `LocalPath` 指向上述 hash 命名的物理文件。这样可以同时满足内容去重与业务隔离的诉求。

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

- **配置下放到数据库**：`storage_pools` 表描述所有主/次存储池，字段包含 `uuid`、`storage_type`、`local_path` / `cloud_config(JSON)`、`max_size`、`priority`、`auto_disable_threshold`、`status` 等。运维可以通过 Migration 或后台管理界面动态增删，应用层自动感知。
- **Media 关联**：`medias.local_pool_uuid`、`medias.cloud_pool_uuid` 记录文件实际落在哪个池，方便下载和迁移。
- **YAML 只保留 PoolManager 行为配置**：

```yaml
storage:
  primary:
    local:
      base_path: "/data/uploads"
      pool_manager:
        delta_channel_size: 1024     # 内存增量队列
        delta_batch_size: 128        # 批量落库阈值
        flush_interval: "2s"         # 定时刷盘
        cache_refresh_interval: "5m" # 定期重载数据库配置
        reconcile_interval: "1h"     # 可选：重新扫描磁盘对账，0 表示关闭
```

### 存储池管理器

```go
type PoolManager struct {
    repo        repository.StoragePoolRepository
    cache       map[string]*StoragePool
    deltaCh     chan PoolDelta         // 增量队列：pool_uuid + delta
    flushCh     chan struct{}          // 手动刷新
    stopCh      chan struct{}
    flushInterval        time.Duration
    cacheRefreshInterval time.Duration
    reconcileInterval    time.Duration
}

func (pm *PoolManager) SelectPool(requiredSize int64) (*StoragePool, error) {
    pools := pm.snapshotPools()
    available := filterAvailablePools(pools, requiredSize)
    sort.Slice(available, func(i, j int) bool {
        return available[i].Priority < available[j].Priority
    })
    return selectLeastLoadedPool(available), nil
}

func (pm *PoolManager) RecordUsage(poolUUID string, delta int64) {
    pool := pm.cache[poolUUID]
    pool.applyDelta(delta)           // 内存即时更新
    pm.deltaCh <- PoolDelta{PoolUUID: poolUUID, Delta: delta, Occurred: time.Now()}
}
```

### 内存计数 + 可靠串行持久化

1. **缓存即时更新**：每次 Put/Delete 先在内存池对象上加锁修改 `CurrentSize`，保证剩余空间判断准确。
2. **串行落库**：
   - PoolManager 内置单 goroutine worker，周期性（或 batch 满时）拉取 `deltaCh`，按池聚合后执行 `UPDATE storage_pools SET current_size = current_size + ? WHERE uuid = ?`。
   - 写库失败会把增量重新塞回队列并记录报警，确保最终一致。
3. **可控刷新**：`flush_interval`、`delta_batch_size` 可以按磁盘性能调节；Stop 或重启前会 `flushCh <- struct{}{}` 强制刷盘。
4. **多实例一致性**：每个实例独立做内存计数，但数据库层使用原子自增语句，不会互相覆盖；`cache_refresh_interval` 让各实例自动收敛配置。
5. **定期对账**：`reconcile_interval`（可选）触发全量扫描磁盘并与数据库对比，发现漂移后更新 `current_size` 和状态，保证长期准确。

```go
func (pm *PoolManager) persistDeltas(deltas map[string]int64) error {
    ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer cancel()
    for poolUUID, delta := range deltas {
        if delta == 0 {
            continue
        }
        if err := pm.repo.IncrementCurrentSize(ctx, poolUUID, delta); err != nil {
            return err
        }
    }
    return nil
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

## 7.2.7 未来特性规划

- **存储池切换（Switch-over）**  
  - 背景：单个磁盘达到阈值或需要下线维护时，需要把新的写流切到其他池。  
  - 预案：PoolManager 已支持动态禁用池并在缓存刷新后立即生效；后续将增加 API/CLI 以手动触发切换，并记录审计日志。

- **分级迁移（Migration）**  
  - 背景：需要在不停机情况下将历史文件从旧池迁往新池（容量扩缩、性能优化）。  
  - 设想流程：  
    1. 通过后台开启迁移任务，读取 `medias.local_pool_uuid = old_pool` 的记录。  
    2. 逐条复制文件到目标池，校验哈希后更新 `LocalPoolUUID` 与 `LocalPath`。  
    3. 迁移任务与 PoolManager 的 delta worker 协调（写入增量走同一 channel），确保容量统计一致。  
  - 后续会补充“迁移 window、速率控制、失败重试、任务监控”等细节。

- **多副本策略**  
  - 当前仅支持“主 + 备份”两级。未来可扩展为多副本策略（例如本地双写 + 云备份），并在 Media 模型中记录副本状态。

- **访问加速**  
  - 预留 `Cache` 层接口，可根据访问热度把热门文件同步到 SSD 池或 CDN，对应的 `StoragePool` 可标记为 `cache` 类型，PoolManager 根据策略自动放置。

## 7.2.8 已知问题与风险

1. **数据库配置与实例状态存在刷新窗口**  
   - PoolManager 周期性刷新缓存，极端情况下数据库已修改但实例尚未感知，可能在短时间内继续写入旧池。可通过手动触发 `InvalidateCache` 或缩短 `cache_refresh_interval` 缓解。

2. **增量队列过载风险**  
   - 若写入速率超过 `delta_channel_size`，会阻塞写操作。需要配合监控（队列长度、flush 延迟），并在参数中预留足够余量。

3. **Reconcile 对账成本高**  
   - 全量遍历文件系统耗时、耗 I/O。需根据业务体量设置较长周期，并在执行前通知运营窗口。

4. **数据库写失败导致容量偏移**  
   - 虽有重试机制，但长期失败会导致 `CurrentSize` 与实际使用量差距，需要通过 reconcile/告警及时处理。后续可以引入轻量 WAL 或任务队列，提高可靠性。

5. **多实例并发写导致容量抖动**  
   - 虽然数据库层使用 `current_size = current_size + ?` 原子更新，但若多个实例的内存缓存长期不刷新，可能在池被禁用后仍短暂写入。需要全局监控池状态并快速刷新。

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

