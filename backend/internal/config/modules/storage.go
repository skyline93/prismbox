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
	BasePath    string               `yaml:"base_path"`
	Pools       []*StoragePoolConfig `yaml:"pools"`
	Temp        *TempFileConfig      `yaml:"temp"`
	Processing  *ProcessingConfig    `yaml:"processing"`
	Performance *PerformanceConfig   `yaml:"performance"`
}

// Validate 验证本地存储配置
func (c *LocalStorageConfig) Validate() error {
	if c.BasePath == "" {
		return fmt.Errorf("base_path is required")
	}
	if len(c.Pools) == 0 {
		return fmt.Errorf("at least one pool is required")
	}
	for i, pool := range c.Pools {
		if err := pool.Validate(); err != nil {
			return fmt.Errorf("pool[%d]: %w", i, err)
		}
	}
	return nil
}

// StoragePoolConfig 存储池配置
type StoragePoolConfig struct {
	ID                   string  `yaml:"id"`
	Path                 string  `yaml:"path"`
	MaxSize              Size    `yaml:"max_size"`
	Priority             int     `yaml:"priority"`
	Enabled              bool    `yaml:"enabled"`
	AutoDisableThreshold float64 `yaml:"auto_disable_threshold"` // 0.0-1.0
}

// Validate 验证存储池配置
func (c *StoragePoolConfig) Validate() error {
	if c.ID == "" {
		return fmt.Errorf("id is required")
	}
	if c.Path == "" {
		return fmt.Errorf("path is required")
	}
	if c.MaxSize.Int64() <= 0 {
		return fmt.Errorf("max_size must be greater than 0")
	}
	if c.AutoDisableThreshold < 0 || c.AutoDisableThreshold > 1 {
		return fmt.Errorf("auto_disable_threshold must be between 0.0 and 1.0")
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
