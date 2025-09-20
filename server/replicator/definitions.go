// replicator/definitions.go

package replicator

import (
	"context"
	"time"

	"gorm.io/datatypes"
)

// --- Constants ---

// OperationType 定义了数据变更的操作类型。
type OperationType string

const (
	OperationCreated OperationType = "CREATED"
	OperationUpdated OperationType = "UPDATED"
	OperationDeleted OperationType = "DELETED"
)

// --- Interfaces ---

// SyncedModel 是业务模型必须实现的接口，以便复制器可以获取其元数据。
type SyncedModel interface {
	GetRecordID() string
	GetTableName() string
}

// WritableRepository 是所有需要被同步的业务仓储必须实现的通用写操作接口。
// 事务管理将由复制器模块内部统一处理。
type WritableRepository[T SyncedModel] interface {
	Create(ctx context.Context, model T) (T, error)
	Update(ctx context.Context, model T) (T, error)
	Delete(ctx context.Context, model T) error
}

// --- Models ---

// Changelog 记录了每一次数据的变更历史。
type Changelog struct {
	SequenceID    int64          `gorm:"primaryKey;autoIncrement"`
	TableName     string         `gorm:"type:varchar(255);index"`
	RecordID      string         `gorm:"type:varchar(255);index"`
	OperationType OperationType  `gorm:"type:varchar(10)"`
	Payload       datatypes.JSON `gorm:"type:jsonb"`
	Timestamp     time.Time      `gorm:"not null"`
}

// ClientSyncStatus 追踪每个设备用户的同步进度。
type ClientSyncStatus struct {
	DeviceID             string    `gorm:"primaryKey;type:varchar(255)"`
	UserID               string    `gorm:"index;type:varchar(255)"`
	LastSyncedSequenceID int64     `gorm:"not null"`
	LastSeenTimestamp    time.Time `gorm:"not null"`
}
