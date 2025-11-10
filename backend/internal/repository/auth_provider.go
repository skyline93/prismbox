package repository

import (
	"context"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

type authProviderRepository struct {
	db *gorm.DB
}

// NewAuthProviderRepository 创建认证提供商仓储。
func NewAuthProviderRepository(db *gorm.DB) AuthProviderRepository {
	return &authProviderRepository{db: db}
}

func (r *authProviderRepository) Create(ctx context.Context, provider *models.AuthProvider) error {
	return r.db.WithContext(ctx).Create(provider).Error
}

func (r *authProviderRepository) FindByProviderAndUserID(ctx context.Context, provider string, userID uint) (*models.AuthProvider, error) {
	var record models.AuthProvider
	if err := r.db.WithContext(ctx).
		Where("provider_name = ? AND user_id = ?", provider, userID).
		First(&record).Error; err != nil {
		return nil, err
	}
	return &record, nil
}

func (r *authProviderRepository) FindByProviderUserID(ctx context.Context, provider, providerUserID string) (*models.AuthProvider, error) {
	var record models.AuthProvider
	if err := r.db.WithContext(ctx).
		Where("provider_name = ? AND provider_user_id = ?", provider, providerUserID).
		First(&record).Error; err != nil {
		return nil, err
	}
	return &record, nil
}
