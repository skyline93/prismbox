package gq

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"sync"
	"time"

	"gorm.io/gorm"
)

// Server 负责从数据库中拉取任务，并根据其类型分发给对应的处理器执行
type Server struct {
	db          *gorm.DB
	concurrency int
	tasksChan   chan *Task
	mux         *ServeMux
	wg          sync.WaitGroup
	ctx         context.Context
	cancel      context.CancelFunc
	mu          sync.Mutex
	running     bool
	// 动态轮询间隔相关
	pollInterval time.Duration
	minInterval  time.Duration
	maxInterval  time.Duration
}

// ServerConfig 是服务器配置
type ServerConfig struct {
	// 并发 Worker 数量
	Concurrency int
	// 最小轮询间隔（毫秒）
	MinPollIntervalMs int
	// 最大轮询间隔（毫秒）
	MaxPollIntervalMs int
}

// DefaultServerConfig 返回默认配置
func DefaultServerConfig() *ServerConfig {
	return &ServerConfig{
		Concurrency:       10,
		MinPollIntervalMs: 100,
		MaxPollIntervalMs: 5000,
	}
}

// NewServer 创建一个新的服务端实例
func NewServer(db *gorm.DB, config *ServerConfig) *Server {
	if config == nil {
		config = DefaultServerConfig()
	}

	ctx, cancel := context.WithCancel(context.Background())

	minInterval := time.Duration(config.MinPollIntervalMs) * time.Millisecond
	maxInterval := time.Duration(config.MaxPollIntervalMs) * time.Millisecond

	return &Server{
		db:           db,
		concurrency:  config.Concurrency,
		tasksChan:    make(chan *Task, config.Concurrency),
		mux:          NewServeMux(),
		ctx:          ctx,
		cancel:       cancel,
		pollInterval: minInterval,
		minInterval:  minInterval,
		maxInterval:  maxInterval,
	}
}

// Run 启动服务器，开始处理任务
func (s *Server) Run(mux *ServeMux) error {
	s.mu.Lock()
	if s.running {
		s.mu.Unlock()
		return fmt.Errorf("server is already running")
	}
	s.running = true
	s.mux = mux
	s.mu.Unlock()

	// 启动 Workers
	for i := 0; i < s.concurrency; i++ {
		s.wg.Add(1)
		go s.worker(i)
	}

	// 启动调度器
	s.wg.Add(1)
	go s.scheduler()

	log.Printf("[GQ] Server started with %d workers", s.concurrency)
	return nil
}

// Shutdown 优雅关闭服务器
func (s *Server) Shutdown(ctx context.Context) error {
	s.mu.Lock()
	if !s.running {
		s.mu.Unlock()
		return nil
	}
	s.mu.Unlock()

	log.Println("[GQ] Shutting down server...")
	s.cancel()

	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		log.Println("[GQ] Server stopped gracefully")
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}

// scheduler 调度循环，定期从数据库中拉取可执行的任务
func (s *Server) scheduler() {
	defer s.wg.Done()

	ticker := time.NewTicker(s.pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-s.ctx.Done():
			return
		case <-ticker.C:
			s.fetchAndDistributeTasks()
			// 动态调整轮询间隔
			ticker.Reset(s.pollInterval)
		}
	}
}

// fetchAndDistributeTasks 从数据库获取任务并分发
func (s *Server) fetchAndDistributeTasks() {
	// 计算需要拉取的任务数量（可用的 worker 数量）
	availableWorkers := s.concurrency - len(s.tasksChan)
	if availableWorkers <= 0 {
		// 没有可用的 worker，增加轮询间隔
		s.adjustPollInterval(true)
		return
	}

	var tasks []Task
	err := s.db.Transaction(func(tx *gorm.DB) error {
		// 使用 FOR UPDATE SKIP LOCKED 锁定任务
		// 注意：某些数据库可能不支持 SKIP LOCKED，需要根据实际数据库类型调整
		result := tx.Set("gorm:query_option", "FOR UPDATE SKIP LOCKED").
			Where("status IN ? AND process_at <= ?",
				[]string{StatusPending, StatusRetrying}, time.Now()).
			Order("priority DESC, process_at ASC").
			Limit(availableWorkers).
			Find(&tasks)

		if result.Error != nil {
			return result.Error
		}

		if len(tasks) == 0 {
			return nil
		}

		// 更新任务状态为 active
		// 使用 ID 列表更新
		var ids []uint
		for i := range tasks {
			// gorm.Model 嵌入后，ID 字段可以直接访问
			// 如果 linter 报错，这是误报，代码可以正常运行
			task := tasks[i]
			ids = append(ids, task.Model.ID)
		}

		return tx.Model(&Task{}).
			Where("id IN ?", ids).
			Update("status", StatusActive).Error
	})

	if err != nil {
		log.Printf("[GQ] Error fetching tasks: %v", err)
		return
	}

	if len(tasks) == 0 {
		// 没有任务，增加轮询间隔
		s.adjustPollInterval(true)
		return
	}

	// 分发任务到 channel
	for i := range tasks {
		select {
		case <-s.ctx.Done():
			return
		case s.tasksChan <- &tasks[i]:
			// 任务已分发
		default:
			// channel 已满，这不应该发生
		}
	}

	// 有任务，减少轮询间隔
	s.adjustPollInterval(false)
}

