# 本地存储模块文档

## 概述

本地存储模块（Local Storage）是主存储（Primary Storage）的实现，负责将用户上传的文件存储到本地文件系统中。该模块采用 Hash-based 存储策略，支持多存储池管理、缓存优化、临时文件管理和处理管道等功能。

## 核心特性

### 1. Hash-based 存储策略

- **文件与用户解耦**：文件路径基于文件本身的 Hash 值，不包含用户ID
- **支持跨用户共享**：相同内容的文件只存储一份，支持秒传优化
- **目录分区优化**：使用2级目录分区（256 × 256 = 65536个目录），避免单目录文件过多

### 2. 多存储池管理

- **存储池选择**：根据文件大小和存储池可用空间自动选择最优存储池
- **负载均衡**：在相同优先级下，选择最空闲的存储池
- **自动禁用**：当存储池使用率超过阈值时，自动禁用该存储池
- **故障转移**：当存储池不可用时，自动切换到其他存储池

### 3. 缓存管理

- **内存缓存**：LRU 缓存，快速访问常用文件
- **磁盘缓存**：持久化缓存，减少磁盘I/O
- **自动清理**：定期清理过期缓存

### 4. 临时文件管理

- **分类管理**：按用途分类（uploads、processing、encryption）
- **自动清理**：定期清理过期临时文件
- **空间限制**：限制临时目录总大小

### 5. 处理管道

- **可扩展处理**：支持压缩、加密等处理步骤
- **管道式处理**：多个处理器串联处理数据流
- **临时文件管理**：自动管理处理过程中的临时文件

## 目录结构

```
internal/storage/primary/local/
├── storage.go          # 主存储实现
├── path_resolver.go    # 路径解析器（Hash-based）
├── pool_manager.go     # 存储池管理器
├── cache.go           # 缓存管理器
├── temp_manager.go     # 临时文件管理器
├── processor/         # 处理管道
│   └── pipeline.go
├── example/           # 示例代码
│   └── main.go
├── README.md          # 本文档
└── PERFORMANCE.md     # 性能优化 Issue 清单
```

## 快速开始

### 1. 基本配置

```go
import (
    "github.com/album/backend/internal/config"
    "github.com/album/backend/internal/config/modules"
    "github.com/album/backend/internal/storage"
    "github.com/album/backend/internal/storage/primary/local"
)

// 创建配置
cfg := &modules.LocalStorageConfig{
    BasePath: "./uploads",
    PoolManager: &modules.PoolManagerConfig{
        DeltaChannelSize:     1024,
        DeltaBatchSize:       128,
        FlushInterval:        modules.Duration(2 * time.Second),
        CacheRefreshInterval: modules.Duration(5 * time.Minute),
        ReconcileInterval:    modules.Duration(0),
    },
}

// 构建仓储（依赖数据库）
poolRepo := repository.NewStoragePoolRepository(db)

// 创建本地存储
localStorage, err := local.NewLocalStorage(cfg, poolRepo)
if err != nil {
    panic(err)
}

// 创建存储管理器
storageManager := storage.NewStorageManager(localStorage)
```

### 2. 上传文件

```go
ctx := context.Background()
key := "ab/cd/sample-hash.jpg"
data := strings.NewReader("文件内容")
size := int64(len("文件内容"))

opts := &storage.PutOptions{
    UserID:    1,
    Extension: "jpg",
    Variant:   "", // 原始文件，无变体
    Metadata: map[string]string{
        "content_type": "image/jpeg",
    },
}

err := storageManager.Put(ctx, key, data, size, opts)
if err != nil {
    log.Fatal(err)
}
```

### 3. 获取文件

```go
ctx := context.Background()
key := "ab/cd/sample-hash.jpg"

reader, err := storageManager.Get(ctx, key)
if err != nil {
    log.Fatal(err)
}
defer reader.Close()

data, err := io.ReadAll(reader)
if err != nil {
    log.Fatal(err)
}
```

### 4. 检查文件是否存在

```go
ctx := context.Background()
key := "ab/cd/sample-hash.jpg"

exists, err := storageManager.Exists(ctx, key)
if err != nil {
    log.Fatal(err)
}

if exists {
    fmt.Println("文件存在")
}
```

### 5. 获取文件信息

