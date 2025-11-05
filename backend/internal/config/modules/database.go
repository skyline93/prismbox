package modules

import (
	"fmt"
)

// DatabaseConfig 数据库配置
type DatabaseConfig struct {
	Type     string `yaml:"type"`      // "sqlite", "mysql", "postgres"
	DSN      string `yaml:"dsn"`       // 数据库连接字符串
	MaxConns int    `yaml:"max_conns"` // 最大连接数
}

// Validate 验证数据库配置
func (c *DatabaseConfig) Validate() error {
	if c.Type == "" {
		return fmt.Errorf("type is required")
	}
	if c.DSN == "" {
		return fmt.Errorf("dsn is required")
	}
	return nil
}