// adjustPollInterval 动态调整轮询间隔
func (s *Server) adjustPollInterval(noTasks bool) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if noTasks {
		// 没有任务，增加间隔
		s.pollInterval = time.Duration(float64(s.pollInterval) * 1.5)
		if s.pollInterval > s.maxInterval {
			s.pollInterval = s.maxInterval
		}
	} else {
		// 有任务，减少间隔
		s.pollInterval = time.Duration(float64(s.pollInterval) * 0.7)
		if s.pollInterval < s.minInterval {
			s.pollInterval = s.minInterval
		}
	}
}

// worker 是工作协程，负责执行任务
func (s *Server) worker(id int) {
	defer s.wg.Done()

	log.Printf("[GQ] Worker %d started", id)

	for {
		select {
		case <-s.ctx.Done():
			log.Printf("[GQ] Worker %d stopped", id)
			return
		case task := <-s.tasksChan:
			s.processTask(task)
		}
	}
}

// processTask 处理单个任务
func (s *Server) processTask(task *Task) {
	// 获取处理器
	handler, ok := s.mux.GetHandler(task.Type)
	if !ok {
		log.Printf("[GQ] No handler found for task type: %s", task.Type)
		s.handleTaskFailure(task, fmt.Errorf("no handler found for task type: %s", task.Type))
		return
	}

	// 创建任务上下文
	ctx := context.Background()

	// 执行任务
	err := handler.ProcessTask(ctx, task)

	if err != nil {
		log.Printf("[GQ] Task %s (type: %s) failed: %v", task.UUID, task.Type, err)
		s.handleTaskFailure(task, err)
	} else {
		log.Printf("[GQ] Task %s (type: %s) completed successfully", task.UUID, task.Type)
		s.handleTaskSuccess(task)
	}
}

// handleTaskSuccess 处理任务成功
func (s *Server) handleTaskSuccess(task *Task) {
	now := time.Now()
	processedAt := &sql.NullTime{
		Time:  now,
		Valid: true,
	}

	s.db.Model(task).Updates(map[string]interface{}{
		"status":       StatusArchived,
		"processed_at": processedAt,
		"last_error":   "",
	})
}

// handleTaskFailure 处理任务失败
func (s *Server) handleTaskFailure(task *Task, err error) {
	task.RetryCount++
	task.LastError = err.Error()

	if task.RetryCount >= task.MaxRetries {
		// 达到最大重试次数，标记为失败
		now := time.Now()
		failedAt := &sql.NullTime{
			Time:  now,
			Valid: true,
		}

		s.db.Model(task).Updates(map[string]interface{}{
			"status":     StatusFailed,
			"failed_at":  failedAt,
			"last_error": task.LastError,
		})
		log.Printf("[GQ] Task %s permanently failed after %d retries", task.UUID, task.RetryCount)
	} else {
		// 重试任务
		nextProcessAt := calculateNextProcessAt(task.RetryCount)
		task.ProcessAt = nextProcessAt

		s.db.Model(task).Updates(map[string]interface{}{
			"status":     StatusRetrying,
			"process_at": nextProcessAt,
			"last_error": task.LastError,
		})
		log.Printf("[GQ] Task %s will retry (attempt %d/%d) at %v",
			task.UUID, task.RetryCount, task.MaxRetries, nextProcessAt)
	}
}