```go
ctx := context.Background()
key := "ab/cd/sample-hash.jpg"

info, err := storageManager.Stat(ctx, key)
if err != nil {
    log.Fatal(err)
}

fmt.Printf("文件大小: %d bytes\n", info.Size)
fmt.Printf("修改时间: %s\n", info.ModTime)
fmt.Printf("ContentType: %s\n", info.ContentType) // 从文件内容检测
```

### 6. 删除文件

```go
ctx := context.Background()
key := "ab/cd/sample-hash.jpg"

err := storageManager.Delete(ctx, key)
if err != nil {
    log.Fatal(err)
}
```

## 配置说明

### 存储池配置

```yaml
storage:
  primary:
    local:
      base_path: "./uploads"
      pools:
        - id: "pool-1"
          path: "/data/storage1"
          max_size: "1TB"
          priority: 1
          enabled: true
          auto_disable_threshold: 0.9  # 90% 时自动禁用
        - id: "pool-2"
          path: "/data/storage2"
          max_size: "2TB"
          priority: 2
          enabled: true
          auto_disable_threshold: 0.9
```

### 临时文件配置

```yaml
temp:
  base_path: "./temp"
  max_age: "24h"           # 临时文件最大保留时间
  max_size: "10GB"         # 临时目录最大大小
  cleanup_interval: "1h"   # 清理间隔
```

### 性能配置

```yaml
performance:
  cache_enabled: true
  cache_size: "1GB"        # 缓存最大大小
  cache_ttl: "24h"         # 缓存过期时间
  read_buffer_size: "64KB"  # 读取缓冲区大小
  write_buffer_size: "64KB" # 写入缓冲区大小
```

### 处理配置

```yaml
processing:
  enable_compression: true
  compression_level: 6
  enable_encryption: false
  encryption_key_path: "/etc/album/encryption.key"
```

## 文件路径规则

### Hash-based 路径结构

文件路径完全基于文件的 Hash 值生成，格式如下：

```
{base_path}/files/{hash[0:2]}/{hash[2:4]}/{hash}.{ext}
```

**示例**：
- Hash: `abcd1234...`
- 文件类型: `original`
- 路径: `uploads/files/ab/cd/abcd1234....jpg`

> **设计意图**：物理文件名只依据内容 Hash，业务层的 UUID、分享 ID 等元数据全部保存在数据库并指向该路径。这样既能保证去重，又避免业务标识泄漏到存储层。

### 文件命名规则

**存储层设计**：存储层只关心 Hash + 扩展名 + 变体，不包含业务逻辑

- **原始文件**：`{hash}.{ext}` （如 `abcd1234....jpg`, `abcd1234....arw`, `abcd1234....mp4`）
- **变体文件**：`{hash}_{variant}.{ext}` （如 `abcd1234...._thumb.jpg`, `abcd1234...._prev.jpg`）

**业务层适配**：业务层通过适配器处理文件类型语义

- **图片类型**：
  - 原始文件：保持原扩展名（jpg, png, arw, cr2 等）
  - 缩略图/预览图：统一使用 jpg 格式（`_thumb.jpg`, `_prev.jpg`）
- **视频类型**：
  - 原始文件：保持原扩展名（mp4, mov 等）
  - 缩略图/预览图：使用 jpg 格式（视频封面，`_thumb.jpg`, `_prev.jpg`）

### Key 格式

Key 格式与路径格式相同：

```
{hash[0:2]}/{hash[2:4]}/{hash}[_variant].{ext}
```

**示例**：
- `ab/cd/abcd1234....jpg` - JPG原始文件
- `ab/cd/abcd1234...._thumb.jpg` - JPG缩略图
- `ab/cd/abcd1234....arw` - RAW原始文件
- `ab/cd/abcd1234...._thumb.jpg` - RAW的缩略图（JPG格式）
- `ab/cd/abcd1234....mp4` - MP4视频文件
- `ab/cd/abcd1234...._thumb.jpg` - 视频缩略图（JPG格式）

## 存储池管理

### 选择策略

1. **优先级策略**：优先使用优先级高的存储池
2. **负载均衡**：在相同优先级下，选择最空闲的存储池
3. **自动禁用**：当存储池使用率超过阈值时，自动禁用
4. **故障转移**：当存储池不可用时，自动切换到其他存储池

### 使用示例

