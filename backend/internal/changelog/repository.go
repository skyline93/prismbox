package changelog

import (
	"context"
	"encoding/json"
	"time"

	"gorm.io/gorm"
)

// changelogRepository 是一个实现了 WritableRepository 接口的通用仓储包装器
// 它包装了业务仓储，自动处理事务和 Changelog 的原子性写入
type changelogRepository[T ChangelogModel] struct {
	db      *gorm.DB
	wrapped WritableRepository[T]
	config  *Config
}

// WithChangelog 是此包装器的构造函数
// 它接收一个业务仓储，返回一个同样实现了 WritableRepository 接口的新仓储实例
// 如果 config.Enabled=false，直接返回原始仓储（零开销）
func WithChangelog[T ChangelogModel](
	db *gorm.DB,
	wrapped WritableRepository[T],
	config *Config,
) WritableRepository[T] {
	// 如果未启用，直接返回原始仓储（零侵入）
	if !config.Enabled {
		return wrapped
	}

	return &changelogRepository[T]{
		db:      db,
		wrapped: wrapped,
		config:  config,
	}
}

// Create 创建记录
func (r *changelogRepository[T]) Create(ctx context.Context, model T) (T, error) {
	var createdModel T
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		m, err := r.wrapped.Create(ctx, model)
		if err != nil {
			return err
		}
		createdModel = m
		return r.createChangelogEntry(tx, m, OperationCreated)
	})
	return createdModel, err
}

// Update 更新记录
func (r *changelogRepository[T]) Update(ctx context.Context, model T) (T, error) {
	var updatedModel T
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		m, err := r.wrapped.Update(ctx, model)
		if err != nil {
			return err
		}
		updatedModel = m
		return r.createChangelogEntry(tx, m, OperationUpdated)
	})
	return updatedModel, err
}

// Delete 删除记录
func (r *changelogRepository[T]) Delete(ctx context.Context, model T) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		recordID := model.GetRecordID()
		tableName := model.GetTableName()

		if err := r.wrapped.Delete(ctx, model); err != nil {
			return err
		}

		// 提取隔离信息
		isolationKey := model.GetIsolationKey()
		isolationValue := model.GetIsolationValue()

		changelog := Changelog{
			TableNameCol:   tableName,
			RecordID:       recordID,
			OperationType:  OperationDeleted,
			Payload:        nil,
			Timestamp:      time.Now().UTC(),
			IsolationKey:   isolationKey,
			IsolationValue: isolationValue,
		}
		return tx.Create(&changelog).Error
	})
}

// createChangelogEntry 创建变更日志条目
func (r *changelogRepository[T]) createChangelogEntry(
	tx *gorm.DB,
	model T,
	opType OperationType,
) error {
	payload, err := json.Marshal(model)
	if err != nil {
		return err
	}

	// 提取隔离信息
	isolationKey := model.GetIsolationKey()
	isolationValue := model.GetIsolationValue()

	changelog := Changelog{
		TableNameCol:   model.GetTableName(),
		RecordID:       model.GetRecordID(),
		OperationType:  opType,
		Payload:        JSON(payload),
		Timestamp:      time.Now().UTC(),
		IsolationKey:   isolationKey,
		IsolationValue: isolationValue,
	}

	return tx.Create(&changelog).Error
}

// WrapperFactory 包装器工厂，根据配置决定是否启用包装
type WrapperFactory struct {
	db     *gorm.DB
	config *Config
}

// NewWrapperFactory 创建包装器工厂
func NewWrapperFactory(db *gorm.DB, config *Config) *WrapperFactory {
	return &WrapperFactory{
		db:     db,
		config: config,
	}
}

// WrapRepository 包装仓储（包级函数，因为 Go 不支持泛型方法）
// 如果 changelog 未启用，直接返回原始仓储（零开销）
// 如果启用，返回包装后的仓储
func WrapRepository[T ChangelogModel](
	factory *WrapperFactory,
	repo WritableRepository[T],
) WritableRepository[T] {
	return WithChangelog(factory.db, repo, factory.config)
}

// IsEnabled 检查是否启用
func (f *WrapperFactory) IsEnabled() bool {
	return f.config.Enabled
}
