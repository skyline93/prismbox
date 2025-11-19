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
	"github.com/album/backend/internal/worker/media"
	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	"github.com/spf13/pflag"
)

func main() {
	// 1. 定义命令行参数
	flags := pflag.NewFlagSet("server", pflag.ExitOnError)
	config.AddFlags(flags)
	flags.Parse(os.Args[1:])

	// 2. 加载配置
	configPath, _ := flags.GetString("config")
	loader := config.NewLoader(configPath)
	loader.BindPFlags(flags) // 绑定命令行参数

	cfg, err := loader.Load()
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
	media.RegisterMediaProcessors(mux, app.MediaRepo, app.StorageManager, app.MediaProcessor)

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
	server := &http.Server{
		Addr:         addr,
		Handler:      router.Engine(),
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  120 * time.Second,
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

	logger.New("server").Info("server exited")
}
