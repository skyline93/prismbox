// replicator/repository.go

package replicator

import (
	"context"
	"encoding/json"
	"time"

	"gorm.io/gorm"
)

// changelogRepository 是一个实现了 WritableRepository 接口的通用仓储包装器。
// 它包装了业务仓储，自动处理事务和Changelog的原子性写入。
// 这是一个内部结构体，外部通过 WritableRepository 接口与之交互。
type changelogRepository[T SyncedModel] struct {
	db      *gorm.DB
	wrapped WritableRepository[T]
}

// WithChangelog 是此包装器的构造函数。它接收一个业务仓储，
// 返回一个同样实现了 WritableRepository 接口的新仓储实例。
// 业务代码应使用返回的实例来执行所有写操作。
func WithChangelog[T SyncedModel](db *gorm.DB, wrapped WritableRepository[T]) WritableRepository[T] {
	return &changelogRepository[T]{
		db:      db,
		wrapped: wrapped,
	}
}

func (r *changelogRepository[T]) Create(ctx context.Context, model T) (T, error) {
	var createdModel T
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		m, err := r.wrapped.Create(ctx, model)
		if err != nil {
			return err
		}
		createdModel = m
		return createChangelogEntry(tx, m, OperationCreated)
	})
	return createdModel, err
}

func (r *changelogRepository[T]) Update(ctx context.Context, model T) (T, error) {
	var updatedModel T
	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		m, err := r.wrapped.Update(ctx, model)
		if err != nil {
			return err
		}
		updatedModel = m
		return createChangelogEntry(tx, m, OperationUpdated)
	})
	return updatedModel, err
}

func (r *changelogRepository[T]) Delete(ctx context.Context, model T) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		recordID := model.GetRecordID()
		tableName := model.GetTableName()

		if err := r.wrapped.Delete(ctx, model); err != nil {
			return err
		}

		changelog := Changelog{
			TableName:     tableName,
			RecordID:      recordID,
			OperationType: OperationDeleted,
			Payload:       nil,
			Timestamp:     time.Now().UTC(),
		}
		return tx.Create(&changelog).Error
	})
}

// createChangelogEntry 是一个内部辅助函数，用于创建和保存 changelog 记录。
func createChangelogEntry[T SyncedModel](tx *gorm.DB, model T, opType OperationType) error {
	payload, err := json.Marshal(model)
	if err != nil {
		return err
	}
	changelog := Changelog{
		TableName:     model.GetTableName(),
		RecordID:      model.GetRecordID(),
		OperationType: opType,
		Payload:       payload,
		Timestamp:     time.Now().UTC(),
	}
	return tx.Create(&changelog).Error
}
