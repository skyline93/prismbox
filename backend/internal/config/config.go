package config

import (
	"github.com/album/backend/internal/config/modules"
)

// Config 主配置结构体
type Config struct {
	Server    *modules.ServerConfig    `yaml:"server"`
	Database  *modules.DatabaseConfig  `yaml:"database"`
	Storage   *modules.StorageConfig   `yaml:"storage"`
	Backup    *modules.BackupConfig    `yaml:"backup"`
	Queue     *modules.QueueConfig     `yaml:"queue"`
	Auth      *modules.AuthConfig      `yaml:"auth"`
	Media     *modules.MediaConfig     `yaml:"media"`
	Logger    *modules.LoggerConfig    `yaml:"logger"`
	Changelog *modules.ChangelogConfig `yaml:"changelog"`
}

// Validate 验证配置
func (c *Config) Validate() error {
	if c.Server != nil {
		if err := c.Server.Validate(); err != nil {
			return err
		}
	}
	if c.Database != nil {
		if err := c.Database.Validate(); err != nil {
			return err
		}
	}
	if c.Storage != nil {
		if err := c.Storage.Validate(); err != nil {
			return err
		}
	}
	if c.Backup != nil {
		if err := c.Backup.Validate(); err != nil {
			return err
		}
	}
	if c.Queue != nil {
		if err := c.Queue.Validate(); err != nil {
			return err
		}
	}
	if c.Auth != nil {
		if err := c.Auth.Validate(); err != nil {
			return err
		}
	}
	if c.Media != nil {
		if err := c.Media.Validate(); err != nil {
			return err
		}
	}
	if c.Logger != nil {
		if err := c.Logger.Validate(); err != nil {
			return err
		}
	}
	if c.Changelog != nil {
		if err := c.Changelog.Validate(); err != nil {
			return err
		}
	}
	return nil
}
