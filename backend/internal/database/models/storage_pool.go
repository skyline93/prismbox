package models

import (
	"time"

	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// StoragePool 存储池模型（支持本地和云存储）
type StoragePool struct {
	gorm.Model

	UUID        string `gorm:"type:varchar(255);uniqueIndex;not null"`
	Name        string `gorm:"type:varchar(255);not null"`
	Description string `gorm:"type:text"`

	StorageType string `gorm:"type:varchar(50);not null;index"` // "local", "openlist", "s3", "oss", "cos"

	// Location 存储池位置 URI，如 local:///absolute/path；为唯一位置来源，解析后 scheme 对应 StorageType，path 为池根（本地须为绝对路径）
	Location string `gorm:"type:varchar(512)"`

	// LocalPath 已废弃，仅用于一次性迁移脚本将旧数据转为 Location 后即不再使用；应用仅读 Location。
	LocalPath string `gorm:"type:varchar(512)"`

	// 云存储配置（JSON）
	CloudConfig datatypes.JSON `gorm:"type:json"`

	MaxSize              int64   `gorm:"not null"`
	CurrentSize          int64   `gorm:"default:0"`
	Priority             int     `gorm:"default:0;index"`
	Enabled              bool    `gorm:"default:true;index"`
	AutoDisableThreshold float64 `gorm:"default:0.9"`

	Status        string `gorm:"type:varchar(50);default:'active';index"`
	LastCheckedAt *time.Time
	ErrorMessage  string `gorm:"type:text"`
}

// TableName 自定义表名
func (StoragePool) TableName() string {
	return "storage_pools"
}
