package changelog

import (
	"context"
	"time"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
)

// MediaRepositoryAdapter 媒体仓储适配器
// 将新架构的 MediaRepository 适配到 changelog 的 WritableRepository 接口
type MediaRepositoryAdapter struct {
	repo repository.MediaRepository
}

// NewMediaRepositoryAdapter 创建媒体仓储适配器
func NewMediaRepositoryAdapter(repo repository.MediaRepository) WritableRepository[*models.Media] {
	return &MediaRepositoryAdapter{repo: repo}
}

// Create 适配 Create 方法
func (a *MediaRepositoryAdapter) Create(
	ctx context.Context,
	media *models.Media,
) (*models.Media, error) {
	if err := a.repo.Create(ctx, media); err != nil {
		return nil, err
	}
	// 重新查询获取完整数据（包括自动填充的字段）
	created, err := a.repo.FindByUUID(ctx, media.UUID)
	if err != nil {
		return nil, err
	}
	return created, nil
}

// Update 适配 Update 方法
// 注意：新架构的 Update 使用 map[string]interface{}，需要转换
func (a *MediaRepositoryAdapter) Update(
	ctx context.Context,
	media *models.Media,
) (*models.Media, error) {
	// 从 media 提取更新字段
	updates := extractMediaUpdates(media)

	if err := a.repo.Update(ctx, media.UUID, updates); err != nil {
		return nil, err
	}

	// 重新查询获取最新数据
	updated, err := a.repo.FindByUUID(ctx, media.UUID)
	if err != nil {
		return nil, err
	}
	return updated, nil
}

// Delete 适配 Delete 方法
func (a *MediaRepositoryAdapter) Delete(
	ctx context.Context,
	media *models.Media,
) error {
	return a.repo.Delete(ctx, media.UUID)
}

// extractMediaUpdates 从 Media 模型提取更新字段
func extractMediaUpdates(media *models.Media) map[string]interface{} {
	updates := make(map[string]interface{})

	// 只提取可更新的字段
	if media.Deleted {
		updates["deleted"] = true
	}
	if media.ProcessingStatus != "" {
		updates["processing_status"] = media.ProcessingStatus
	}
	if media.Width > 0 {
		updates["width"] = media.Width
	}
	if media.Height > 0 {
		updates["height"] = media.Height
	}
	if media.Duration != nil {
		updates["duration"] = media.Duration
	}
	if media.MediaTakenAt != nil {
		updates["media_taken_at"] = media.MediaTakenAt
	}
	if media.CameraMake != nil {
		updates["camera_make"] = media.CameraMake
	}
	if media.CameraModel != nil {
		updates["camera_model"] = media.CameraModel
	}
	if media.Aperture != nil {
		updates["aperture"] = media.Aperture
	}
	if media.ShutterSpeed != nil {
		updates["shutter_speed"] = media.ShutterSpeed
	}
	if media.ISO != nil {
		updates["iso"] = media.ISO
	}
	if media.Latitude != nil {
		updates["latitude"] = media.Latitude
	}
	if media.Longitude != nil {
		updates["longitude"] = media.Longitude
	}
	if media.BackupStatus != "" {
		updates["backup_status"] = media.BackupStatus
	}
	if media.BackupStartedAt != nil {
		updates["backup_started_at"] = media.BackupStartedAt
	}
	if media.BackupCompletedAt != nil {
		updates["backup_completed_at"] = media.BackupCompletedAt
	}
	if media.BackupError != "" {
		updates["backup_error"] = media.BackupError
	}
	if media.ThumbHash != "" {
		updates["thumb_hash"] = media.ThumbHash
	}

	return updates
}

// ChangelogAwareMediaRepository 包装器，将 WritableRepository 适配回 MediaRepository
// 这样业务代码可以继续使用 MediaRepository 接口
type ChangelogAwareMediaRepository struct {
	writableRepo WritableRepository[*models.Media]
	readableRepo repository.MediaRepository
}

// NewChangelogAwareMediaRepository 创建包装后的媒体仓储
func NewChangelogAwareMediaRepository(
	writable WritableRepository[*models.Media],
	readable repository.MediaRepository,
) repository.MediaRepository {
	return &ChangelogAwareMediaRepository{
		writableRepo: writable,
		readableRepo: readable,
	}
}

