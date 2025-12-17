package database

import (
	"fmt"

	"github.com/album/backend/internal/database/models"
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

	return nil
}
