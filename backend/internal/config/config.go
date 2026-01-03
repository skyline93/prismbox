package config

import (
	"github.com/album/backend/internal/config/types"
	"github.com/album/backend/internal/database"
	"github.com/album/backend/internal/server"
	"github.com/album/backend/internal/service/auth"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	mediaprocessor "github.com/album/backend/pkg/media-processor"
)

// APIConfig API 配置
type APIConfig struct {
	// MaxFileSize 最大文件上传大小（用于 API 层验证）
	MaxFileSize types.Size `yaml:"max_file_size"`
}

// Config 主配置结构体
type Config struct {
	Server   *server.Config         `yaml:"server"`
	Database *database.Config       `yaml:"database"`
	Storage  *storage.Config        `yaml:"storage"`
	Auth     *auth.Config           `yaml:"auth"`
	API      *APIConfig             `yaml:"api"`
	Logger   *logger.Config         `yaml:"logger"`
	Queue    *gq.ServerConfig       `yaml:"queue"`
	Media    *mediaprocessor.Config `yaml:"media"`
}
