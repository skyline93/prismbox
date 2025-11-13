package changelog

import (
	"context"
	"database/sql/driver"
	"encoding/json"
	"time"
)

// --- Constants ---

// OperationType 定义了数据变更的操作类型
type OperationType string

const (
	OperationCreated OperationType = "CREATED"
	OperationUpdated OperationType = "UPDATED"
	OperationDeleted OperationType = "DELETED"
)

// --- Interfaces ---

// ChangelogModel 是业务模型必须实现的接口，以便 changelog 可以获取其元数据
type ChangelogModel interface {
	// GetRecordID 获取记录ID
	GetRecordID() string

	// GetTableName 获取表名
	GetTableName() string

	// GetIsolationKey 获取隔离键（可选实现）
	// 返回隔离字段名，如 "user_id", "organization_id" 等
	// 如果返回空字符串，表示该表不需要隔离
	GetIsolationKey() string

	// GetIsolationValue 获取隔离值（可选实现）
	// 返回隔离字段的值，如用户ID、组织ID等
	// 如果返回空字符串，表示该记录不需要隔离
	GetIsolationValue() string
}

// WritableRepository 是所有需要被同步的业务仓储必须实现的通用写操作接口
// 事务管理将由 changelog 模块内部统一处理
type WritableRepository[T ChangelogModel] interface {
	Create(ctx context.Context, model T) (T, error)
	Update(ctx context.Context, model T) (T, error)
	Delete(ctx context.Context, model T) error
}

// --- Models ---

// Changelog 记录了每一次数据的变更历史
type Changelog struct {
	SequenceID    int64         `gorm:"primaryKey;autoIncrement"`
	TableNameCol  string        `gorm:"column:table_name;type:varchar(255);index:idx_changelog_table" json:"table_name"`
	RecordID      string        `gorm:"type:varchar(255);index:idx_changelog_record"`
	OperationType OperationType `gorm:"type:varchar(10)"`
	Payload       JSON          `gorm:"type:jsonb"`
	Timestamp     time.Time     `gorm:"not null;index:idx_changelog_timestamp"`

	// 通用隔离字段（冗余但关键）
	// 从 Payload 中提取，用于快速过滤和查询
	// 如果为空，表示该表不需要隔离
	IsolationKey   string `gorm:"type:varchar(100);index:idx_changelog_isolation" json:"isolation_key,omitempty"`
	IsolationValue string `gorm:"type:varchar(255);index:idx_changelog_isolation" json:"isolation_value,omitempty"`

	// 复合索引：提高查询性能
	// idx_changelog_isolation_seq: (isolation_key, isolation_value, sequence_id) - 用于隔离增量同步
}

// TableName 指定表名（GORM 标准方法）
func (Changelog) TableName() string {
	return "changelogs"
}

// ClientChangelogStatus 追踪每个设备用户的变更日志同步进度
type ClientChangelogStatus struct {
	DeviceID                string    `gorm:"primaryKey;type:varchar(255)"`
	UserID                  string    `gorm:"index;type:varchar(255)"`
	LastChangelogSequenceID int64     `gorm:"not null;column:last_synced_sequence_id"`
	LastSeenTimestamp       time.Time `gorm:"not null"`
}

// TableName 指定表名（GORM 标准方法）
func (ClientChangelogStatus) TableName() string {
	return "client_sync_statuses"
}

// JSON 自定义 JSON 类型，用于 GORM
type JSON []byte

// Value 实现 driver.Valuer 接口
func (j JSON) Value() (driver.Value, error) {
	if len(j) == 0 {
		return nil, nil
	}
	return string(j), nil
}

// Scan 实现 sql.Scanner 接口
func (j *JSON) Scan(value interface{}) error {
	if value == nil {
		*j = nil
		return nil
	}
	bytes, ok := value.([]byte)
	if !ok {
		return json.Unmarshal([]byte(value.(string)), j)
	}
	*j = JSON(bytes)
	return nil
}

// MarshalJSON 实现 json.Marshaler 接口
func (j JSON) MarshalJSON() ([]byte, error) {
	if len(j) == 0 {
		return []byte("null"), nil
	}
	return []byte(j), nil
}

// UnmarshalJSON 实现 json.Unmarshaler 接口
func (j *JSON) UnmarshalJSON(data []byte) error {
	if j == nil {
		return json.Unmarshal(data, j)
	}
	*j = JSON(data)
	return nil
}
