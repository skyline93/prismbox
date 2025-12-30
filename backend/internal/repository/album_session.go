package repository

import (
	"context"
	"fmt"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/pkg/logger"
	"gorm.io/gorm"
)

// albumSessionRepository 相册会话仓储实现
type albumSessionRepository struct {
	db     *gorm.DB
	logger logger.Logger
}

// NewAlbumSessionRepository 创建相册会话仓储
func NewAlbumSessionRepository(db *gorm.DB) AlbumSessionRepository {
	return &albumSessionRepository{
		db:     db,
		logger: logger.New("repository.album_session"),
	}
}

// Create 创建会话记录
func (r *albumSessionRepository) Create(ctx context.Context, session *models.AlbumSession) error {
	return r.db.WithContext(ctx).Create(session).Error
}

// FindByID 根据ID查找会话
func (r *albumSessionRepository) FindByID(ctx context.Context, id string) (*models.AlbumSession, error) {
	var session models.AlbumSession
	err := r.db.WithContext(ctx).Where("id = ?", id).First(&session).Error
	if err != nil {
		return nil, err
	}
	return &session, nil
}

// FindByAlbumID 根据相册ID查找所有会话
func (r *albumSessionRepository) FindByAlbumID(ctx context.Context, albumID string) ([]*models.AlbumSession, error) {
	var sessions []*models.AlbumSession
	err := r.db.WithContext(ctx).
		Where("album_id = ?", albumID).
		Find(&sessions).Error
	return sessions, err
}

// Delete 删除会话
func (r *albumSessionRepository) Delete(ctx context.Context, id string) error {
	result := r.db.WithContext(ctx).Where("id = ?", id).Delete(&models.AlbumSession{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return fmt.Errorf("session not found: %s", id)
	}
	return nil
}

// DeleteByAlbumID 删除相册的所有会话
func (r *albumSessionRepository) DeleteByAlbumID(ctx context.Context, albumID string) error {
	return r.db.WithContext(ctx).Where("album_id = ?", albumID).Delete(&models.AlbumSession{}).Error
}

