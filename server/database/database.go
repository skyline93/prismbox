package database

import (
	"log"
	"os"
	"server/models"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// ConnectAndMigrate 负责连接到数据库并执行自动迁移。
// 它接收数据库文件的路径作为参数。
// 它会确保所有在 models 包中定义的表都已创建或更新。
func ConnectAndMigrate(databaseURL string) (*gorm.DB, error) {
	// 配置GORM的日志记录器，可以设置为 Silent, Error, Warn, Info
	// 这里使用 Info 级别，可以看到所有执行的SQL语句，便于调试
	newLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags), // io writer
		logger.Config{
			// SlowThreshold: logger.DefaultSlowThreshold, // 慢 SQL 阈值
			LogLevel: logger.Info, // 日志级别
			Colorful: true,        // 启用彩色打印
		},
	)

	// 连接到SQLite数据库
	db, err := gorm.Open(sqlite.Open(databaseURL), &gorm.Config{
		Logger: newLogger,
	})

	if err != nil {
		log.Printf("Failed to connect to database: %v", err)
		return nil, err
	}

	log.Println("Database connection established successfully.")

	// 自动迁移，GORM会检查模型与数据库表的差异，并进行更新
	// 这对于开发非常方便
	log.Println("Running auto migration...")
	err = db.AutoMigrate(
		&models.User{},
		&models.Photo{},
		&models.Album{},
		&models.RefreshToken{},
		&models.Share{},
	)
	if err != nil {
		log.Printf("Failed to auto migrate database: %v", err)
		return nil, err
	}
	log.Println("Auto migration completed.")

	return db, nil
}
