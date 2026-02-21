package interfaces

import (
	"context"
	"io"
	"time"
)

// PutOptions 上传选项
type PutOptions struct {
	UserID     uint
	Extension  string            // 文件扩展名（如 "jpg", "mp4", "arw"），不包含点号
	Variant    string            // 文件变体标识（如 "thumb", "prev"），可选，用于区分同一hash的不同变体
	Processors []string          // 处理步骤：compression, encryption
	PoolID     string            // 指定存储池
	Metadata   map[string]string // 元数据
}

// FileInfo 文件信息
type FileInfo struct {
	Key         string
	Size        int64
	ModTime     time.Time
	ContentType string
	Metadata    map[string]string
}

// PoolInfo 存储池信息
type PoolInfo struct {
	ID          string
	Path        string
	MaxSize     int64
	CurrentSize int64
	Priority    int
	Enabled     bool
}

// PoolOperationResult 存储池操作结果
type PoolOperationResult struct {
	Message string
	TaskID  string
}

// PoolRefreshRequest 缓存刷新请求
type PoolRefreshRequest struct {
	Node  string
	Async bool
}

// PoolReconcileRequest 存储池对账请求
type PoolReconcileRequest struct {
	PoolUUID string
	DryRun   bool
	Parallel int
}

// PrimaryStorage 主存储接口（同步操作，必须成功）
type PrimaryStorage interface {
	// 基础操作
	Put(ctx context.Context, key string, data io.Reader, size int64, opts *PutOptions) error
	Get(ctx context.Context, key string) (io.ReadCloser, error)
	// GetWithPool 在指定池中按 key 获取文件，用于读时定向（调用方已知 pool_id 时避免多池遍历）
	GetWithPool(ctx context.Context, key string, poolID string) (io.ReadCloser, error)
	Delete(ctx context.Context, key string) error
	Exists(ctx context.Context, key string) (bool, error)
	GetSignedURL(ctx context.Context, key string, duration time.Duration) (string, error)

	// 高级操作
	Copy(ctx context.Context, srcKey, dstKey string) error
	Move(ctx context.Context, srcKey, dstKey string) error
	Stat(ctx context.Context, key string) (*FileInfo, error)

	// 存储池管理
	SelectPool(size int64) (string, error) // 返回池ID
	GetPoolInfo(poolID string) (*PoolInfo, error)

	// Close 释放资源并停止后台 goroutine（如 delta worker、cache refresher、reconciler），应在应用退出时调用。
	Close() error
}

// SecondaryStorage 次存储接口（异步操作，用于备份）
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

// PoolMaintenance 可选接口：实现额外的存储池维护能力
type PoolMaintenance interface {
	RefreshPools(ctx context.Context, req *PoolRefreshRequest) (*PoolOperationResult, error)
	ReconcilePools(ctx context.Context, req *PoolReconcileRequest) (*PoolOperationResult, error)
}

// UploadStatus 上传状态
type UploadStatus struct {
	Key      string
	Status   string // "pending", "uploading", "completed", "failed"
	Progress int64  // 已上传字节数
	Total    int64  // 总字节数
	Error    string // 错误信息
}
