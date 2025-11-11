package imageprocessor

import (
	"sync"
	"sync/atomic"

	"gopkg.in/gographics/imagick.v3/imagick"

	"github.com/album/backend/pkg/media-processor/core"
)

// ImagickManager 管理 ImageMagick 生命周期。
type ImagickManager struct {
	mu          sync.RWMutex
	initialized bool
	closed      bool
	refCount    atomic.Int64
}

var (
	managerOnce sync.Once
	globalMgr   *ImagickManager
)

// GetManager 获取全局单例管理器。
func GetManager() *ImagickManager {
	managerOnce.Do(func() {
		globalMgr = &ImagickManager{}
	})
	return globalMgr
}

// Initialize 初始化 ImageMagick。
func (m *ImagickManager) Initialize() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if m.initialized {
		return nil
	}
	if m.closed {
		return core.ErrImagickClosed
	}

	imagick.Initialize()
	m.initialized = true
	return nil
}

// Acquire 增加引用计数。
func (m *ImagickManager) Acquire() error {
	m.mu.RLock()
	defer m.mu.RUnlock()

	if !m.initialized {
		return core.ErrImagickNotInitialized
	}
	if m.closed {
		return core.ErrImagickClosed
	}

	m.refCount.Add(1)
	return nil
}

// Release 释放引用。
func (m *ImagickManager) Release() {
	if m.refCount.Load() == 0 {
		return
	}
	m.refCount.Add(-1)
}

// Close 关闭 ImageMagick。
func (m *ImagickManager) Close() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if !m.initialized || m.closed {
		return nil
	}
	if m.refCount.Load() > 0 {
		return core.ErrImagickInUse
	}

	imagick.Terminate()
	m.closed = true
	return nil
}

// IsInitialized 判断是否初始化。
func (m *ImagickManager) IsInitialized() bool {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return m.initialized && !m.closed
}
