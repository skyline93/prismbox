package modules

// QueueConfig 队列配置
type QueueConfig struct {
	Type string `yaml:"type"` // "gq"
	// 其他队列配置字段
}

// Validate 验证队列配置
func (c *QueueConfig) Validate() error {
	return nil
}
