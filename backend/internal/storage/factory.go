package storage

import (
	"fmt"

	"github.com/album/backend/internal/config/modules"
	"github.com/album/backend/internal/storage/interfaces"
	"github.com/album/backend/internal/storage/primary/local"
)

// NewPrimaryStorage 创建主存储
func NewPrimaryStorage(cfg *modules.PrimaryStorageConfig) (interfaces.PrimaryStorage, error) {
	switch cfg.Type {
	case "local":
		if cfg.Local == nil {
			return nil, fmt.Errorf("local config is required")
		}
		return local.NewLocalStorage(cfg.Local)
	default:
		return nil, fmt.Errorf("unsupported primary storage type: %s", cfg.Type)
	}
}

// NewSecondaryStorage 创建次存储（可选）
func NewSecondaryStorage(cfg *modules.SecondaryStorageConfig) (interfaces.SecondaryStorage, error) {
	if cfg == nil || !cfg.Enabled {
		return nil, nil // 未启用次存储
	}

	switch cfg.Type {
	case "openlist":
		// TODO: 实现 OpenList 存储
		return nil, fmt.Errorf("openlist storage not implemented yet")
	case "s3":
		// TODO: 实现 S3 存储
		return nil, fmt.Errorf("s3 storage not implemented yet")
	case "oss":
		// TODO: 实现 OSS 存储
		return nil, fmt.Errorf("oss storage not implemented yet")
	case "cos":
		// TODO: 实现 COS 存储
		return nil, fmt.Errorf("cos storage not implemented yet")
	default:
		return nil, fmt.Errorf("unsupported secondary storage type: %s", cfg.Type)
	}
}
