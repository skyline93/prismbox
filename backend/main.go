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
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func main() {
	// 1. 设置数据库连接
	db := setupDatabase()

	// 2. 自动迁移数据库表结构
	if err := gq.AutoMigrate(db); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
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
		log.Fatalf("Failed to start server: %v", err)
	}

	// 8. 创建一些示例任务
	ctx := context.Background()
	createSampleTasks(ctx, client)

	// 9. 等待中断信号
	waitForShutdown(server)
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
		Logger: logger.New(
			log.New(os.Stdout, "", log.LstdFlags),
			logger.Config{
				SlowThreshold:             time.Second,
				LogLevel:                  logger.Silent,
				IgnoreRecordNotFoundError: true,
				Colorful:                  true,
			},
		),
	})

	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	log.Println("Database connected successfully")
	return db
}

// createSampleTasks 创建一些示例任务
func createSampleTasks(ctx context.Context, client *gq.Client) {
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
		log.Printf("Failed to enqueue welcome email task: %v", err)
	} else {
		log.Println("Enqueued welcome email task")
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
		log.Printf("Failed to enqueue reminder email task: %v", err)
	} else {
		log.Printf("Enqueued reminder email task (scheduled for %v)", processAt)
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
			log.Printf("Failed to enqueue image process task %d: %v", i, err)
		} else {
			log.Printf("Enqueued image process task %d", i)
		}
	}
}

// welcomeEmailHandler 处理欢迎邮件任务
func welcomeEmailHandler(ctx context.Context, task *gq.Task) error {
	var payload map[string]string
	if err := json.Unmarshal(task.Payload, &payload); err != nil {
		return fmt.Errorf("invalid payload: %w", err)
	}

	email := payload["email"]
	name := payload["name"]

	log.Printf("[Handler] Sending welcome email to %s (%s)...", email, name)

	// 模拟邮件发送
	time.Sleep(500 * time.Millisecond)

	log.Printf("[Handler] Welcome email sent successfully to %s", email)
	return nil
}

// reminderEmailHandler 处理提醒邮件任务
func reminderEmailHandler(ctx context.Context, task *gq.Task) error {
	var payload map[string]string
	if err := json.Unmarshal(task.Payload, &payload); err != nil {
		return fmt.Errorf("invalid payload: %w", err)
	}

	email := payload["email"]
	message := payload["message"]

	log.Printf("[Handler] Sending reminder email to %s: %s", email, message)

	// 模拟邮件发送
	time.Sleep(300 * time.Millisecond)

	log.Printf("[Handler] Reminder email sent successfully to %s", email)
	return nil
}

// imageProcessHandler 处理图片处理任务
func imageProcessHandler(ctx context.Context, task *gq.Task) error {
	var payload map[string]interface{}
	if err := json.Unmarshal(task.Payload, &payload); err != nil {
		return fmt.Errorf("invalid payload: %w", err)
	}

	imageURL := payload["image_url"].(string)
	action := payload["action"].(string)

	log.Printf("[Handler] Processing image: %s (action: %s)", imageURL, action)

	// 模拟图片处理
	time.Sleep(1 * time.Second)

	log.Printf("[Handler] Image processed successfully: %s", imageURL)
	return nil
}

// waitForShutdown 等待中断信号并优雅关闭服务器
func waitForShutdown(server *gq.Server) {
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	<-quit
	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}
