package server

import "github.com/album/backend/internal/config/types"

// Config 服务器配置
type Config struct {
	Host          string         `yaml:"host"`
	Port          int            `yaml:"port"`
	PublicBaseURL string         `yaml:"public_base_url"`
	ReadTimeout   types.Duration `yaml:"read_timeout"`
	WriteTimeout  types.Duration `yaml:"write_timeout"`
	IdleTimeout   types.Duration `yaml:"idle_timeout"`
}
