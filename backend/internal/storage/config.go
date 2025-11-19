package storage

import (
	"github.com/album/backend/internal/config/types"
)

// Config 存储配置
type Config struct {
	Primary   *PrimaryStorageConfig   `yaml:"primary"`
	Secondary *SecondaryStorageConfig `yaml:"secondary"`
}

// PrimaryStorageConfig 主存储配置
type PrimaryStorageConfig struct {
	Type  string              `yaml:"type"` // "local"
	Local *LocalStorageConfig `yaml:"local"`
}

// LocalStorageConfig 本地存储配置
type LocalStorageConfig struct {
	BasePath    string             `yaml:"base_path"`
	PoolManager *PoolManagerConfig `yaml:"pool_manager"`
	Temp        *TempFileConfig    `yaml:"temp"`
	Processing  *ProcessingConfig  `yaml:"processing"`
	Performance *PerformanceConfig `yaml:"performance"`
}

// PoolManagerConfig 存储池管理器配置
type PoolManagerConfig struct {
	DeltaChannelSize     int              `yaml:"delta_channel_size"`
	DeltaBatchSize       int              `yaml:"delta_batch_size"`
	FlushInterval        types.Duration `yaml:"flush_interval"`
	CacheRefreshInterval types.Duration `yaml:"cache_refresh_interval"`
	ReconcileInterval    types.Duration `yaml:"reconcile_interval"`
}

// TempFileConfig 临时文件配置
type TempFileConfig struct {
	BasePath        string           `yaml:"base_path"`
	MaxAge          types.Duration `yaml:"max_age"`
	MaxSize         types.Size     `yaml:"max_size"`
	CleanupInterval types.Duration `yaml:"cleanup_interval"`
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
	CacheEnabled    bool             `yaml:"cache_enabled"`
	CacheSize       types.Size     `yaml:"cache_size"`
	CacheTTL        types.Duration `yaml:"cache_ttl"`
	ReadBufferSize  types.Size     `yaml:"read_buffer_size"`
	WriteBufferSize types.Size     `yaml:"write_buffer_size"`
}

// SecondaryStorageConfig 次存储配置
type SecondaryStorageConfig struct {
	Enabled bool   `yaml:"enabled"`
	Type    string `yaml:"type"` // "openlist", "s3", "oss", "cos"
	// 其他配置字段根据具体实现添加
}
