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
    Extension   string            // 文件扩展名（如 "jpg", "mp4", "arw"），不包含点号
    Variant     string            // 文件变体标识（如 "thumb", "prev"），可选，用于区分同一hash的不同变体
    Processors  []string          // 处理步骤：compression, encryption
    PoolID      string            // 指定存储池
    Metadata    map[string]string // 元数据
}

// 注意：FileType 枚举已移除，改为使用 Extension + Variant
// 业务层的文件类型语义（original/thumbnail/preview）由业务层适配器处理
```

