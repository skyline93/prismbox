package pool

import (
	"context"
	"errors"
	"time"
)

// ErrPoolClosed 表示资源池已关闭。
var ErrPoolClosed = errors.New("media-processor: pool closed")

// ResourceFactory 用于创建资源。
type ResourceFactory[T any] func() (T, error)

// ResourceDestructor 用于销毁资源。
type ResourceDestructor[T any] func(T)

// Config 控制通用资源池行为。
type Config struct {
	MaxSize       int
	IdleTimeout   time.Duration
	GetTimeout    time.Duration
	ResourceName  string
	OverProvision bool
}

// Pool 是一个协程安全的通用资源池。
type Pool[T any] struct {
	ch         chan item[T]
	cfg        Config
	factory    ResourceFactory[T]
	destructor ResourceDestructor[T]
	closed     chan struct{}
}

type item[T any] struct {
	value     T
	expiresAt time.Time
}

// New 创建资源池。
func New[T any](cfg Config, factory ResourceFactory[T], destructor ResourceDestructor[T]) *Pool[T] {
	return &Pool[T]{
		ch:         make(chan item[T], cfg.MaxSize),
		cfg:        cfg,
		factory:    factory,
		destructor: destructor,
		closed:     make(chan struct{}),
	}
}

// Get 取出资源。
func (p *Pool[T]) Get(ctx context.Context) (T, error) {
	var zero T

	select {
	case <-ctx.Done():
		return zero, ctx.Err()
	case <-p.closed:
		return zero, ErrPoolClosed
	default:
	}

	select {
	case it := <-p.ch:
		if p.cfg.IdleTimeout > 0 && time.Now().After(it.expiresAt) {
			p.destructor(it.value)
			return p.factory()
		}
		return it.value, nil
	default:
		return p.factory()
	}
}

// Put 将资源归还到池中。
func (p *Pool[T]) Put(res T) {
	select {
	case <-p.closed:
		p.destructor(res)
		return
	default:
	}

	it := item[T]{
		value:     res,
		expiresAt: time.Now().Add(p.cfg.IdleTimeout),
	}

	select {
	case p.ch <- it:
	default:
		p.destructor(res)
	}
}

// Close 关闭资源池。
func (p *Pool[T]) Close() {
	select {
	case <-p.closed:
		return
	default:
		close(p.closed)
	}

	for {
		select {
		case it := <-p.ch:
			p.destructor(it.value)
		default:
			return
		}
	}
}
