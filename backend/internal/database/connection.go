package database

import (
	"fmt"

	"github.com/album/backend/internal/config/modules"
	"gorm.io/driver/postgres"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

// NewConnection 创建数据库连接
func NewConnection(cfg *modules.DatabaseConfig) (*gorm.DB, error) {
	switch cfg.Type {
	case "sqlite":
		return newSQLiteConnection(cfg.DSN)
	case "postgres":
		return newPostgreSQLConnection(cfg.DSN)
	default:
		return nil, fmt.Errorf("unsupported database type: %s", cfg.Type)
	}
}

// newSQLiteConnection 创建SQLite连接
func newSQLiteConnection(dsn string) (*gorm.DB, error) {
	db, err := gorm.Open(sqlite.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to sqlite database: %w", err)
	}

	return db, nil
}

// newPostgreSQLConnection 创建PostgreSQL连接
func newPostgreSQLConnection(dsn string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		return nil, fmt.Errorf("failed to connect to postgresql database: %w", err)
	}

	return db, nil
}
