package database

import (
	"fmt"
	"log"
	"os"
	"server/core"
	"server/models"

	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// ConnectAndMigrate 负责连接到数据库并执行自动迁移。
// 它现在是一个工厂函数，根据配置动态选择数据库。
func ConnectAndMigrate(cfg *core.DBConfig) (*gorm.DB, error) {
	var dialector gorm.Dialector
	dbType := cfg.Type

	log.Printf("Attempting to connect to database of type: %s", dbType)

	if dbType == "postgres" {
		dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=%s TimeZone=%s",
			cfg.Host,
			cfg.User,
			cfg.Password,
			cfg.DBName,
			cfg.Port,
			cfg.SSLMode,
			cfg.TimeZone,
		)
		dialector = postgres.Open(dsn)
	} else if dbType == "sqlite" {
		dialector = sqlite.Open(cfg.SQLitePath)
	} else {
		return nil, fmt.Errorf("unsupported database type: %s", dbType)
	}

	// 配置GORM的日志记录器
	newLogger := logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			LogLevel: logger.Info,
			Colorful: true,
		},
	)

	// 使用选择好的Dialector进行连接
	db, err := gorm.Open(dialector, &gorm.Config{
		Logger: newLogger,
	})

	if err != nil {
		log.Printf("Failed to connect to %s database: %v", dbType, err)
		return nil, err
	}

	log.Printf("%s database connection established successfully.", dbType)

	// 自动迁移逻辑保持不变，GORM会处理SQL方言的差异
	log.Println("Running auto migration...")
	err = db.AutoMigrate(
		&models.User{},
		&models.Media{},
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
