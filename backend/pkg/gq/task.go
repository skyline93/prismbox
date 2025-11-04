package gq

import (
	"crypto/rand"
	"encoding/hex"
	"time"
)

// TaskInfo 是客户端使用的任务信息结构体
type TaskInfo struct {
	Type    string
	Payload []byte
}

// NewTask 创建一个新的任务信息
func NewTask(typeName string, payload []byte) *TaskInfo {
	return &TaskInfo{
		Type:    typeName,
		Payload: payload,
	}
}

// generateUUID 生成一个 UUID 字符串
func generateUUID() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// calculateNextProcessAt 计算下次处理时间（指数退避）
func calculateNextProcessAt(retryCount int) time.Time {
	// 初始延迟 1 秒，每次重试指数增长
	delay := time.Duration(1<<uint(retryCount)) * time.Second
	return time.Now().Add(delay)
}
