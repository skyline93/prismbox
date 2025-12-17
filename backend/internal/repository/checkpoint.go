package repository

import (
	"context"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/album/backend/internal/database/models"
	"gorm.io/gorm"
)

// checkpointRepository 检查点仓储实现
type checkpointRepository struct {
	db *gorm.DB
}

// NewCheckpointRepository 创建检查点仓储
func NewCheckpointRepository(db *gorm.DB) CheckpointRepository {
	return &checkpointRepository{
		db: db,
	}
}

// GetCheckpoint 获取检查点
func (r *checkpointRepository) GetCheckpoint(ctx context.Context, userID uint, deviceID string, syncType string) (*models.SyncCheckpoint, error) {
	var checkpoint models.SyncCheckpoint
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND device_id = ? AND sync_type = ?", userID, deviceID, syncType).
		First(&checkpoint).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			return nil, nil // 返回 nil 表示没有检查点
		}
		return nil, err
	}
	return &checkpoint, nil
}

// SetCheckpoint 设置检查点
func (r *checkpointRepository) SetCheckpoint(ctx context.Context, userID uint, deviceID string, syncType string, ack string) error {
	checkpoint := &models.SyncCheckpoint{
		UserID:    userID,
		DeviceID:  deviceID,
		SyncType:  syncType,
		Ack:       ack,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// 使用 FirstOrCreate，如果存在则更新
	var existing models.SyncCheckpoint
	err := r.db.WithContext(ctx).
		Where("user_id = ? AND device_id = ? AND sync_type = ?", userID, deviceID, syncType).
		First(&existing).Error

	if err != nil {
		if err == gorm.ErrRecordNotFound {
			// 不存在，创建新记录
			return r.db.WithContext(ctx).Create(checkpoint).Error
		}
		return err
	}

	// 存在，更新记录
	return r.db.WithContext(ctx).
		Model(&existing).
		Updates(map[string]interface{}{
			"ack":        ack,
			"updated_at": time.Now(),
		}).Error
}

// DeleteCheckpoint 删除检查点
func (r *checkpointRepository) DeleteCheckpoint(ctx context.Context, userID uint, deviceID string, syncType string) error {
	return r.db.WithContext(ctx).
		Where("user_id = ? AND device_id = ? AND sync_type = ?", userID, deviceID, syncType).
		Delete(&models.SyncCheckpoint{}).Error
}

// ResetSyncProgress 重置同步进度（删除所有检查点）
func (r *checkpointRepository) ResetSyncProgress(ctx context.Context, userID uint, deviceID string) error {
	return r.db.WithContext(ctx).
		Where("user_id = ? AND device_id = ?", userID, deviceID).
		Delete(&models.SyncCheckpoint{}).Error
}

// GetNowID 获取当前时间ID（用于生成checkpoint）
// 格式：时间戳 + 随机数（Base64 编码）
func (r *checkpointRepository) GetNowID() string {
	now := time.Now()
	timestamp := now.Format("20060102150405")
	// 添加纳秒时间戳的随机部分
	nanos := fmt.Sprintf("%09d", now.Nanosecond())
	combined := timestamp + "-" + nanos
	// Base64 编码
	return base64.URLEncoding.EncodeToString([]byte(combined))
}
