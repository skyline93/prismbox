// replicator/config.go

package replicator

import "time"

// FullSyncTableConfig 定义了参与全量同步的表的具体配置。
type FullSyncTableConfig struct {
	// PrimaryKeyColumn 指定了该表用于分页和记录追踪的主键列名。
	// 注意：该列必须是可排序的类型（如 INT, BIGINT, UUID, 或有序的字符串）。
	PrimaryKeyColumn string `json:"primary_key_column"`
}

// Config 定义了复制器模块的所有可配置项。
type Config struct {
	CleanupInterval       time.Duration                  `json:"cleanup_interval"`        // 清理周期
	DeviceActiveThreshold time.Duration                  `json:"device_active_threshold"` // 设备活跃判断阈值
	DefaultSyncPageLimit  int                            `json:"default_sync_page_limit"` // 默认同步分页大小
	FullSyncTables        map[string]FullSyncTableConfig `json:"full_sync_tables"`        // 需要参与全量同步的业务表及其配置
}

// DefaultConfig 返回一个带有合理默认值的配置。
func DefaultConfig() *Config {
	return &Config{
		CleanupInterval:       24 * time.Hour,
		DeviceActiveThreshold: 180 * 24 * time.Hour, // 180天
		DefaultSyncPageLimit:  500,
		FullSyncTables:        make(map[string]FullSyncTableConfig),
	}
}
