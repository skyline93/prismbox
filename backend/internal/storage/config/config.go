// Package config 提供存储相关的配置类型，供 storage 与各后端（如 local）共用，避免重复定义与循环依赖。
// 配置层（YAML/环境变量）与运行时共用此唯一定义。
package config

import (
	"github.com/album/backend/internal/config/types"
)

// PrimaryStorageConfig 主存储配置：类型 + 对应后端配置块。
type PrimaryStorageConfig struct {
	Type  string             `yaml:"type" mapstructure:"type"`   // "local"，后续可扩展 "s3" 等
	Local *LocalStorageConfig `yaml:"local" mapstructure:"local"`
}

// LocalStorageConfig 本地存储后端配置。
// DataDir 为工作根目录（必填），仅用于 temp、staging、cache 的默认父目录；须为绝对路径，由 NewPrimaryStorage 统一校验并规范化。
// 池内文件路径由 pool.Path + key 决定，池根来自 DB（storage_pools.location）。
type LocalStorageConfig struct {
	DataDir     string             `yaml:"data_dir" mapstructure:"data_dir"` // 必填，绝对路径
	PoolManager *PoolManagerConfig `yaml:"pool_manager" mapstructure:"pool_manager"`
	Temp        *TempFileConfig    `yaml:"temp" mapstructure:"temp"`
	Processing  *ProcessingConfig  `yaml:"processing" mapstructure:"processing"`
	Performance *PerformanceConfig `yaml:"performance" mapstructure:"performance"`
}

// PoolManagerConfig 存储池管理器配置（flush/刷新/对账间隔等）。
type PoolManagerConfig struct {
	DeltaChannelSize     int            `yaml:"delta_channel_size" mapstructure:"delta_channel_size"`
	DeltaBatchSize       int            `yaml:"delta_batch_size" mapstructure:"delta_batch_size"`
	FlushInterval        types.Duration `yaml:"flush_interval" mapstructure:"flush_interval"`
	CacheRefreshInterval types.Duration `yaml:"cache_refresh_interval" mapstructure:"cache_refresh_interval"`
	ReconcileInterval    types.Duration `yaml:"reconcile_interval" mapstructure:"reconcile_interval"`
}

// TempFileConfig 临时文件配置。
type TempFileConfig struct {
	BasePath        string         `yaml:"base_path" mapstructure:"base_path"`
	MaxAge          types.Duration `yaml:"max_age" mapstructure:"max_age"`
	MaxSize         types.Size     `yaml:"max_size" mapstructure:"max_size"`
	CleanupInterval types.Duration `yaml:"cleanup_interval" mapstructure:"cleanup_interval"`
}

// ProcessingConfig 处理配置（压缩、加密）。
type ProcessingConfig struct {
	EnableCompression bool   `yaml:"enable_compression" mapstructure:"enable_compression"`
	CompressionLevel  int    `yaml:"compression_level" mapstructure:"compression_level"`
	EnableEncryption  bool   `yaml:"enable_encryption" mapstructure:"enable_encryption"`
	EncryptionKeyPath string `yaml:"encryption_key_path" mapstructure:"encryption_key_path"`
}

// PerformanceConfig 性能配置（磁盘缓存）。不含未使用的 ReadBufferSize/WriteBufferSize。
type PerformanceConfig struct {
	CacheEnabled bool           `yaml:"cache_enabled" mapstructure:"cache_enabled"`
	CachePath    string         `yaml:"cache_path" mapstructure:"cache_path"` // 磁盘缓存根目录
	CacheSize    types.Size     `yaml:"cache_size" mapstructure:"cache_size"`
	CacheTTL     types.Duration `yaml:"cache_ttl" mapstructure:"cache_ttl"`
}

// SecondaryStorageConfig 次存储配置（占位，后续实现）。
type SecondaryStorageConfig struct {
	Enabled bool   `yaml:"enabled" mapstructure:"enabled"`
	Type    string `yaml:"type" mapstructure:"type"` // "openlist", "s3", "oss", "cos"
}
