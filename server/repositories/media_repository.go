package repositories

import (
	"context"
	"fmt"
	"server/models"
	"server/replicator"

	"gorm.io/gorm"
)

// MediaRepository 封装了 Media 模型的数据访问逻辑。
type MediaRepository struct {
	db *gorm.DB
}

// NewMediaRepository 创建 MediaRepository 的一个新实例。
func NewMediaRepository(db *gorm.DB) *MediaRepository {
	return &MediaRepository{db: db}
}

// --- 实现 replicator.WritableRepository[*models.Media] 接口 ---

// Create 插入一条新的媒体记录。
func (r *MediaRepository) Create(ctx context.Context, media *models.Media) (*models.Media, error) {
	return media, r.db.WithContext(ctx).Create(media).Error
}

// Update 更新一条已存在的媒体记录。软删除和恢复操作会调用此方法。
func (r *MediaRepository) Update(ctx context.Context, media *models.Media) (*models.Media, error) {
	return media, r.db.WithContext(ctx).Save(media).Error
}

// Delete 永久删除一条媒体记录及其所有关联数据（事务性）。
// Purge 操作会调用此方法，replicator 将记录一个 DELETED 事件。
func (r *MediaRepository) Delete(ctx context.Context, media *models.Media) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		// 1. 删除相册关联
		if err := tx.Exec("DELETE FROM album_items WHERE media_id = ?", media.ID).Error; err != nil {
			return fmt.Errorf("failed to disassociate from albums: %w", err)
		}
		// 2. 删除分享记录
		if err := tx.Unscoped().Where("media_id = ?", media.ID).Delete(&models.Share{}).Error; err != nil {
			return fmt.Errorf("failed to delete shares: %w", err)
		}
		// 3. 删除圈子媒体引用
		if err := tx.Unscoped().Where("media_uuid = ?", media.UUID).Delete(&models.GroupMedia{}).Error; err != nil {
			return fmt.Errorf("failed to delete group media references: %w", err)
		}
		// 4. 将关联的封面设置为空
		if err := tx.Model(&models.Album{}).Where("cover_media_uuid = ?", media.UUID).Update("cover_media_uuid", nil).Error; err != nil {
			return fmt.Errorf("failed to nullify album covers: %w", err)
		}
		if err := tx.Model(&models.Group{}).Where("cover_media_uuid = ?", media.UUID).Update("cover_media_uuid", "").Error; err != nil {
			return fmt.Errorf("failed to clear group covers: %w", err)
		}
		// 5. 永久删除媒体记录本身
		if err := tx.Unscoped().Delete(&models.Media{}, media.ID).Error; err != nil {
			return fmt.Errorf("failed to permanently delete media record: %w", err)
		}
		return nil
	})
}

// --- 特定于业务的查询方法 ---

// FindByUserAndHash 通过用户ID和文件哈希查找媒体（用于秒传检查）。
func (r *MediaRepository) FindByUserAndHash(ctx context.Context, userID uint, hash string) (*models.Media, error) {
	var media models.Media
	err := r.db.WithContext(ctx).First(&media, "user_id = ? AND hash = ?", userID, hash).Error
	return &media, err
}

// FindActiveByUUIDAndUser 通过UUID和用户ID查找一个未被软删除的媒体。
func (r *MediaRepository) FindActiveByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error) {
	var media models.Media
	err := r.db.WithContext(ctx).Where("uuid = ? AND user_id = ? AND deleted = ?", uuid, userID, false).First(&media).Error
	return &media, err
}

// FindInBinByUUIDAndUser 通过UUID和用户ID查找一个在回收站中的媒体。
func (r *MediaRepository) FindInBinByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error) {
	var media models.Media
	err := r.db.WithContext(ctx).Where("uuid = ? AND user_id = ? AND deleted = ?", uuid, userID, true).First(&media).Error
	return &media, err
}

type ReplicatorAwareMediaRepository struct {
	// 用于写操作，确保变更会被 replicator 记录
	writableRepo replicator.WritableRepository[*models.Media]
	// 用于所有自定义的读/查询操作
	readableRepo *MediaRepository
}

func NewReplicatorAwareMediaRepository(
	writable replicator.WritableRepository[*models.Media],
	readable *MediaRepository,
) *ReplicatorAwareMediaRepository {
	return &ReplicatorAwareMediaRepository{
		writableRepo: writable,
		readableRepo: readable,
	}
}

// Create 将写操作委托给被 replicator 包装的仓储。
func (r *ReplicatorAwareMediaRepository) Create(ctx context.Context, media *models.Media) (*models.Media, error) {
	return r.writableRepo.Create(ctx, media)
}

// Update 将写操作委托给被 replicator 包装的仓储。
func (r *ReplicatorAwareMediaRepository) Update(ctx context.Context, media *models.Media) (*models.Media, error) {
	return r.writableRepo.Update(ctx, media)
}

// Delete 将写操作委托给被 replicator 包装的仓储。
func (r *ReplicatorAwareMediaRepository) Delete(ctx context.Context, media *models.Media) error {
	return r.writableRepo.Delete(ctx, media)
}

// FindByUserAndHash 将读操作委托给原始的仓储。
func (r *ReplicatorAwareMediaRepository) FindByUserAndHash(ctx context.Context, userID uint, hash string) (*models.Media, error) {
	return r.readableRepo.FindByUserAndHash(ctx, userID, hash)
}

// FindActiveByUUIDAndUser 将读操作委托给原始的仓储。
func (r *ReplicatorAwareMediaRepository) FindActiveByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error) {
	return r.readableRepo.FindActiveByUUIDAndUser(ctx, uuid, userID)
}

// FindInBinByUUIDAndUser 将读操作委托给原始的仓储。
func (r *ReplicatorAwareMediaRepository) FindInBinByUUIDAndUser(ctx context.Context, uuid string, userID uint) (*models.Media, error) {
	return r.readableRepo.FindInBinByUUIDAndUser(ctx, uuid, userID)
}
