package changelog

import "time"

// FullChangelogTableConfig 定义了参与全量变更日志的表的具体配置
type FullChangelogTableConfig struct {
	// PrimaryKeyColumn 指定了该表用于分页和记录追踪的主键列名
	// 注意：该列必须是可排序的类型（如 INT, BIGINT, UUID, 或有序的字符串）
	PrimaryKeyColumn string `json:"primary_key_column" yaml:"primary_key_column"`
}

// Config 定义了 changelog 模块的所有可配置项
type Config struct {
	// Enabled 是否启用变更日志功能
	// 如果为 false，所有包装器将直接透传，不记录变更日志
	Enabled bool `json:"enabled" yaml:"enabled"`

	// CleanupInterval 清理周期
	CleanupInterval time.Duration `json:"cleanup_interval" yaml:"cleanup_interval"`

	// DeviceActiveThreshold 设备活跃判断阈值
	DeviceActiveThreshold time.Duration `json:"device_active_threshold" yaml:"device_active_threshold"`

	// DefaultChangelogPageLimit 默认变更日志分页大小
	DefaultChangelogPageLimit int `json:"default_changelog_page_limit" yaml:"default_changelog_page_limit"`

	// FullChangelogTables 需要参与全量变更日志的业务表及其配置
	FullChangelogTables map[string]FullChangelogTableConfig `json:"full_changelog_tables" yaml:"full_changelog_tables"`
}

// DefaultConfig 返回一个带有合理默认值的配置（默认启用）
func DefaultConfig() *Config {
	return &Config{
		Enabled:                   true,
		CleanupInterval:           24 * time.Hour,
		DeviceActiveThreshold:     180 * 24 * time.Hour, // 180天
		DefaultChangelogPageLimit: 500,
		FullChangelogTables:       make(map[string]FullChangelogTableConfig),
	}
}

// DisabledConfig 返回禁用状态的配置
func DisabledConfig() *Config {
	cfg := DefaultConfig()
	cfg.Enabled = false
	return cfg
}