// Create 创建媒体记录（使用包装后的仓储，自动记录变更日志）
func (r *ChangelogAwareMediaRepository) Create(ctx context.Context, media *models.Media) error {
	_, err := r.writableRepo.Create(ctx, media)
	return err
}

// Update 更新媒体记录（使用包装后的仓储，自动记录变更日志）
func (r *ChangelogAwareMediaRepository) Update(ctx context.Context, uuid string, updates map[string]interface{}) error {
	// 先查询现有记录
	existing, err := r.readableRepo.FindByUUID(ctx, uuid)
	if err != nil {
		return err
	}

	// 应用更新
	for k, v := range updates {
		switch k {
		case "deleted":
			if val, ok := v.(bool); ok {
				existing.Deleted = val
			}
		case "processing_status":
			if val, ok := v.(string); ok {
				existing.ProcessingStatus = val
			}
		case "width":
			if val, ok := v.(int); ok {
				existing.Width = val
			}
		case "height":
			if val, ok := v.(int); ok {
				existing.Height = val
			}
		case "duration":
			if val, ok := v.(*float64); ok {
				existing.Duration = val
			}
		case "media_taken_at":
			if val, ok := v.(*time.Time); ok {
				existing.MediaTakenAt = val
			}
		case "backup_status":
			if val, ok := v.(string); ok {
				existing.BackupStatus = val
			}
		case "thumb_hash":
			if val, ok := v.(string); ok {
				existing.ThumbHash = val
			}
			// ... 其他字段
		}
	}

	// 使用包装后的仓储更新（自动记录变更日志）
	_, err = r.writableRepo.Update(ctx, existing)
	return err
}

// Delete 删除媒体记录（使用包装后的仓储，自动记录变更日志）
func (r *ChangelogAwareMediaRepository) Delete(ctx context.Context, uuid string) error {
	// 先查询现有记录
	existing, err := r.readableRepo.FindByUUID(ctx, uuid)
	if err != nil {
		return err
	}

	// 使用包装后的仓储删除（自动记录变更日志）
	return r.writableRepo.Delete(ctx, existing)
}

// 其他方法直接透传给 readableRepo
func (r *ChangelogAwareMediaRepository) FindByUUID(ctx context.Context, uuid string) (*models.Media, error) {
	return r.readableRepo.FindByUUID(ctx, uuid)
}

func (r *ChangelogAwareMediaRepository) FindByUserID(ctx context.Context, userID uint, limit, offset int) ([]*models.Media, error) {
	return r.readableRepo.FindByUserID(ctx, userID, limit, offset)
}

func (r *ChangelogAwareMediaRepository) FindByHash(ctx context.Context, userID uint, hash string) (*models.Media, error) {
	return r.readableRepo.FindByHash(ctx, userID, hash)
}

func (r *ChangelogAwareMediaRepository) FindByUserIDWithFilter(ctx context.Context, userID uint, itemType string, limit, offset int) ([]*models.Media, error) {
	return r.readableRepo.FindByUserIDWithFilter(ctx, userID, itemType, limit, offset)
}

func (r *ChangelogAwareMediaRepository) CountByUserID(ctx context.Context, userID uint, itemType string) (int64, error) {
	return r.readableRepo.CountByUserID(ctx, userID, itemType)
}

func (r *ChangelogAwareMediaRepository) FindHashesByUserID(ctx context.Context, userID uint, hashes []string) ([]string, error) {
	return r.readableRepo.FindHashesByUserID(ctx, userID, hashes)
}

func (r *ChangelogAwareMediaRepository) FindChangesSince(ctx context.Context, userID uint, since interface{}) ([]*models.Media, error) {
	return r.readableRepo.FindChangesSince(ctx, userID, since)
}

func (r *ChangelogAwareMediaRepository) FindActiveByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error) {
	return r.readableRepo.FindActiveByUUIDAndUser(ctx, uuid, userID)
}

func (r *ChangelogAwareMediaRepository) FindInBinByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error) {
	return r.readableRepo.FindInBinByUUIDAndUser(ctx, uuid, userID)
}

func (r *ChangelogAwareMediaRepository) Purge(ctx context.Context, uuid string) error {
	// Purge 是硬删除，直接调用原始仓储
	// 注意：如果需要记录变更日志，应该在调用 Purge 之前先查询记录
	return r.readableRepo.Purge(ctx, uuid)
}
