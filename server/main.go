// main.go
package main

import (
	"fmt"
	"log"
	"server/api"
	"server/core"
	"server/database"
	"server/processing"
)

func main() {
	// 1. 加载配置
	cfg, err := core.LoadConfig()
	if err != nil {
		log.Fatalf("Could not load config: %v", err)
	}

	// 2. 连接数据库并迁移
	db, err := database.ConnectAndMigrate(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// 3. 启动孤立任务处理器
	go processing.ProcessOrphanedTasks(db, cfg.UploadDir)

	// 4. 设置并启动路由器
	r := api.SetupRouter(db, cfg)
	fmt.Println("Server is running on :8080")
	if err := r.Run(cfg.ServerAddress); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
