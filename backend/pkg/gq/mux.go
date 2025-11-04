package gq

import (
	"context"
	"sync"
)

// Handler 是处理任务的接口
type Handler interface {
	ProcessTask(ctx context.Context, task *Task) error
}

// HandlerFunc 是 Handler 的函数类型适配器
type HandlerFunc func(ctx context.Context, task *Task) error

// ProcessTask 实现 Handler 接口
func (f HandlerFunc) ProcessTask(ctx context.Context, task *Task) error {
	return f(ctx, task)
}

// ServeMux 是多路复用器，用于注册任务类型和其对应的处理器
type ServeMux struct {
	mu sync.RWMutex
	m  map[string]Handler
}

// NewServeMux 创建一个新的 ServeMux
func NewServeMux() *ServeMux {
	return &ServeMux{
		m: make(map[string]Handler),
	}
}

// Handle 注册一个任务类型和其对应的处理器
func (mux *ServeMux) Handle(taskType string, handler Handler) {
	mux.mu.Lock()
	defer mux.mu.Unlock()
	mux.m[taskType] = handler
}

// HandleFunc 注册一个任务类型和其对应的处理器函数
func (mux *ServeMux) HandleFunc(taskType string, handler func(ctx context.Context, task *Task) error) {
	mux.Handle(taskType, HandlerFunc(handler))
}

// GetHandler 获取指定任务类型的处理器
func (mux *ServeMux) GetHandler(taskType string) (Handler, bool) {
	mux.mu.RLock()
	defer mux.mu.RUnlock()
	handler, ok := mux.m[taskType]
	return handler, ok
}
