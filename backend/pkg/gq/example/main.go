package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/album/backend/pkg/gq"
	"github.com/album/backend/pkg/logger"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	gormlogger "gorm.io/gorm/logger"
)

func main() {
	// 0. 初始化日志系统
	logConfig := &logger.Config{
		Level:        "info",
		Format:       "console",
		Output:       "stdout",
		EnableCaller: true,
		EnableStack:  false,
		Async:        false,
	}
	if err := logger.Init(logConfig); err != nil {
		panic(err)
	}
	defer logger.Sync()

	log := logger.New("gq.example")

	// 1. 设置数据库连接
	db := setupDatabase()

	// 2. 自动迁移数据库表结构
	if err := gq.AutoMigrate(db); err != nil {
		log.Fatal("Failed to migrate database", logger.Error(err))
	}

	// 3. 创建客户端
	client := gq.NewClient(db)

	// 4. 创建服务端配置
	config := &gq.ServerConfig{
		Concurrency:       5,
		MinPollIntervalMs: 200,
		MaxPollIntervalMs: 3000,
	}

	// 5. 创建服务端
	server := gq.NewServer(db, config)

	// 6. 创建多路复用器并注册处理器
	mux := gq.NewServeMux()
	mux.HandleFunc("email:welcome", welcomeEmailHandler)
	mux.HandleFunc("email:reminder", reminderEmailHandler)
	mux.HandleFunc("image:process", imageProcessHandler)

	// 7. 启动服务端
	if err := server.Run(mux); err != nil {
		log.Fatal("Failed to start server", logger.Error(err))
	}

	// 8. 创建一些示例任务
	ctx := context.Background()
	createSampleTasks(ctx, client, log)

	// 9. 等待中断信号
	waitForShutdown(server, log)
}

// setupDatabase 设置数据库连接
func setupDatabase() *gorm.DB {
	// 这里使用 SQLite 作为示例，可以根据需要修改为 MySQL 或 PostgreSQL
	dsn := "gq.db"

	// 使用 MySQL 示例（需要取消注释并配置）
	// dsn := "user:password@tcp(localhost:3306)/gq?charset=utf8mb4&parseTime=True&loc=Local"
	// db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})

	// 使用 PostgreSQL 示例（需要取消注释并配置）
	// dsn := "host=localhost user=gorm password=gorm dbname=gorm port=9920 sslmode=disable TimeZone=Asia/Shanghai"
	// db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})

	// SQLite 配置
	db, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{
		Logger: gormlogger.New(
			log.New(os.Stdout, "", log.LstdFlags),
			gormlogger.Config{
				SlowThreshold:             time.Second,
				LogLevel:                  gormlogger.Silent,
				IgnoreRecordNotFoundError: true,
				Colorful:                  true,
			},
		),
	})

	if err != nil {
		panic(fmt.Errorf("failed to connect to database: %w", err))
	}

	return db
}

// createSampleTasks 创建一些示例任务
func createSampleTasks(ctx context.Context, client *gq.Client, log logger.Logger) {
	// 示例 1: 发送欢迎邮件（高优先级）
	welcomePayload, _ := json.Marshal(map[string]string{
		"email": "user@example.com",
		"name":  "张三",
	})

	if err := client.Enqueue(ctx,
		gq.NewTask("email:welcome", welcomePayload),
		gq.Queue("critical"),
		gq.Priority(10),
		gq.MaxRetries(3),
	); err != nil {
		log.Error("Failed to enqueue welcome email task", logger.Error(err))
	} else {
		log.Info("Enqueued welcome email task")
	}

	// 示例 2: 发送提醒邮件（普通优先级，延迟执行）
	reminderPayload, _ := json.Marshal(map[string]string{
		"email":   "user2@example.com",
		"message": "请及时查看您的账户",
	})

	processAt := time.Now().Add(5 * time.Second)
	if err := client.Enqueue(ctx,
		gq.NewTask("email:reminder", reminderPayload),
		gq.Queue("default"),
		gq.Priority(5),
		gq.ProcessAt(processAt),
	); err != nil {
		log.Error("Failed to enqueue reminder email task", logger.Error(err))
	} else {
		log.Info("Enqueued reminder email task", logger.Time("scheduled_at", processAt))
	}

	// 示例 3: 处理图片（多个任务）
	for i := 0; i < 3; i++ {
		imagePayload, _ := json.Marshal(map[string]interface{}{
			"image_url": fmt.Sprintf("https://example.com/image%d.jpg", i),
			"action":    "resize",
			"width":     800,
			"height":    600,
		})

		if err := client.Enqueue(ctx,
			gq.NewTask("image:process", imagePayload),
			gq.Queue("default"),
			gq.Priority(i), // 不同的优先级
		); err != nil {
			log.Error("Failed to enqueue image process task", logger.Int("task_id", i), logger.Error(err))
		} else {
			log.Info("Enqueued image process task", logger.Int("task_id", i))
		}
	}
}

// welcomeEmailHandler 处理欢迎邮件任务
func welcomeEmailHandler(ctx context.Context, task *gq.Task) error {
	log := logger.New("gq.handler")
	var payload map[string]string
	if err := json.Unmarshal(task.Payload, &payload); err != nil {
		return fmt.Errorf("invalid payload: %w", err)
	}

	email := payload["email"]
	name := payload["name"]

	log.Info("Sending welcome email", logger.String("email", email), logger.String("name", name))

	// 模拟邮件发送
	time.Sleep(500 * time.Millisecond)

	log.Info("Welcome email sent successfully", logger.String("email", email))
	return nil
}

// reminderEmailHandler 处理提醒邮件任务
func reminderEmailHandler(ctx context.Context, task *gq.Task) error {
	log := logger.New("gq.handler")
	var payload map[string]string
	if err := json.Unmarshal(task.Payload, &payload); err != nil {
		return fmt.Errorf("invalid payload: %w", err)
	}

	email := payload["email"]
	message := payload["message"]

	log.Info("Sending reminder email", logger.String("email", email), logger.String("message", message))

	// 模拟邮件发送
	time.Sleep(300 * time.Millisecond)

	log.Info("Reminder email sent successfully", logger.String("email", email))
	return nil
}

// imageProcessHandler 处理图片处理任务
func imageProcessHandler(ctx context.Context, task *gq.Task) error {
	log := logger.New("gq.handler")
	var payload map[string]interface{}
	if err := json.Unmarshal(task.Payload, &payload); err != nil {
		return fmt.Errorf("invalid payload: %w", err)
	}

	imageURL := payload["image_url"].(string)
	action := payload["action"].(string)

	log.Info("Processing image", logger.String("image_url", imageURL), logger.String("action", action))

	// 模拟图片处理
	time.Sleep(1 * time.Second)

	log.Info("Image processed successfully", logger.String("image_url", imageURL))
	return nil
}

// waitForShutdown 等待中断信号并优雅关闭服务器
func waitForShutdown(server *gq.Server, log logger.Logger) {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	<-quit
	log.Info("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatal("Server forced to shutdown", logger.Error(err))
	}

	log.Info("Server exited")
}
