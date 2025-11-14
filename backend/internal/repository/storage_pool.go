package repository

import (
	"context"
	"time"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

type storagePoolRepository struct {
	db *gorm.DB
}

// NewStoragePoolRepository 创建存储池仓储实现
func NewStoragePoolRepository(db *gorm.DB) StoragePoolRepository {
	return &storagePoolRepository{db: db}
}

func (r *storagePoolRepository) FindEnabledByStorageType(ctx context.Context, storageType string) ([]*models.StoragePool, error) {
	var pools []*models.StoragePool
	err := r.db.WithContext(ctx).
		Where("storage_type = ? AND enabled = ? AND status = ?", storageType, true, "active").
		Order("priority ASC").
		Find(&pools).Error
	return pools, err
}

func (r *storagePoolRepository) IncrementCurrentSize(ctx context.Context, poolUUID string, delta int64) error {
	return r.db.WithContext(ctx).
		Model(&models.StoragePool{}).
		Where("uuid = ?", poolUUID).
		Update("current_size", gorm.Expr("current_size + ?", delta)).Error
}

func (r *storagePoolRepository) UpdateCurrentSize(ctx context.Context, poolUUID string, size int64) error {
	return r.db.WithContext(ctx).
		Model(&models.StoragePool{}).
		Where("uuid = ?", poolUUID).
		Update("current_size", size).Error
}

func (r *storagePoolRepository) UpdateState(ctx context.Context, poolUUID string, enabled bool, status string, currentSize int64, lastCheckedAt *time.Time) error {
	updates := map[string]interface{}{
		"enabled":      enabled,
		"status":       status,
		"current_size": currentSize,
	}
	if lastCheckedAt != nil {
		updates["last_checked_at"] = lastCheckedAt
	}
	return r.db.WithContext(ctx).
		Model(&models.StoragePool{}).
		Where("uuid = ?", poolUUID).
		Updates(updates).Error
}
