package modules

// MediaConfig 媒体配置
type MediaConfig struct {
	MaxFileSize Size `yaml:"max_file_size"` // 支持 "100MB", "1GB" 等格式
	// 其他媒体配置字段
}

// Validate 验证媒体配置
func (c *MediaConfig) Validate() error {
	return nil
}
