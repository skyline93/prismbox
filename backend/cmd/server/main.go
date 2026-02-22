package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/album/backend/internal/api"
	"github.com/album/backend/internal/app"
	"github.com/album/backend/internal/config"
	"github.com/album/backend/internal/database/models"
	"github.com/album/backend/internal/worker/media"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	"github.com/spf13/pflag"

	_ "github.com/album/backend/docs/swagger" // 导入 Swagger 文档
)

// @title           PrismBox Backend API
// @version         1.0
// @description     PrismBox 后端服务 API 文档
// @termsOfService  https://prismbox.example.com/terms

// @contact.name   API Support
// @contact.url    https://prismbox.example.com/support
// @contact.email  support@prismbox.example.com

// @license.name  MIT
// @license.url   https://opensource.org/licenses/MIT

// @host      localhost:8080
// @BasePath  /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description 使用 "Bearer {token}" 格式，或使用 "x-prismbox-user-token: {token}" 格式

func main() {
	// 1. 定义命令行参数
	flags := pflag.NewFlagSet("server", pflag.ExitOnError)
	config.AddFlags(flags)
	flags.Parse(os.Args[1:])

	// 2. 加载配置
	// 优先级：显式 -c/--config > 环境变量 ALBUM_CONFIG_PATH > 默认 configs/config.yaml
	configPath, _ := flags.GetString("config")
	if !flags.Changed("config") {
		if envPath := os.Getenv("ALBUM_CONFIG_PATH"); envPath != "" {
			configPath = envPath
		}
	}
	if configPath == "" {
		configPath = "configs/config.yaml"
	}
	loader := config.NewLoader(configPath)
	loader.BindPFlags(flags) // 绑定命令行参数

	cfg, err := loader.Load(flags)
	if err != nil {
		log.Fatalf("Could not load config: %v", err)
	}

	// 2. 构建应用（依赖注入）
	builder := app.NewBuilder(cfg)
	if err := builder.BuildAll(); err != nil {
		log.Fatalf("Failed to build app: %v", err)
	}
	defer logger.Sync() // 确保所有日志写入完成

	app := builder.Build()

	// 3. 注册任务处理器
	mux := gq.NewServeMux()
	media.RegisterMediaProcessors(mux, app.MediaRepo, app.StorageManager, app.MediaProcessor, app.MediaProcessorConfig,
		func(m *models.Media) (string, error) { return app.MediaService.BuildThumbnailKey(m) })

	// 4. 启动任务队列服务器（后台运行）
	go func() {
		if err := app.TaskQueueServer.Run(mux); err != nil {
			logger.New("server").Error("task queue server failed",
				logger.Error(err),
			)
		}
	}()

	// 5. 创建路由
	router := api.NewRouter(app)
	router.Setup()

	// 6. 创建HTTP服务器
	addr := fmt.Sprintf("%s:%d", cfg.Server.Host, cfg.Server.Port)

	// 设置超时时间（从配置读取，如果为0则使用默认值）
	readTimeout := cfg.Server.ReadTimeout.Duration()
	if readTimeout == 0 {
		readTimeout = 1 * time.Hour
	}
	writeTimeout := cfg.Server.WriteTimeout.Duration()
	if writeTimeout == 0 {
		writeTimeout = 1 * time.Hour
	}
	idleTimeout := cfg.Server.IdleTimeout.Duration()
	if idleTimeout == 0 {
		idleTimeout = 2 * time.Minute
	}

	server := &http.Server{
		Addr:         addr,
		Handler:      router.Engine(),
		ReadTimeout:  readTimeout,
		WriteTimeout: writeTimeout,
		IdleTimeout:  idleTimeout,
	}

	// 7. 启动HTTP服务器（后台运行）
	go func() {
		logger.New("server").Info("starting HTTP server",
			logger.String("address", addr),
		)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.New("server").Fatal("failed to start HTTP server",
				logger.Error(err),
			)
		}
	}()

	// 8. 等待中断信号
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	logger.New("server").Info("shutting down server...")

	// 9. 优雅关闭
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// 关闭HTTP服务器
	if err := server.Shutdown(ctx); err != nil {
		logger.New("server").Error("failed to shutdown HTTP server",
			logger.Error(err),
		)
	}

	// 关闭任务队列服务器
	if err := app.TaskQueueServer.Shutdown(ctx); err != nil {
		logger.New("server").Error("failed to shutdown task queue server",
			logger.Error(err),
		)
	}

	// 关闭存储等资源（停止 PoolManager 后台 goroutine）
	if err := app.Close(); err != nil {
		logger.New("server").Error("failed to close app",
			logger.Error(err),
		)
	}

	logger.New("server").Info("server exited")
}
