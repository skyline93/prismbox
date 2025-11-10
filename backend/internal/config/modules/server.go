package modules

import (
	"fmt"
)

// ServerConfig 服务器配置
type ServerConfig struct {
	Host          string `yaml:"host"`
	Port          int    `yaml:"port"`
	PublicBaseURL string `yaml:"public_base_url"`
}

// Validate 验证服务器配置
func (c *ServerConfig) Validate() error {
	if c.Host == "" {
		return fmt.Errorf("host is required")
	}
	if c.Port <= 0 || c.Port > 65535 {
		return fmt.Errorf("port must be between 1 and 65535")
	}
	if c.PublicBaseURL == "" {
		return fmt.Errorf("public_base_url is required")
	}
	return nil
}
