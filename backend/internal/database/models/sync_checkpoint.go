package models

import (
	"time"
)

// SyncCheckpoint 同步检查点模型
type SyncCheckpoint struct {
	ID        uint      `gorm:"primaryKey;autoIncrement"`
	UserID    uint      `gorm:"index:idx_checkpoint_user_device_type,unique;index;not null"`
	DeviceID  string    `gorm:"type:varchar(255);index:idx_checkpoint_user_device_type,unique;not null;default:''"` // 设备ID（用于多设备支持）
	SyncType  string    `gorm:"type:varchar(50);index:idx_checkpoint_user_device_type,unique;not null"`
	Ack       string    `gorm:"type:text;not null"` // Checkpoint 数据（JSON 字符串）
	CreatedAt time.Time `gorm:"not null"`
	UpdatedAt time.Time `gorm:"not null"`
}

// TableName 指定表名
func (SyncCheckpoint) TableName() string {
	return "sync_checkpoint"
}
