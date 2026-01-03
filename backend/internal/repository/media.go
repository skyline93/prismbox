package repository

import (
	"context"
	"encoding/json"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/pkg/logger"
	"gorm.io/gorm"
)

// mediaRepository 媒体仓储实现
type mediaRepository struct {
	db     *gorm.DB
	logger logger.Logger
}

// NewMediaRepository 创建媒体仓储
func NewMediaRepository(db *gorm.DB) MediaRepository {
	return &mediaRepository{
		db:     db,
		logger: logger.New("repository.media"),
	}
}

// Create 创建媒体记录
func (r *mediaRepository) Create(ctx context.Context, media *models.Media) error {
	return r.db.WithContext(ctx).Create(media).Error
}

// FindByUUID 根据UUID查找媒体
func (r *mediaRepository) FindByUUID(ctx context.Context, uuid string) (*models.Media, error) {
	var media models.Media
	err := r.db.WithContext(ctx).Where("uuid = ?", uuid).First(&media).Error
	if err != nil {
		return nil, err
	}
	return &media, nil
}

// FindByUserID 根据用户ID查找媒体列表
func (r *mediaRepository) FindByUserID(ctx context.Context, userID uint, limit, offset int) ([]*models.Media, error) {
	var medias []*models.Media
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND deleted = ?", userID, false).
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&medias).Error
	return medias, err
}

// Update 更新媒体记录
func (r *mediaRepository) Update(ctx context.Context, uuid string, updates map[string]interface{}) error {
	// 记录更新操作日志
	updatesJSON, _ := json.Marshal(updates)
	r.logger.Info("updating media record",
		logger.String("uuid", uuid),
		logger.String("updates", string(updatesJSON)),
		logger.Int("fields_count", len(updates)),
	)

	// 执行更新
	result := r.db.WithContext(ctx).
		Model(&models.Media{}).
		Where("uuid = ?", uuid).
		Updates(updates)

	if result.Error != nil {
		r.logger.Error("failed to update media record",
			logger.String("uuid", uuid),
			logger.Error(result.Error),
		)
		return result.Error
	}

	// 检查是否真的更新了记录
	if result.RowsAffected == 0 {
		r.logger.Warn("update media record: no rows affected",
			logger.String("uuid", uuid),
			logger.String("updates", string(updatesJSON)),
		)
		return gorm.ErrRecordNotFound
	}

	// 记录更新结果
	r.logger.Info("media record updated successfully",
		logger.String("uuid", uuid),
		logger.Int64("rows_affected", result.RowsAffected),
	)

	// 如果更新成功，查询并打印更新后的记录
	if result.RowsAffected > 0 {
		var media models.Media
		if err := r.db.WithContext(ctx).Where("uuid = ?", uuid).First(&media).Error; err == nil {
			mediaJSON, _ := json.Marshal(media)
			r.logger.Debug("updated media record",
				logger.String("uuid", uuid),
				logger.String("media", string(mediaJSON)),
			)
		}
	}

	return nil
}

// Delete 删除媒体记录（软删除）
func (r *mediaRepository) Delete(ctx context.Context, uuid string) error {
	return r.db.WithContext(ctx).
		Model(&models.Media{}).
		Where("uuid = ?", uuid).
		Update("deleted", true).Error
}

// FindByHash 根据Hash查找媒体（用于去重）
func (r *mediaRepository) FindByHash(ctx context.Context, userID uint, hash string) (*models.Media, error) {
	var media models.Media
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND hash = ? AND deleted = ?", userID, hash, false).
		First(&media).Error
	if err != nil {
		return nil, err
	}
	return &media, nil
}

// FindByUserIDWithFilter 根据用户ID和过滤条件查找媒体列表
func (r *mediaRepository) FindByUserIDWithFilter(ctx context.Context, userID uint, itemType string, limit, offset int) ([]*models.Media, error) {
	var medias []*models.Media
	query := r.db.WithContext(ctx).
		Where("user_id = ? AND deleted = ?", userID, false)

	if itemType != "" {
		query = query.Where("item_type = ?", itemType)
	}

	err := query.
		Order("created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&medias).Error
	return medias, err
}

// CountByUserID 统计用户媒体数量
func (r *mediaRepository) CountByUserID(ctx context.Context, userID uint, itemType string) (int64, error) {
	var count int64
	query := r.db.WithContext(ctx).
		Model(&models.Media{}).
		Where("user_id = ? AND deleted = ?", userID, false)

	if itemType != "" {
		query = query.Where("item_type = ?", itemType)
	}

	err := query.Count(&count).Error
	return count, err
}

// FindHashesByUserID 根据用户ID和哈希列表查找已存在的哈希
func (r *mediaRepository) FindHashesByUserID(ctx context.Context, userID uint, hashes []string) ([]string, error) {
	var existingHashes []string
	err := r.db.WithContext(ctx).
		Model(&models.Media{}).
		Where("user_id = ? AND hash IN ? AND deleted = ?", userID, hashes, false).
		Pluck("hash", &existingHashes).Error
	return existingHashes, err
}

// FindChangesSince 查找指定时间之后的媒体变更
func (r *mediaRepository) FindChangesSince(ctx context.Context, userID uint, since interface{}) ([]*models.Media, error) {
	var medias []*models.Media
	query := r.db.WithContext(ctx).
		Where("user_id = ?", userID)

	if since != nil {
		query = query.Where("updated_at > ?", since)
	}

	err := query.
		Order("updated_at ASC").
		Find(&medias).Error
	return medias, err
}

// FindActiveByUUIDAndUser 查找一个未被软删除的媒体记录
func (r *mediaRepository) FindActiveByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error) {
	var media models.Media
	err := r.db.WithContext(ctx).
		Where("uuid = ? AND user_id = ? AND deleted = ?", uuid, userID, false).
		First(&media).Error
	if err != nil {
		return nil, err
	}
	return &media, nil
}

// FindInBinByUUIDAndUser 查找一个在回收站中（已被软删除）的媒体记录
func (r *mediaRepository) FindInBinByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error) {
	var media models.Media
	err := r.db.WithContext(ctx).
		Where("uuid = ? AND user_id = ? AND deleted = ?", uuid, userID, true).
		First(&media).Error
	if err != nil {
		return nil, err
	}
	return &media, nil
}

// Purge 永久删除媒体记录（硬删除）
func (r *mediaRepository) Purge(ctx context.Context, uuid string) error {
	return r.db.WithContext(ctx).
		Where("uuid = ?", uuid).
		Delete(&models.Media{}).Error
}
