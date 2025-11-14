# 7.1 分层存储架构

## 7.1.1 设计原则

**核心设计理念：主存储与次存储完全解耦**

- **主存储（Primary Storage）**：用户上传文件的本地存储，同步操作，必须成功
- **次存储（Secondary Storage）**：云存储备份，异步操作，可选功能
- **完全解耦**：用户上传流程与云存储备份流程完全独立，通过后台调度器统一处理
- **延迟调度**：不在用户上传时触发备份，而是在系统空闲时批量处理

## 7.1.2 存储接口设计

### 主存储接口（同步操作）

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

### 次存储接口（异步操作）

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

### 存储管理器

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

## 7.1.3 存储实现

### 主存储实现

- **local**：本地文件系统存储（主要存储）

### 次存储实现

- **openlist**：通过 OpenList/AList 对接的云存储（备份存储）
- **s3**：AWS S3 存储（直接对接，可选）
- **oss**：阿里云 OSS 存储（直接对接，可选）
- **cos**：腾讯云 COS 存储（直接对接，可选）

## 7.1.4 存储工厂

```go
// 创建主存储
func NewPrimaryStorage(cfg *modules.PrimaryStorageConfig, db *gorm.DB) (interfaces.PrimaryStorage, error) {
    switch cfg.Type {
    case "local":
        poolRepo := repository.NewStoragePoolRepository(db)
        return local.NewLocalStorage(cfg.Local, poolRepo)
    default:
        return nil, fmt.Errorf("unsupported primary storage type: %s", cfg.Type)
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
    Extension   string            // 文件扩展名（如 "jpg", "mp4", "arw"），不包含点号
    Variant     string            // 文件变体标识（如 "thumb", "prev"），可选，用于区分同一hash的不同变体
    Processors  []string          // 处理步骤：compression, encryption
    PoolID      string            // 指定存储池
    Metadata    map[string]string // 元数据
}

// 注意：FileType 枚举已移除，改为使用 Extension + Variant
// 业务层的文件类型语义（original/thumbnail/preview）由业务层适配器处理
```

## 7.1.5 存储池管理（数据库 + 内存计数）

- **配置下放到数据库**：所有存储池定义（`storage_pools` 表）持久化在数据库里，支持本地与云类型统一管理。`LocalPath`、`CloudConfig`、容量阈值、优先级都由运维通过管理后台或 migration 维护。
- **PoolManager 只读配置**：`NewLocalStorage` 在启动时通过 `StoragePoolRepository` 读取启用中的存储池，并构建本地缓存。应用无需重启即可通过刷新任务感知配置变化。
- **内存计数 + 串行持久化**：
  - 上传/删除即时更新本地缓存（互斥锁保护），保证可用空间判断实时准确。
  - 同时将 `PoolDelta` 写入 channel，由单独 worker 串行汇总并通过 `UPDATE storage_pools SET current_size = current_size + ?` 原子语句落库，避免并发覆盖。
  - 进程退出或收到 flush 信号时会强制刷写 pending 增量，确保不会丢数据。
- **定期校验**：PoolManager 支持可选的 `reconcile_interval`，在低频周期内重新遍历文件系统并与数据库对账，及时发现漂移。
- **缓存刷新**：`cache_refresh_interval` 用于定时从数据库重新加载元数据，保证多实例在几分钟内收敛；也提供手动 `InvalidateCache` 接口。
- **配置参数**：
  - `delta_channel_size`：增量队列长度，防止高峰期阻塞。
  - `delta_batch_size`：一次批量写库的最大池数量。
  - `flush_interval`：增量自动落库周期。
  - `cache_refresh_interval`：加载最新存储池元数据的周期。
  - `reconcile_interval`：可选的全量校验周期，0 表示关闭。

## 7.1.6 未来演进方向

| 方向 | 描述 | 依赖/注意事项 |
| ---- | ---- | ------------- |
| 存储池平滑切换 | 提供 API/后台用于在不中断写入的情况下切换默认池，并追踪操作日志 | PoolManager 已支持动态禁用/启用池，后续需要统一控制面 |
| 大规模迁移 | 通过迁移任务批量搬迁旧数据到新池，保证 hash 去重语义不变 | 需与 delta worker、Media 更新流程解耦，考虑限速与重试 |
| 多副本/多级存储 | 支持同一 hash 多副本（SSD / HDD / 云），基于策略自动放置 | 需要扩展 Media 记录、Pool 类型、读写调度逻辑 |
| 智能冷热分层 | 根据访问频率将文件自动迁移到不同池（缓存/归档） | 依赖访问统计和后台任务，需防止 thrash |

## 7.1.7 当前风险与待办

1. **增量落库单点**：delta worker 在单 goroutine 中串行写库，如遇数据库长时间不可用会造成积压。需要监控队列长度并提供持久化（WAL）能力。
2. **多实例一致性**：虽然数据库更新采用原子自增，但缓存刷新存在窗口。尽量统一 `cache_refresh_interval`，并在状态变更后触发广播或手动刷新。
3. **Reconcile 成本**：全量扫描磁盘耗费资源；需在运维窗口执行，并限制并发，避免影响在线 I/O。
4. **缺少自动迁移工具**：目前仅规划层面的迁移设计，尚未提供可执行工具。如果需要扩容/退役磁盘，需要手动操作。
5. **配置治理**：StoragePool 由数据库掌控，需要额外的后台界面/API/审计机制确保变更可追溯。

