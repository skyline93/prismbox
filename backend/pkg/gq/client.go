package gq

import (
	"context"
	"time"

	"gorm.io/gorm"
)

// Client 负责创建任务并将其推送到数据库中
type Client struct {
	db *gorm.DB
}

// NewClient 创建一个新的客户端实例
func NewClient(db *gorm.DB) *Client {
	return &Client{db: db}
}

// Enqueue 将一个任务添加到队列中
func (c *Client) Enqueue(ctx context.Context, task *TaskInfo, opts ...Option) error {
	// 应用选项
	options := defaultTaskOptions()
	for _, opt := range opts {
		opt.apply(options)
	}

	// 构造数据库任务模型
	dbTask := &Task{
		UUID:       generateUUID(),
		Queue:      options.queue,
		Type:       task.Type,
		Payload:    task.Payload,
		Status:     StatusPending,
		Priority:   options.priority,
		MaxRetries: options.maxRetries,
		RetryCount: 0,
	}

	// 设置处理时间
	if options.processAt != nil {
		dbTask.ProcessAt = *options.processAt
	} else {
		dbTask.ProcessAt = time.Now()
	}

	// 保存到数据库
	return c.db.WithContext(ctx).Create(dbTask).Error
}
