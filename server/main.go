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

// @title           媒体管理 API
// @version         1.0
// @description     一个用于上传、管理和浏览照片与视频的后端服务 API。
// @description     该 API 支持用户认证、多媒体处理、相册管理，并提供标准化的响应格式。

// @tag.name        Authentication
// @tag.description 用户注册与登录

// @tag.name        Media
// @tag.description 媒体资源的上传、查询和管理

// @tag.name        Albums
// @tag.description 相册管理

// @tag.name 		Shares
// @tag.description 共享资源

// @tag.name		Public
// @tag.description	获取共享资源

// @host      localhost:8080
// @BasePath  /api/v1

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization
// @description Type "Bearer" followed by a space and a JWT.
func main() {
	// 1. 加载配置
	cfg, err := core.LoadConfig()
	if err != nil {
		log.Fatalf("Could not load config: %v", err)
	}

	// 2. 连接数据库并迁移
	db, err := database.ConnectAndMigrate(&cfg.DB)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// 3. 启动孤立任务处理器
	go processing.ProcessOrphanedTasks(db, cfg.UploadDir)

	// 4. 设置并启动路由器
	r := api.SetupRouter(db, cfg)
	fmt.Printf("Server is running on : %s", cfg.ServerAddress)
	if err := r.Run(cfg.ServerAddress); err != nil {
		log.Fatalf("Failed to run server: %v", err)
	}
}
