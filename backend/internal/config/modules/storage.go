package modules

import (
	"fmt"
)

// StorageConfig 存储配置
type StorageConfig struct {
	Primary   *PrimaryStorageConfig   `yaml:"primary"`
	Secondary *SecondaryStorageConfig `yaml:"secondary"`
}

// Validate 验证存储配置
func (c *StorageConfig) Validate() error {
	if c.Primary == nil {
		return fmt.Errorf("storage.primary is required")
	}
	if err := c.Primary.Validate(); err != nil {
		return fmt.Errorf("storage.primary: %w", err)
	}
	if c.Secondary != nil {
		if err := c.Secondary.Validate(); err != nil {
			return fmt.Errorf("storage.secondary: %w", err)
		}
	}
	return nil
}

// PrimaryStorageConfig 主存储配置
type PrimaryStorageConfig struct {
	Type  string              `yaml:"type"` // "local"
	Local *LocalStorageConfig `yaml:"local"`
}

// Validate 验证主存储配置
func (c *PrimaryStorageConfig) Validate() error {
	if c.Type == "" {
		return fmt.Errorf("type is required")
	}
	if c.Type != "local" {
		return fmt.Errorf("unsupported primary storage type: %s", c.Type)
	}
	if c.Local == nil {
		return fmt.Errorf("local config is required")
	}
	return c.Local.Validate()
}

// LocalStorageConfig 本地存储配置
type LocalStorageConfig struct {
	BasePath    string             `yaml:"base_path"`
	PoolManager *PoolManagerConfig `yaml:"pool_manager"`
	Temp        *TempFileConfig    `yaml:"temp"`
	Processing  *ProcessingConfig  `yaml:"processing"`
	Performance *PerformanceConfig `yaml:"performance"`
}

// Validate 验证本地存储配置
func (c *LocalStorageConfig) Validate() error {
	if c.BasePath == "" {
		return fmt.Errorf("base_path is required")
	}
	if c.PoolManager != nil {
		if err := c.PoolManager.Validate(); err != nil {
			return fmt.Errorf("pool_manager: %w", err)
		}
	}
	return nil
}

// PoolManagerConfig 存储池管理器配置
type PoolManagerConfig struct {
	DeltaChannelSize     int      `yaml:"delta_channel_size"`
	DeltaBatchSize       int      `yaml:"delta_batch_size"`
	FlushInterval        Duration `yaml:"flush_interval"`
	CacheRefreshInterval Duration `yaml:"cache_refresh_interval"`
	ReconcileInterval    Duration `yaml:"reconcile_interval"`
}

// Validate 验证存储池管理器配置
func (c *PoolManagerConfig) Validate() error {
	if c.DeltaChannelSize < 0 {
		return fmt.Errorf("delta_channel_size must be >= 0")
	}
	if c.DeltaBatchSize < 0 {
		return fmt.Errorf("delta_batch_size must be >= 0")
	}
	if c.FlushInterval.Duration() <= 0 {
		return fmt.Errorf("flush_interval must be > 0")
	}
	if c.CacheRefreshInterval.Duration() <= 0 {
		return fmt.Errorf("cache_refresh_interval must be > 0")
	}
	if c.ReconcileInterval.Duration() < 0 {
		return fmt.Errorf("reconcile_interval must be >= 0")
	}
	return nil
}

// TempFileConfig 临时文件配置
type TempFileConfig struct {
	BasePath        string   `yaml:"base_path"`
	MaxAge          Duration `yaml:"max_age"`
	MaxSize         Size     `yaml:"max_size"`
	CleanupInterval Duration `yaml:"cleanup_interval"`
}

// ProcessingConfig 处理配置
type ProcessingConfig struct {
	EnableCompression bool   `yaml:"enable_compression"`
	CompressionLevel  int    `yaml:"compression_level"`
	EnableEncryption  bool   `yaml:"enable_encryption"`
	EncryptionKeyPath string `yaml:"encryption_key_path"`
}

// PerformanceConfig 性能配置
type PerformanceConfig struct {
	CacheEnabled    bool     `yaml:"cache_enabled"`
	CacheSize       Size     `yaml:"cache_size"`
	CacheTTL        Duration `yaml:"cache_ttl"`
	ReadBufferSize  Size     `yaml:"read_buffer_size"`
	WriteBufferSize Size     `yaml:"write_buffer_size"`
}

// SecondaryStorageConfig 次存储配置
type SecondaryStorageConfig struct {
	Enabled bool   `yaml:"enabled"`
	Type    string `yaml:"type"` // "openlist", "s3", "oss", "cos"
	// 其他配置字段根据具体实现添加
}

// Validate 验证次存储配置
func (c *SecondaryStorageConfig) Validate() error {
	if !c.Enabled {
		return nil
	}
	if c.Type == "" {
		return fmt.Errorf("type is required when enabled")
	}
	return nil
}
