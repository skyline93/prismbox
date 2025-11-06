package repository

import (
	"context"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

// mediaRepository 媒体仓储实现
type mediaRepository struct {
	db *gorm.DB
}

// NewMediaRepository 创建媒体仓储
func NewMediaRepository(db *gorm.DB) MediaRepository {
	return &mediaRepository{
		db: db,
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
	return r.db.WithContext(ctx).
		Model(&models.Media{}).
		Where("uuid = ?", uuid).
		Updates(updates).Error
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
