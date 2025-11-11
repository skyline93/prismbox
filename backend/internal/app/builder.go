package app

import (
	"fmt"

	"github.com/album/backend/internal/config"
	"github.com/album/backend/internal/config/modules"
	"github.com/album/backend/internal/database"
	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/repository"
	"github.com/album/backend/internal/service/auth"
	"github.com/album/backend/internal/service/media"
	"github.com/album/backend/internal/storage"
	"github.com/album/backend/internal/urlsigner"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	mediaprocessor "github.com/album/backend/pkg/media-processor"
)

// Builder 应用构建器
type Builder struct {
	app *App
	cfg *config.Config
}

// NewBuilder 创建应用构建器
func NewBuilder(cfg *config.Config) *Builder {
	return &Builder{
		app: &App{
			Config: cfg,
		},
		cfg: cfg,
	}
}

// BuildAll 构建所有组件
func (b *Builder) BuildAll() error {
	// 按顺序构建各个组件
	if err := b.BuildLogger(); err != nil {
		return fmt.Errorf("build logger: %w", err)
	}

	if err := b.BuildDatabase(); err != nil {
		return fmt.Errorf("build database: %w", err)
	}

	if err := b.BuildPrimaryStorage(); err != nil {
		return fmt.Errorf("build primary storage: %w", err)
	}

	if err := b.BuildStorageManager(); err != nil {
		return fmt.Errorf("build storage manager: %w", err)
	}

	if err := b.BuildMediaProcessor(); err != nil {
		return fmt.Errorf("build media processor: %w", err)
	}

	if err := b.BuildTaskQueue(); err != nil {
		return fmt.Errorf("build task queue: %w", err)
	}

	if err := b.BuildSecurity(); err != nil {
		return fmt.Errorf("build security: %w", err)
	}

	if err := b.BuildRepositories(); err != nil {
		return fmt.Errorf("build repositories: %w", err)
	}

	if err := b.BuildServices(); err != nil {
		return fmt.Errorf("build services: %w", err)
	}

	return nil
}

// BuildLogger 构建日志系统
func (b *Builder) BuildLogger() error {
	if b.cfg.Logger == nil {
		// 使用默认配置
		b.cfg.Logger = &modules.LoggerConfig{
			Level:  "info",
			Format: "console",
			Output: "stdout",
		}
	}

	loggerConfig := &logger.Config{
		Level:  b.cfg.Logger.Level,
		Format: b.cfg.Logger.Format,
		Output: b.cfg.Logger.Output,
	}

	if err := logger.Init(loggerConfig); err != nil {
		return fmt.Errorf("init logger: %w", err)
	}

	return nil
}

// BuildDatabase 构建数据库连接
func (b *Builder) BuildDatabase() error {
	if b.cfg.Database == nil {
		return fmt.Errorf("database config is required")
	}

	db, err := database.NewConnection(b.cfg.Database)
	if err != nil {
		return fmt.Errorf("connect to database: %w", err)
	}

	b.app.DB = db

	// 自动迁移数据库表
	if err := db.AutoMigrate(
		&models.User{},
		&models.AuthProvider{},
		&models.RefreshToken{},
		&models.Media{},
	); err != nil {
		return fmt.Errorf("auto migrate models: %w", err)
	}

	// 自动迁移gq任务表
	if err := gq.AutoMigrate(db); err != nil {
		return fmt.Errorf("auto migrate gq: %w", err)
	}

	return nil
}

// BuildPrimaryStorage 构建主存储
func (b *Builder) BuildPrimaryStorage() error {
	if b.cfg.Storage == nil || b.cfg.Storage.Primary == nil {
		return fmt.Errorf("primary storage config is required")
	}

	primary, err := storage.NewPrimaryStorage(b.cfg.Storage.Primary)
	if err != nil {
		return fmt.Errorf("create primary storage: %w", err)
	}

	b.app.PrimaryStorage = primary
	return nil
}

