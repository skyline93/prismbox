package storage

import (
	"fmt"
	"path/filepath"

	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/storage/interfaces"
	"github.com/album/backend/internal/storage/primary/local"
	"gorm.io/gorm"
)

// NewPrimaryStorage 创建主存储
func NewPrimaryStorage(cfg *PrimaryStorageConfig, db *gorm.DB) (interfaces.PrimaryStorage, error) {
	switch cfg.Type {
	case "local":
		if cfg.Local == nil {
			return nil, fmt.Errorf("local config is required")
		}
		poolRepo := repository.NewStoragePoolRepository(db)
		dataDir := cfg.Local.DataDir
		if dataDir == "" {
			dataDir = "./data"
		}
		tempCfg := convertTempFileConfig(cfg.Local.Temp)
		if tempCfg != nil && tempCfg.BasePath == "" {
			tempCfg.BasePath = filepath.Join(dataDir, "temp")
		}
		perfCfg := convertPerformanceConfig(cfg.Local.Performance)
		if perfCfg != nil && perfCfg.CachePath == "" && perfCfg.CacheEnabled {
			perfCfg.CachePath = filepath.Join(dataDir, "cache")
		}
		localCfg := &local.LocalStorageConfig{
			BasePath:    dataDir, // PathResolver 用此作为 temp/staging 根
			PoolManager: convertPoolManagerConfig(cfg.Local.PoolManager),
			Temp:        tempCfg,
			Processing:  convertProcessingConfig(cfg.Local.Processing),
			Performance: perfCfg,
		}
		return local.NewLocalStorage(localCfg, poolRepo)
	default:
		return nil, fmt.Errorf("unsupported primary storage type: %s", cfg.Type)
	}
}

// NewSecondaryStorage 创建次存储（可选）
func NewSecondaryStorage(cfg *SecondaryStorageConfig) (interfaces.SecondaryStorage, error) {
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

// convertPoolManagerConfig 转换 PoolManagerConfig
func convertPoolManagerConfig(cfg *PoolManagerConfig) *local.PoolManagerConfig {
	if cfg == nil {
		return nil
	}
	return &local.PoolManagerConfig{
		DeltaChannelSize:     cfg.DeltaChannelSize,
		DeltaBatchSize:       cfg.DeltaBatchSize,
		FlushInterval:        cfg.FlushInterval,
		CacheRefreshInterval: cfg.CacheRefreshInterval,
		ReconcileInterval:    cfg.ReconcileInterval,
	}
}

// convertTempFileConfig 转换 TempFileConfig
func convertTempFileConfig(cfg *TempFileConfig) *local.TempFileConfig {
	if cfg == nil {
		return nil
	}
	return &local.TempFileConfig{
		BasePath:        cfg.BasePath,
		MaxAge:          cfg.MaxAge,
		MaxSize:         cfg.MaxSize,
		CleanupInterval: cfg.CleanupInterval,
	}
}

// convertProcessingConfig 转换 ProcessingConfig
func convertProcessingConfig(cfg *ProcessingConfig) *local.ProcessingConfig {
	if cfg == nil {
		return nil
	}
	return &local.ProcessingConfig{
		EnableCompression: cfg.EnableCompression,
		CompressionLevel:  cfg.CompressionLevel,
		EnableEncryption:  cfg.EnableEncryption,
		EncryptionKeyPath: cfg.EncryptionKeyPath,
	}
}

// convertPerformanceConfig 转换 PerformanceConfig
func convertPerformanceConfig(cfg *PerformanceConfig) *local.PerformanceConfig {
	if cfg == nil {
		return nil
	}
	return &local.PerformanceConfig{
		CacheEnabled:    cfg.CacheEnabled,
		CachePath:       cfg.CachePath,
		CacheSize:       cfg.CacheSize,
		CacheTTL:        cfg.CacheTTL,
		ReadBufferSize:  cfg.ReadBufferSize,
		WriteBufferSize: cfg.WriteBufferSize,
	}
}
