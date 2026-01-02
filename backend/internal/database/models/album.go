package models

import (
	"gorm.io/gorm"
)

// AlbumType 相册类型枚举
type AlbumType string

const (
	AlbumTypeNormal AlbumType = "normal"
	AlbumTypeCustom AlbumType = "custom"
)

// Album 相册模型
type Album struct {
	gorm.Model

	// 核心字段
	UUID        string `gorm:"type:varchar(255);uniqueIndex;not null"`
	Name        string `gorm:"type:varchar(255);not null"`
	Description string `gorm:"type:text"`
	UserID      uint   `gorm:"index;not null"`

	// 缩略图
	CoverMediaUUID *string `gorm:"type:varchar(255)"`

	// 活动功能
	IsActivityEnabled bool `gorm:"default:false"`

	// 排序方式
	Order int `gorm:"default:1"`

	// 关联
	Items []Media `gorm:"many2many:album_items;"`
}

// TableName 指定表名
func (Album) TableName() string {
	return "albums"
}