// BuildStorageManager 构建存储管理器
func (b *Builder) BuildStorageManager() error {
	if b.app.PrimaryStorage == nil {
		return fmt.Errorf("primary storage is required")
	}

	manager := storage.NewStorageManager(b.app.PrimaryStorage)
	b.app.StorageManager = manager
	return nil
}

// BuildTaskQueue 构建任务队列
func (b *Builder) BuildTaskQueue() error {
	if b.app.DB == nil {
		return fmt.Errorf("database is required")
	}

	// 创建任务队列客户端
	client := gq.NewClient(b.app.DB)
	b.app.TaskQueueClient = client

	// 创建任务队列服务器
	serverConfig := &gq.ServerConfig{
		Concurrency:       5,
		MinPollIntervalMs: 200,
		MaxPollIntervalMs: 3000,
	}
	if b.cfg.Queue != nil {
		// TODO: 从配置中读取队列配置
	}

	server := gq.NewServer(b.app.DB, serverConfig)
	b.app.TaskQueueServer = server

	return nil
}

// BuildSecurity 构建安全相关组件
func (b *Builder) BuildSecurity() error {
	if b.cfg.Auth == nil {
		return fmt.Errorf("auth config is required")
	}

	b.app.URLSigner = urlsigner.NewSigner([]byte(b.cfg.Auth.URLSignerSecret))
	return nil
}

// BuildRepositories 构建仓储
func (b *Builder) BuildRepositories() error {
	if b.app.DB == nil {
		return fmt.Errorf("database is required")
	}

	// 创建媒体仓储
	b.app.MediaRepo = repository.NewMediaRepository(b.app.DB)
	b.app.UserRepo = repository.NewUserRepository(b.app.DB)
	b.app.AuthProviderRepo = repository.NewAuthProviderRepository(b.app.DB)
	b.app.RefreshTokenRepo = repository.NewRefreshTokenRepository(b.app.DB)

	return nil
}

// BuildServices 构建服务
func (b *Builder) BuildServices() error {
	if b.app.StorageManager == nil {
		return fmt.Errorf("storage manager is required")
	}

	if b.app.MediaProcessor == nil {
		return fmt.Errorf("media processor is required")
	}

	if b.app.TaskQueueClient == nil {
		return fmt.Errorf("task queue client is required")
	}

	if b.app.MediaRepo == nil {
		return fmt.Errorf("media repository is required")
	}

	if b.app.UserRepo == nil || b.app.AuthProviderRepo == nil || b.app.RefreshTokenRepo == nil {
		return fmt.Errorf("auth repositories are required")
	}

	if b.cfg.Auth == nil {
		return fmt.Errorf("auth config is required")
	}

	if b.cfg.Server == nil {
		return fmt.Errorf("server config is required")
	}

	// 创建媒体服务
	b.app.MediaService = media.NewService(
		b.app.MediaRepo,
		b.app.StorageManager,
		b.app.TaskQueueClient,
		b.app.MediaProcessor,
		b.app.MediaProcessorConfig,
	)

	authService, err := auth.NewService(
		b.app.DB,
		b.app.UserRepo,
		b.app.AuthProviderRepo,
		b.app.RefreshTokenRepo,
		b.cfg.Auth,
		b.cfg.Server,
	)
	if err != nil {
		return fmt.Errorf("build auth service: %w", err)
	}
	b.app.AuthService = authService

	return nil
}

// Build 返回构建的应用
func (b *Builder) Build() *App {
	return b.app
}

// BuildMediaProcessor 构建媒体处理器。
func (b *Builder) BuildMediaProcessor() error {
	cfg := mediaprocessor.DefaultConfig()

	if b.cfg.Media != nil && b.cfg.Media.Processor != nil {
		applyMediaProcessorConfig(cfg, b.cfg.Media.Processor)
	}

	processor, err := mediaprocessor.NewProcessor(cfg)
	if err != nil {
		return err
	}

	b.app.MediaProcessor = processor
	b.app.MediaProcessorConfig = cfg
	return nil
}

