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
