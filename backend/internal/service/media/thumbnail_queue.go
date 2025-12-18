package media

import (
	"context"
	"sync"
	"time"

	"github.com/album/backend/pkg/logger"
)

// ThumbnailGenerationTask 缩略图生成任务
type ThumbnailGenerationTask struct {
	MediaUUID string
	SizeParam string
	Key       string // 存储 key
	CreatedAt time.Time
}

// ThumbnailQueue 缩略图生成队列管理器
// 用于避免并发请求重复生成相同的缩略图
type ThumbnailQueue struct {
	mu          sync.RWMutex
	generating  map[string]*generationState // key -> 生成状态
	log         logger.Logger
	maxWaitTime time.Duration // 最大等待时间
}

type generationState struct {
	task      *ThumbnailGenerationTask
	startedAt time.Time
	waiters   []chan error // 等待生成完成的通道
}

// NewThumbnailQueue 创建缩略图生成队列
func NewThumbnailQueue() *ThumbnailQueue {
	return &ThumbnailQueue{
		generating:  make(map[string]*generationState),
		log:         logger.New("service.media.thumbnail_queue"),
		maxWaitTime: 30 * time.Second, // 最大等待30秒
	}
}

// TryAcquire 尝试获取生成权限
// 如果返回 true，表示获得了生成权限，需要调用者负责生成
// 如果返回 false，表示已有其他请求正在生成，返回 waitCh 等待完成
func (q *ThumbnailQueue) TryAcquire(key string, task *ThumbnailGenerationTask) (acquired bool, waitCh <-chan error) {
	q.mu.Lock()
	defer q.mu.Unlock()

	// 检查是否正在生成
	if state, exists := q.generating[key]; exists {
		// 已有生成任务，加入等待队列
		ch := make(chan error, 1)
		state.waiters = append(state.waiters, ch)
		return false, ch
	}

	// 获得生成权限
	q.generating[key] = &generationState{
		task:      task,
		startedAt: time.Now(),
		waiters:   make([]chan error, 0),
	}
	return true, nil
}

// Complete 标记生成完成
func (q *ThumbnailQueue) Complete(key string, err error) {
	q.mu.Lock()
	defer q.mu.Unlock()

	state, exists := q.generating[key]
	if !exists {
		return
	}

	// 通知所有等待者
	for _, ch := range state.waiters {
		select {
		case ch <- err:
		default:
		}
		close(ch)
	}

	// 移除生成状态
	delete(q.generating, key)

	// 记录生成时间
	if err == nil {
		duration := time.Since(state.startedAt)
		q.log.Debug("thumbnail generation completed",
			logger.String("key", key),
			logger.Duration("duration", duration),
		)
	} else {
		q.log.Warn("thumbnail generation failed",
			logger.String("key", key),
			logger.Error(err),
		)
	}
}

// Cleanup 清理超时的生成任务
func (q *ThumbnailQueue) Cleanup() {
	q.mu.Lock()
	defer q.mu.Unlock()

	now := time.Now()
	for key, state := range q.generating {
		if now.Sub(state.startedAt) > q.maxWaitTime {
			// 超时，通知等待者并移除
			for _, ch := range state.waiters {
				select {
				case ch <- context.DeadlineExceeded:
				default:
				}
				close(ch)
			}
			delete(q.generating, key)
			q.log.Warn("thumbnail generation timeout",
				logger.String("key", key),
				logger.Duration("timeout", q.maxWaitTime),
			)
		}
	}
}

// StartCleanup 启动定期清理任务
func (q *ThumbnailQueue) StartCleanup(ctx context.Context) {
	ticker := time.NewTicker(1 * time.Minute)
	go func() {
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				q.Cleanup()
			}
		}
	}()
}

// GetStats 获取队列统计信息
func (q *ThumbnailQueue) GetStats() map[string]interface{} {
	q.mu.RLock()
	defer q.mu.RUnlock()

	return map[string]interface{}{
		"generating_count": len(q.generating),
		"max_wait_time":    q.maxWaitTime.String(),
	}
}
