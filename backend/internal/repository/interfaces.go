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
