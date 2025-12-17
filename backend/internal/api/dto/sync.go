package dto

import "time"

// SyncRequestType 同步类型
type SyncRequestType string

const (
	SyncRequestTypeAssetsV1 SyncRequestType = "assets_v1"
)

// SyncStreamRequest 流式同步请求
type SyncStreamRequest struct {
	Types       []SyncRequestType `json:"types" binding:"required,min=1"`
	Reset       bool              `json:"reset"`
	UpdatedAfter *string           `json:"updated_after,omitempty"` // RFC3339 格式的时间戳
}

// CheckpointDto 检查点 DTO
type CheckpointDto struct {
	Type string `json:"type"` // 同步类型（如 "assets_v1"）
	Ack  string `json:"ack"`  // Checkpoint ID
}

// GetCheckpointResponse 获取检查点响应
type GetCheckpointResponse struct {
	Checkpoints []CheckpointDto `json:"checkpoints"`
}

// SetCheckpointRequest 设置检查点请求
type SetCheckpointRequest struct {
	Checkpoints []CheckpointDto `json:"checkpoints" binding:"required,min=1"`
}

// DeleteCheckpointRequest 删除检查点请求
type DeleteCheckpointRequest struct {
	Types []string `json:"types" binding:"required,min=1"` // 要删除的同步类型列表
}

// SyncAssetsResponse 全量同步响应（游标分页）
type SyncAssetsResponse struct {
	Assets     []*MediaResponse `json:"assets"`
	NextLastID string           `json:"next_last_id"`
	HasMore    bool             `json:"has_more"`
}

// ParseUpdatedAfter 解析 updated_after 字段
func (r *SyncStreamRequest) ParseUpdatedAfter() (*time.Time, error) {
	if r.UpdatedAfter == nil || *r.UpdatedAfter == "" {
		return nil, nil
	}
	t, err := time.Parse(time.RFC3339, *r.UpdatedAfter)
	if err != nil {
		return nil, err
	}
	return &t, nil
}