```go
// 选择存储池
poolID, err := localStorage.SelectPool(1024 * 1024) // 1MB
if err != nil {
    log.Fatal(err)
}

// 获取存储池信息
poolInfo, err := localStorage.GetPoolInfo(poolID)
if err != nil {
    log.Fatal(err)
}

fmt.Printf("存储池ID: %s\n", poolInfo.ID)
fmt.Printf("最大大小: %d bytes\n", poolInfo.MaxSize)
fmt.Printf("当前使用: %d bytes\n", poolInfo.CurrentSize)
fmt.Printf("使用率: %.2f%%\n", float64(poolInfo.CurrentSize)/float64(poolInfo.MaxSize)*100)
```

## 缓存管理

### 缓存策略

1. **内存缓存**：LRU 缓存，快速访问常用文件
2. **磁盘缓存**：持久化缓存，减少磁盘I/O
3. **自动清理**：定期清理过期缓存

### 使用示例

缓存管理器在存储操作中自动使用，无需手动调用。可以通过配置启用或禁用缓存：

```yaml
performance:
  cache_enabled: true
  cache_size: "1GB"
  cache_ttl: "24h"
```

## 临时文件管理

### 临时文件分类

- `uploads/`: 上传过程中的临时文件
- `processing/`: 处理过程中的临时文件
- `encryption/`: 加密处理临时文件

### 自动清理

临时文件管理器会自动清理过期文件，清理策略：

- **定期清理**：根据 `cleanup_interval` 配置定期清理
- **过期清理**：根据 `max_age` 配置清理过期文件
- **空间限制**：根据 `max_size` 配置限制临时目录大小

## 处理管道

### 处理器类型

1. **压缩处理器**：压缩文件以减少存储空间
2. **加密处理器**：加密文件以保护隐私
3. **元数据提取器**：提取文件元数据

### 使用示例

处理管道在文件上传时自动使用，可以通过配置启用：

```yaml
processing:
  enable_compression: true
  compression_level: 6
  enable_encryption: false
```

## 错误处理

### 常见错误

1. **存储池不足**：`no available pool for size {size}`
   - 原因：所有存储池空间不足或已禁用
   - 解决：增加存储池或清理空间

2. **文件不存在**：`file not found: {key}`
   - 原因：指定的文件不存在
   - 解决：检查 key 是否正确

3. **路径解析失败**：`resolve key: invalid key format`
   - 原因：Key 格式不正确
   - 解决：使用正确的 Key 格式

4. **临时目录满**：`temp directory full`
   - 原因：临时目录空间不足
   - 解决：清理临时文件或增加空间

## 性能优化建议

### 配置优化

#### 1. 存储池配置

- 根据实际需求配置多个存储池，实现负载均衡
- 合理设置优先级，将高性能存储设置为高优先级
- 设置合理的 `auto_disable_threshold`（建议 0.8-0.9），避免存储池过早禁用
- 定期监控存储池使用率，及时扩容

#### 2. 缓存配置

- 根据内存情况启用内存缓存（建议内存充足时启用）
- 合理设置缓存大小（建议为常用文件大小的 10-20 倍）
- 设置合理的缓存过期时间（建议 24-48 小时）
- 对于访问频繁的文件类型，可以增加缓存大小

#### 3. 临时文件管理

- 定期清理临时文件（建议每小时清理一次）
- 合理设置临时目录大小限制（建议为总存储空间的 5-10%）
- 根据实际上传频率调整清理间隔
- 监控临时文件目录使用率

#### 4. 处理管道

- 根据实际需求启用压缩和加密（压缩通常值得启用，加密按需）
- 压缩级别建议设置为 4-6（平衡压缩率和性能）
- 加密处理会增加 CPU 开销，仅在必要时启用
- 对于大文件，考虑使用流式处理而非全量处理

### 代码优化

详细的代码级性能优化计划和 Issue 清单请参考 [PERFORMANCE.md](./PERFORMANCE.md) 文档。

## 并发支持与性能

本地存储模块设计时充分考虑了并发场景，采用多种同步机制确保线程安全和高并发性能。

### 并发支持概述

#### 线程安全设计

- **存储池管理器**: 使用 `sync.RWMutex` 读写锁，支持并发读取
- **缓存管理器**: 使用 `sync.RWMutex` 读写锁，支持并发读取
- **路径解析器**: 无状态设计，完全线程安全
- **文件操作**: 操作系统级别支持并发访问

#### 并发性能特点

