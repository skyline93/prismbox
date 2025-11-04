package gq

import "time"

// Option 是配置选项的接口
type Option interface {
	apply(*taskOptions)
}

// taskOptions 存储任务的所有选项
type taskOptions struct {
	queue      string
	priority   int
	maxRetries int
	processAt  *time.Time
}

// defaultTaskOptions 返回默认选项
func defaultTaskOptions() *taskOptions {
	return &taskOptions{
		queue:      "default",
		priority:   0,
		maxRetries: 3,
		processAt:  nil,
	}
}

// queueOption 队列名称选项
type queueOption string

func (o queueOption) apply(opts *taskOptions) {
	opts.queue = string(o)
}

// Queue 设置任务所属的队列名称
func Queue(name string) Option {
	return queueOption(name)
}

// priorityOption 优先级选项
type priorityOption int

func (o priorityOption) apply(opts *taskOptions) {
	opts.priority = int(o)
}

// Priority 设置任务优先级（数值越大，优先级越高）
func Priority(p int) Option {
	return priorityOption(p)
}

// maxRetriesOption 最大重试次数选项
type maxRetriesOption int

func (o maxRetriesOption) apply(opts *taskOptions) {
	opts.maxRetries = int(o)
}

// MaxRetries 设置任务的最大重试次数
func MaxRetries(n int) Option {
	return maxRetriesOption(n)
}

// processAtOption 计划执行时间选项
type processAtOption struct {
	t time.Time
}

func (o *processAtOption) apply(opts *taskOptions) {
	opts.processAt = &o.t
}

// ProcessAt 设置任务的计划执行时间
func ProcessAt(t time.Time) Option {
	return &processAtOption{t: t}
}
