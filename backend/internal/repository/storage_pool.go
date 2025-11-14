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

// List 根据过滤条件返回存储池列表
func (r *storagePoolRepository) List(ctx context.Context, filter StoragePoolFilter) ([]*models.StoragePool, error) {
	var pools []*models.StoragePool
	tx := r.db.WithContext(ctx).Model(&models.StoragePool{})
	if filter.StorageType != "" {
		tx = tx.Where("storage_type = ?", filter.StorageType)
	}
	if filter.Status != "" {
		tx = tx.Where("status = ?", filter.Status)
	}
	if err := tx.Order("priority ASC").Find(&pools).Error; err != nil {
		return nil, err
	}
	return pools, nil
}

// FindByUUID 根据 UUID 获取存储池
func (r *storagePoolRepository) FindByUUID(ctx context.Context, uuid string) (*models.StoragePool, error) {
	var pool models.StoragePool
	if err := r.db.WithContext(ctx).Where("uuid = ?", uuid).First(&pool).Error; err != nil {
		return nil, err
	}
	return &pool, nil
}

// Create 创建存储池
func (r *storagePoolRepository) Create(ctx context.Context, pool *models.StoragePool) error {
	return r.db.WithContext(ctx).Create(pool).Error
}

// UpdateByUUID 更新存储池字段
func (r *storagePoolRepository) UpdateByUUID(ctx context.Context, uuid string, updates map[string]interface{}) error {
	if len(updates) == 0 {
		return nil
	}
	return r.db.WithContext(ctx).
		Model(&models.StoragePool{}).
		Where("uuid = ?", uuid).
		Updates(updates).Error
}

// SetEnabled 更新启用状态
func (r *storagePoolRepository) SetEnabled(ctx context.Context, uuid string, enabled bool) error {
	return r.db.WithContext(ctx).
		Model(&models.StoragePool{}).
		Where("uuid = ?", uuid).
		Update("enabled", enabled).Error
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

// FindUsage 返回容量统计
func (r *storagePoolRepository) FindUsage(ctx context.Context, poolUUID string) ([]StoragePoolUsageRow, error) {
	var rows []StoragePoolUsageRow
	tx := r.db.WithContext(ctx).Model(&models.StoragePool{})
	if poolUUID != "" {
		tx = tx.Where("uuid = ?", poolUUID)
	}
	err := tx.Select("uuid, current_size AS database_size, current_size AS actual_size, last_checked_at").
		Order("priority ASC").
		Scan(&rows).Error
	return rows, err
}