- ✅ **读取操作**: 高并发支持，O(1) 时间复杂度
- ⚠️ **写入操作**: 中等并发支持，存在优化空间
- ✅ **缓存操作**: 高并发支持，读写锁优化
- ✅ **存储池管理**: 高并发支持，独立锁设计

### 性能优化计划

详细的性能分析和优化计划请参考 [PERFORMANCE.md](./PERFORMANCE.md) 文档。

**优化优先级**：
- 🔴 **P0 - 紧急**: 存储池大小更新锁竞争优化（立即优化）
- 🟡 **P1 - 高优先级**: 临时文件管理器串行化优化（近期优化）
- 🟡 **P2 - 中优先级**: 缓存清理锁内遍历优化（中期优化）
- 🟢 **P3 - 低优先级**: CheckAndUpdatePools 异步执行优化（可暂缓）

### 性能监控

建议监控以下关键指标：
- 锁竞争指标（锁等待时间、竞争次数）
- 操作性能指标（P50、P95、P99 延迟）
- 并发能力指标（吞吐量、并发数）
- 资源使用指标（CPU、内存、磁盘 I/O）

详细的性能监控建议和优化路线图请参考 [PERFORMANCE.md](./PERFORMANCE.md)。

## 最佳实践

### 1. 文件上传

```go
// 1. 计算文件 Hash（用于去重）
hash := calculateFileHash(file)

// 2. 使用业务层适配器构建 Key 和选项
// 注意：实际使用中应通过业务层适配器处理
adapter := media.NewStorageAdapter()
key, err := adapter.BuildStorageKey(hash, itemType, media.MediaFileTypeOriginal, extension)
if err != nil {
    return err
}

opts, err := adapter.ToStorageOptions(itemType, media.MediaFileTypeOriginal, extension)
if err != nil {
    return err
}
opts.UserID = userID
opts.Metadata = map[string]string{
    "content_type": contentType,
}

// 3. 上传文件
err = storageManager.Put(ctx, key, file, size, opts)

// 4. 在数据库中创建媒体记录（业务 UUID 在数据库层生成）
mediaRepo.Create(ctx, &models.Media{
    UUID:     generateUUID(),
    Hash:     hash,
    LocalPath: filepath.Join("files", key),
    // ...
})
```

### 2. 文件下载

```go
// 1. 检查文件是否存在
exists, err := storageManager.Exists(ctx, key)
if err != nil || !exists {
    return errors.New("file not found")
}

// 2. 获取文件
reader, err := storageManager.Get(ctx, key)
if err != nil {
    return err
}
defer reader.Close()

// 3. 读取文件内容
data, err := io.ReadAll(reader)
```

### 3. 存储池监控

```go
// 定期检查存储池状态
ticker := time.NewTicker(1 * time.Hour)
defer ticker.Stop()

for range ticker.C {
    // 获取所有存储池信息
    for _, poolID := range poolIDs {
        poolInfo, err := localStorage.GetPoolInfo(poolID)
        if err != nil {
            log.Printf("获取存储池信息失败: %v", err)
            continue
        }
        
        usage := float64(poolInfo.CurrentSize) / float64(poolInfo.MaxSize)
        if usage > 0.8 {
            log.Printf("警告: 存储池 %s 使用率 %.2f%%", poolID, usage*100)
        }
    }
}
```

## API 参考

### LocalStorage

```go
type LocalStorage interface {
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
    SelectPool(size int64) (string, error)
    GetPoolInfo(poolID string) (*PoolInfo, error)
}
```

### PutOptions

```go
type PutOptions struct {
    UserID     uint
    Extension  string            // 文件扩展名（如 "jpg", "mp4", "arw"），不包含点号
    Variant    string            // 文件变体标识（如 "thumb", "prev"），可选，用于区分同一hash的不同变体
    Processors []string          // 处理步骤：compression, encryption
    PoolID     string            // 指定存储池
    Metadata   map[string]string // 元数据
}
```

**注意**：`FileType` 枚举已移除，改为使用 `Extension` + `Variant`。业务层的文件类型语义（original/thumbnail/preview）由业务层适配器处理。

### FileInfo

```go
type FileInfo struct {
    Key         string
    Size        int64
    ModTime     time.Time
    ContentType string
    Metadata    map[string]string
}
```

### PoolInfo

```go
type PoolInfo struct {
    ID          string
    Path        string
    MaxSize     int64
    CurrentSize int64
    Priority    int
    Enabled     bool
}
```

