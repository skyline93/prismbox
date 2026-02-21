package storage

import (
	"fmt"
	"path/filepath"
	"strings"

	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage/config"
	"github.com/album/backend/internal/storage/interfaces"
	"github.com/album/backend/internal/storage/pooluri"
	"github.com/album/backend/internal/storage/primary/local"
	"gorm.io/gorm"
)

// NewPrimaryStorage 创建主存储
func NewPrimaryStorage(cfg *config.PrimaryStorageConfig, db *gorm.DB) (interfaces.PrimaryStorage, error) {
	switch cfg.Type {
	case "local":
		if cfg.Local == nil {
			return nil, fmt.Errorf("local config is required")
		}
		// DataDir 必填，且规范化为绝对路径（唯一校验处，避免散落）
		dataDir := strings.TrimSpace(cfg.Local.DataDir)
		if dataDir == "" {
			return nil, fmt.Errorf("storage.primary.local.data_dir is required")
		}
		absDir, err := filepath.Abs(dataDir)
		if err != nil {
			return nil, fmt.Errorf("storage.primary.local.data_dir: %w", err)
		}
		if err := pooluri.ValidateLocalPath(absDir); err != nil {
			return nil, fmt.Errorf("storage.primary.local.data_dir: %w", err)
		}
		cfg.Local.DataDir = absDir
		poolRepo := repository.NewStoragePoolRepository(db)
		// 就地填充默认子路径（temp/cache）
		if cfg.Local.Temp != nil && cfg.Local.Temp.BasePath == "" {
			cfg.Local.Temp.BasePath = filepath.Join(absDir, "temp")
		}
		if cfg.Local.Performance != nil && cfg.Local.Performance.CacheEnabled && cfg.Local.Performance.CachePath == "" {
			cfg.Local.Performance.CachePath = filepath.Join(absDir, "cache")
		}
		return local.NewLocalStorage(cfg.Local, poolRepo)
	default:
		return nil, fmt.Errorf("unsupported primary storage type: %s", cfg.Type)
	}
}

// NewSecondaryStorage 创建次存储（可选）
func NewSecondaryStorage(cfg *config.SecondaryStorageConfig) (interfaces.SecondaryStorage, error) {
	if cfg == nil || !cfg.Enabled {
		return nil, nil // 未启用次存储
	}

	switch cfg.Type {
	case "openlist":
		return nil, fmt.Errorf("openlist storage not implemented yet")
	case "s3":
		return nil, fmt.Errorf("s3 storage not implemented yet")
	case "oss":
		return nil, fmt.Errorf("oss storage not implemented yet")
	case "cos":
		return nil, fmt.Errorf("cos storage not implemented yet")
	default:
		return nil, fmt.Errorf("unsupported secondary storage type: %s", cfg.Type)
	}
}
