package server

import "github.com/album/backend/internal/config/types"

// Config 服务器配置
// 所有需从 config/env 合并的字段均带 mapstructure tag；自定义类型（Duration）在 Unmarshal 阶段由 Loader 的 DecodeHook 统一解析。
type Config struct {
	Host          string         `yaml:"host" mapstructure:"host"`
	Port          int            `yaml:"port" mapstructure:"port"`
	PublicBaseURL string         `yaml:"public_base_url" mapstructure:"public_base_url"`
	ReadTimeout   types.Duration `yaml:"read_timeout" mapstructure:"read_timeout"`
	WriteTimeout  types.Duration `yaml:"write_timeout" mapstructure:"write_timeout"`
	IdleTimeout   types.Duration `yaml:"idle_timeout" mapstructure:"idle_timeout"`
}
