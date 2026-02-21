package database

import (
	"fmt"

	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/storage/pooluri"
	"github.com/album/backend/pkg/gq"
	"gorm.io/gorm"
)

// RunAutoMigrations 执行所有核心模型及 gq 任务表的自动迁移。
func RunAutoMigrations(db *gorm.DB) error {
	if err := db.AutoMigrate(
		&models.User{},
		&models.AuthProvider{},
		&models.RefreshToken{},
		&models.Media{},
		&models.Album{},
		&models.StoragePool{},
		&models.Group{},
		&models.GroupMember{},
		&models.GroupPost{},
		&models.GroupMedia{},
		&models.Comment{},
		&models.CommentLike{},
		&models.Like{},
		&models.GroupInvite{},
		&models.Share{},
		&models.SyncCheckpoint{},
	); err != nil {
		return fmt.Errorf("auto migrate models: %w", err)
	}

	if err := gq.AutoMigrate(db); err != nil {
		return fmt.Errorf("auto migrate gq: %w", err)
	}

	// 一次性迁移：将 storage_pools 中 local_path 非空且 location 为空的记录转为 location URI。
	if err := migrateStoragePoolLocation(db); err != nil {
		return fmt.Errorf("migrate storage pool location: %w", err)
	}

	return nil
}

// migrateStoragePoolLocation 将已有 local_path 的本地池写入 location（local:///abs(path)），仅处理 location 为空且 local_path 非空的记录。
func migrateStoragePoolLocation(db *gorm.DB) error {
	var pools []models.StoragePool
	if err := db.Where("storage_type = ? AND (location IS NULL OR location = '') AND local_path != ''", "local").Find(&pools).Error; err != nil {
		return err
	}
	for i := range pools {
		loc, err := pooluri.BuildLocal(pools[i].LocalPath)
		if err != nil {
			return fmt.Errorf("pool %s: %w", pools[i].UUID, err)
		}
		if err := db.Model(&pools[i]).Update("location", loc).Error; err != nil {
			return err
		}
	}
	return nil
}
