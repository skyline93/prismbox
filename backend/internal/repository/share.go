package repository

import (
	"context"
	"time"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

// shareRepository 分享仓储实现
type shareRepository struct {
	db *gorm.DB
}

// NewShareRepository 创建分享仓储
func NewShareRepository(db *gorm.DB) ShareRepository {
	return &shareRepository{db: db}
}

func (r *shareRepository) Create(ctx context.Context, share *models.Share) error {
	return r.db.WithContext(ctx).Create(share).Error
}

func (r *shareRepository) FindByToken(ctx context.Context, token string) (*models.Share, error) {
	var share models.Share
	err := r.db.WithContext(ctx).
		Preload("Media").
		Preload("Owner").
		Where("share_token = ?", token).
		First(&share).Error
	if err != nil {
		return nil, err
	}
	return &share, nil
}

func (r *shareRepository) FindByTargetUserID(ctx context.Context, userID uint) ([]*models.Share, error) {
	var shares []*models.Share
	err := r.db.WithContext(ctx).
		Preload("Media").
		Preload("Owner").
		Where("target_user_id = ? AND is_revoked = ? AND expires_at > ?", userID, false, time.Now()).
		Find(&shares).Error
	return shares, err
}

func (r *shareRepository) Revoke(ctx context.Context, shareID uint) error {
	return r.db.WithContext(ctx).
		Model(&models.Share{}).
		Where("id = ?", shareID).
		Update("is_revoked", true).Error
}

