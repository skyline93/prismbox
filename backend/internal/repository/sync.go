package repository

import (
	"context"
	"time"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

// syncRepository 同步仓储实现
type syncRepository struct {
	db *gorm.DB
}

// NewSyncRepository 创建同步仓储
func NewSyncRepository(db *gorm.DB) SyncRepository {
	return &syncRepository{
		db: db,
	}
}

// GetAssetsWithCursor 使用游标分页获取资产列表
func (r *syncRepository) GetAssetsWithCursor(ctx context.Context, userID uint, batchSize int, lastID string) ([]*models.Media, string, error) {
	query := r.db.WithContext(ctx).
		Where("user_id = ? AND deleted = ?", userID, false)

	// 游标分页：使用 ID 排序和比较
	if lastID != "" {
		// 如果 lastID 是 UUID，需要先找到对应的记录
		var lastMedia models.Media
		if err := r.db.WithContext(ctx).Where("uuid = ?", lastID).First(&lastMedia).Error; err == nil {
			query = query.Where("id > ?", lastMedia.ID)
		} else {
			// 如果找不到，使用 UUID 字符串比较（作为备选方案）
			query = query.Where("uuid > ?", lastID)
		}
	}

	var medias []*models.Media
	// 查询 batchSize + 1 条，用于判断是否还有更多数据
	if err := query.Order("id ASC").Limit(batchSize + 1).Find(&medias).Error; err != nil {
		return nil, "", err
	}

	hasMore := len(medias) > batchSize
	if hasMore {
		medias = medias[:batchSize]
	}

	nextLastID := ""
	if len(medias) > 0 {
		nextLastID = medias[len(medias)-1].UUID
	}

	return medias, nextLastID, nil
}

// GetAssetsSince 获取指定时间之后的资产（用于增量同步）
func (r *syncRepository) GetAssetsSince(ctx context.Context, userID uint, since *time.Time, batchSize int) ([]*models.Media, error) {
	query := r.db.WithContext(ctx).
		Where("user_id = ? AND deleted = ?", userID, false)

	if since != nil {
		query = query.Where("updated_at > ?", *since)
	}

	var medias []*models.Media
	if err := query.Order("updated_at ASC").Limit(batchSize).Find(&medias).Error; err != nil {
		return nil, err
	}

	return medias, nil
}

// GetDeletedAssetsSince 获取指定时间之后被软删除的资产UUID列表（用于增量同步）
func (r *syncRepository) GetDeletedAssetsSince(ctx context.Context, userID uint, since *time.Time, batchSize int) ([]string, error) {
	query := r.db.WithContext(ctx).
		Model(&models.Media{}).
		Where("user_id = ? AND deleted = ?", userID, true).
		Select("uuid")

	if since != nil {
		query = query.Where("updated_at > ?", *since)
	}

	var uuids []string
	if err := query.Order("updated_at ASC").Limit(batchSize).Pluck("uuid", &uuids).Error; err != nil {
		return nil, err
	}

	return uuids, nil
}
