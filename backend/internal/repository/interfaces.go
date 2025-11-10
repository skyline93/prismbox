package repository

import (
	"context"

	"github.com/album/backend/internal/database/models"
)

// MediaRepository 媒体仓储接口
type MediaRepository interface {
	// Create 创建媒体记录
	Create(ctx context.Context, media *models.Media) error

	// FindByUUID 根据UUID查找媒体
	FindByUUID(ctx context.Context, uuid string) (*models.Media, error)

	// FindByUserID 根据用户ID查找媒体列表
	FindByUserID(ctx context.Context, userID uint, limit, offset int) ([]*models.Media, error)

	// Update 更新媒体记录
	Update(ctx context.Context, uuid string, updates map[string]interface{}) error

	// Delete 删除媒体记录（软删除）
	Delete(ctx context.Context, uuid string) error

	// FindByHash 根据Hash查找媒体（用于去重）
	FindByHash(ctx context.Context, userID uint, hash string) (*models.Media, error)
}

// UserRepository 用户仓储接口
// 负责用户注册、查询及资料更新等操作。
type UserRepository interface {
	Create(ctx context.Context, user *models.User) error
	FindByEmail(ctx context.Context, email string) (*models.User, error)
	FindByID(ctx context.Context, id uint) (*models.User, error)
	ExistsByUsernameOrEmail(ctx context.Context, username, email string) (bool, error)
	UpdatePassword(ctx context.Context, userID uint, hashedPassword string) error
	UpdateAvatar(ctx context.Context, userID uint, filename string) error
}

// AuthProviderRepository 认证提供商仓储接口
// 用于维护用户与第三方账号的关联关系。
type AuthProviderRepository interface {
	Create(ctx context.Context, provider *models.AuthProvider) error
	FindByProviderAndUserID(ctx context.Context, provider string, userID uint) (*models.AuthProvider, error)
	FindByProviderUserID(ctx context.Context, provider, providerUserID string) (*models.AuthProvider, error)
}

// RefreshTokenRepository 刷新令牌仓储接口
type RefreshTokenRepository interface {
	Create(ctx context.Context, token *models.RefreshToken) error
	FindActiveByToken(ctx context.Context, token string) (*models.RefreshToken, error)
	RevokeByToken(ctx context.Context, token string) (bool, error)
}
