package repository

import (
	"context"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/pkg/logger"
	"gorm.io/gorm"
)

// albumRepository 相册仓储实现
type albumRepository struct {
	db     *gorm.DB
	logger logger.Logger
}

// NewAlbumRepository 创建相册仓储
func NewAlbumRepository(db *gorm.DB) AlbumRepository {
	return &albumRepository{
		db:     db,
		logger: logger.New("repository.album"),
	}
}

// Create 创建相册
func (r *albumRepository) Create(ctx context.Context, album *models.Album) error {
	return r.db.WithContext(ctx).Create(album).Error
}

// FindByUUID 根据UUID查找相册
func (r *albumRepository) FindByUUID(ctx context.Context, uuid string) (*models.Album, error) {
	var album models.Album
	err := r.db.WithContext(ctx).Where("uuid = ?", uuid).First(&album).Error
	if err != nil {
		return nil, err
	}
	return &album, nil
}

// FindByUserID 根据用户ID查找相册列表
func (r *albumRepository) FindByUserID(ctx context.Context, userID uint) ([]*models.Album, error) {
	var albums []*models.Album
	err := r.db.WithContext(ctx).
		Where("user_id = ?", userID).
		Order("created_at DESC").
		Find(&albums).Error
	return albums, err
}

// Update 更新相册信息
func (r *albumRepository) Update(ctx context.Context, album *models.Album) error {
	return r.db.WithContext(ctx).Save(album).Error
}

// Delete 删除相册
func (r *albumRepository) Delete(ctx context.Context, uuid string) error {
	return r.db.WithContext(ctx).Where("uuid = ?", uuid).Delete(&models.Album{}).Error
}