func applyMediaProcessorConfig(cfg *mediaprocessor.Config, moduleCfg *modules.MediaProcessorConfig) {
	if moduleCfg == nil {
		return
	}

	if moduleCfg.Concurrency > 0 {
		cfg.Concurrency = moduleCfg.Concurrency
	}

	if len(moduleCfg.DefaultImageSpecs) > 0 {
		cfg.DefaultImageSpecs = make([]mediaprocessor.ImageSpec, 0, len(moduleCfg.DefaultImageSpecs))
		for _, spec := range moduleCfg.DefaultImageSpecs {
			cfg.DefaultImageSpecs = append(cfg.DefaultImageSpecs, mediaprocessor.ImageSpec{
				Name:      spec.Name,
				MaxWidth:  spec.MaxWidth,
				MaxHeight: spec.MaxHeight,
				Quality:   spec.Quality,
				Format:    spec.Format,
				Crop:      spec.Crop,
			})
		}
	}

	if len(moduleCfg.DefaultVideoSpecs) > 0 {
		cfg.DefaultVideoSpecs = make([]mediaprocessor.VideoSpec, 0, len(moduleCfg.DefaultVideoSpecs))
		for _, spec := range moduleCfg.DefaultVideoSpecs {
			cfg.DefaultVideoSpecs = append(cfg.DefaultVideoSpecs, mediaprocessor.VideoSpec{
				Name:     spec.Name,
				MaxWidth: spec.MaxWidth,
				Quality:  spec.Quality,
				Format:   spec.Format,
			})
		}
	}

	if moduleCfg.Imagick != nil {
		if moduleCfg.Imagick.PoolSize > 0 {
			cfg.Imagick.PoolSize = moduleCfg.Imagick.PoolSize
		}
		if moduleCfg.Imagick.MemoryLimit != "" {
			cfg.Imagick.MemoryLimit = moduleCfg.Imagick.MemoryLimit
		}
		if moduleCfg.Imagick.DiskLimit != "" {
			cfg.Imagick.DiskLimit = moduleCfg.Imagick.DiskLimit
		}
		if moduleCfg.Imagick.RAW != nil {
			if moduleCfg.Imagick.RAW.Quality > 0 {
				cfg.Imagick.RAW.Quality = moduleCfg.Imagick.RAW.Quality
			}
			if moduleCfg.Imagick.RAW.Format != "" {
				cfg.Imagick.RAW.Format = moduleCfg.Imagick.RAW.Format
			}
			if moduleCfg.Imagick.RAW.MaxRetries > 0 {
				cfg.Imagick.RAW.MaxRetries = moduleCfg.Imagick.RAW.MaxRetries
			}
			if moduleCfg.Imagick.RAW.RetryDelay > 0 {
				cfg.Imagick.RAW.RetryDelay = moduleCfg.Imagick.RAW.RetryDelay
			}
			if len(moduleCfg.Imagick.RAW.SupportedFormats) > 0 {
				cfg.Imagick.RAW.SupportedFormats = append([]string(nil), moduleCfg.Imagick.RAW.SupportedFormats...)
			}
		}
	}

	if moduleCfg.FFmpeg != nil {
		if moduleCfg.FFmpeg.BinaryPath != "" {
			cfg.FFmpeg.BinaryPath = moduleCfg.FFmpeg.BinaryPath
		}
		if moduleCfg.FFmpeg.ProbePath != "" {
			cfg.FFmpeg.ProbePath = moduleCfg.FFmpeg.ProbePath
		}
		if moduleCfg.FFmpeg.MaxConcurrency > 0 {
			cfg.FFmpeg.MaxConcurrency = moduleCfg.FFmpeg.MaxConcurrency
		}
		if moduleCfg.FFmpeg.ProcessTimeout > 0 {
			cfg.FFmpeg.ProcessTimeout = moduleCfg.FFmpeg.ProcessTimeout
		}
		if moduleCfg.FFmpeg.ThumbnailOffset > 0 {
			cfg.FFmpeg.ThumbnailOffset = moduleCfg.FFmpeg.ThumbnailOffset
		}
	}
}
