package modules

// LoggerConfig 日志配置
type LoggerConfig struct {
	Level  string `yaml:"level"`
	Format string `yaml:"format"`
	Output string `yaml:"output"`
	// 其他日志配置字段
}

// Validate 验证日志配置
func (c *LoggerConfig) Validate() error {
	return nil
}
