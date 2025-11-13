package modules

import "time"

// ChangelogConfig 变更日志模块配置
type ChangelogConfig struct {
	Enabled                   bool                                `yaml:"enabled" json:"enabled"`
	CleanupInterval           time.Duration                       `yaml:"cleanup_interval" json:"cleanup_interval"`
	DeviceActiveThreshold     time.Duration                       `yaml:"device_active_threshold" json:"device_active_threshold"`
	DefaultChangelogPageLimit int                                 `yaml:"default_changelog_page_limit" json:"default_changelog_page_limit"`
	FullChangelogTables       map[string]FullChangelogTableConfig `yaml:"full_changelog_tables" json:"full_changelog_tables"`
}

// FullChangelogTableConfig 全量变更日志表配置
type FullChangelogTableConfig struct {
	PrimaryKeyColumn string `yaml:"primary_key_column" json:"primary_key_column"`
}

// Validate 验证配置
func (c *ChangelogConfig) Validate() error {
	// 可以添加验证逻辑
	return nil
}