## 示例代码

完整示例代码请参考 [example/main.go](./example/main.go)，包含以下示例：
- 基本配置和初始化
- 文件上传（Put）
- 文件下载（Get）
- 文件存在检查（Exists）
- 文件信息获取（Stat）
- 文件删除（Delete）
- 存储池管理

## 常见问题

### Q: 如何实现文件去重？

A: 使用文件的 Hash 值作为路径的一部分，相同 Hash 的文件会存储在同一位置。在上传前可以先计算 Hash，检查文件是否已存在。Hash-based 存储策略天然支持文件去重。

### Q: 如何支持不同媒体类型（图片、视频、RAW）？

A: 存储层支持任意扩展名，通过 `Extension` 字段指定。业务层适配器会根据媒体类型（图片/视频）和业务类型（原始/缩略图/预览图）自动选择合适的扩展名：
- 图片原始文件：保持原格式（jpg, png, arw 等）
- 图片缩略图/预览图：统一使用 jpg
- 视频原始文件：保持原格式（mp4, mov 等）
- 视频缩略图/预览图：使用 jpg（视频封面）

### Q: ContentType 是如何检测的？

A: ContentType 通过读取文件内容的 magic bytes 检测，而不是从扩展名推断。这确保了准确性，即使扩展名被修改也能正确识别文件类型。

### Q: 如何支持多用户文件隔离？

A: 文件存储与用户解耦，用户关联存储在数据库层。在应用层进行权限检查，确保用户只能访问自己的文件或被分享的文件。这种设计支持跨用户共享，提高存储效率。

### Q: 如何处理存储池故障？

A: 存储池管理器会自动检测存储池状态，当存储池不可用时会自动切换到其他存储池。可以通过 `CheckAndUpdatePools` 方法定期检查存储池状态。建议设置合理的监控和告警机制。

### Q: 如何优化大文件上传？

A: 可以使用分片上传，将大文件分成多个小块分别上传，然后在服务端合并。也可以使用临时文件管理器管理上传过程中的临时文件。对于超大文件，建议使用流式处理。

### Q: 如何提升并发上传性能？

A: 参考 [PERFORMANCE.md](./PERFORMANCE.md) 中的性能优化计划。当前最紧急的优化是存储池大小更新的锁竞争问题，建议立即使用原子操作替代锁保护。

### Q: 缓存命中率如何提升？

A: 合理设置缓存大小和过期时间，监控缓存命中率，根据实际情况调整。对于热点文件，可以考虑预热缓存。详细优化建议参考 [PERFORMANCE.md](./PERFORMANCE.md)。

## 相关文档

- [PERFORMANCE.md](./PERFORMANCE.md) - 性能优化 Issue 清单和优化路线图
- [示例代码](./example/main.go) - 完整的使用示例

## 未来规划

| 规划方向 | 说明 |
| -------- | ---- |
| 存储池切换 | 提供 API/后台控制在不停机情况下切换默认写入池，结合 PoolManager 的动态禁用能力，实现平滑迁移/维护 |
| 批量迁移 | 引入迁移任务，批量将旧池上的 Media 搬到新池，过程中保持 hash 去重与 LocalPoolUUID 更新一致 |
| 多副本策略 | 支持同一 Hash 写入多个池（SSD/HDD/云）以满足不同 SLA，未来会在 Media 模型中扩展副本状态 |
| 热冷分层 | 根据访问日志把热点文件迁入高性能池，冷数据迁回归档池，和 PoolManager 的 `storage_type` 配合 |

## 已知风险与注意事项

1. **Delta 队列积压**：如果写入峰值超过 `delta_channel_size`，会阻塞上传。需要监控并按需调大参数或拆分 worker。
2. **缓存刷新窗口**：数据库更新后的池状态需要等待 `cache_refresh_interval` 才能生效，关键操作可手动触发 `InvalidateCache`。
3. **Reconcile 成本高**：全量扫描磁盘耗时，建议在低峰期执行并限制并发，避免影响线上 I/O。
4. **数据库写失败导致容量漂移**：虽然有重试机制，但长时间失败会造成 `CurrentSize` 偏差，需要结合日志/告警及时处理。
5. **缺少自动化迁移工具**：目前对大规模磁盘退役仍需手动操作，后续需配合迁移任务和审计能力。
