package repository

import (
	"context"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

type refreshTokenRepository struct {
	db *gorm.DB
}

// NewRefreshTokenRepository 创建刷新令牌仓储。
func NewRefreshTokenRepository(db *gorm.DB) RefreshTokenRepository {
	return &refreshTokenRepository{db: db}
}

func (r *refreshTokenRepository) Create(ctx context.Context, token *models.RefreshToken) error {
	return r.db.WithContext(ctx).Create(token).Error
}

func (r *refreshTokenRepository) FindActiveByToken(ctx context.Context, token string) (*models.RefreshToken, error) {
	var record models.RefreshToken
	if err := r.db.WithContext(ctx).
		Where("token = ? AND is_revoked = ?", token, false).
		First(&record).Error; err != nil {
		return nil, err
	}
	return &record, nil
}

func (r *refreshTokenRepository) RevokeByToken(ctx context.Context, token string) (bool, error) {
	res := r.db.WithContext(ctx).
		Model(&models.RefreshToken{}).
		Where("token = ?", token).
		Update("is_revoked", true)

	if res.Error != nil {
		return false, res.Error
	}

	return res.RowsAffected > 0, nil
}
