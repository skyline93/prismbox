package modules

import "time"

// ChangelogConfig 变更日志模块配置
type ChangelogConfig struct {
	Enabled              bool          `yaml:"enabled" json:"enabled"`
	CleanupInterval      time.Duration `yaml:"cleanup_interval" json:"cleanup_interval"`
	DeviceActiveThreshold time.Duration `yaml:"device_active_threshold" json:"device_active_threshold"`
	DefaultSyncPageLimit int           `yaml:"default_sync_page_limit" json:"default_sync_page_limit"`
	FullSyncTables       map[string]FullSyncTableConfig `yaml:"full_sync_tables" json:"full_sync_tables"`
}

// FullSyncTableConfig 全量同步表配置
type FullSyncTableConfig struct {
	PrimaryKeyColumn string `yaml:"primary_key_column" json:"primary_key_column"`
}

// Validate 验证配置
func (c *ChangelogConfig) Validate() error {
	// 可以添加验证逻辑
	return nil
}

