package storage

import (
	"github.com/album/backend/internal/storage/config"
)

// Config 存储配置根。Primary/Secondary 的具体类型在 storage/config 中定义。
type Config struct {
	Primary   *config.PrimaryStorageConfig   `yaml:"primary" mapstructure:"primary"`
	Secondary *config.SecondaryStorageConfig `yaml:"secondary,omitempty" mapstructure:"secondary"`
}
