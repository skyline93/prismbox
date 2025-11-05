package modules

// BackupConfig 备份配置
type BackupConfig struct {
	Enabled bool `yaml:"enabled"`
	// 其他备份配置字段
}

// Validate 验证备份配置
func (c *BackupConfig) Validate() error {
	return nil
}
