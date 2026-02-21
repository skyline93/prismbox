package local

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	"github.com/album/backend/internal/storage/config"
)

// TempFileManager 临时文件管理器
type TempFileManager struct {
	baseDir         string
	maxAge          time.Duration
	maxSize         int64
	currentSize     int64
	cleanupInterval time.Duration
	mu              sync.Mutex
	stopCh          chan struct{}
}

// NewTempFileManager 创建临时文件管理器
func NewTempFileManager(cfg *config.TempFileConfig) (*TempFileManager, error) {
	if cfg == nil {
		return nil, nil // 临时文件管理未启用
	}

	tm := &TempFileManager{
		baseDir:         cfg.BasePath,
		maxAge:          cfg.MaxAge.Duration(),
		maxSize:         cfg.MaxSize.Int64(),
		cleanupInterval: cfg.CleanupInterval.Duration(),
		stopCh:          make(chan struct{}),
	}

	// 确保目录存在
	if err := os.MkdirAll(tm.baseDir, 0755); err != nil {
		return nil, fmt.Errorf("create temp directory: %w", err)
	}

	// 计算当前大小
	if err := tm.updateCurrentSize(); err != nil {
		return nil, fmt.Errorf("update temp size: %w", err)
	}

	// 启动清理协程
	go tm.startCleanup()

	return tm, nil
}

// CreateTempFile 创建临时文件
func (tm *TempFileManager) CreateTempFile(prefix string, category string) (*os.File, error) {
	if tm == nil {
		// 如果未启用，使用系统临时目录
		return os.CreateTemp("", prefix+"_*.tmp")
	}

	tm.mu.Lock()
	defer tm.mu.Unlock()

	// 1. 清理过期文件
	if err := tm.cleanupExpired(); err != nil {
		return nil, fmt.Errorf("cleanup expired: %w", err)
	}

	// 2. 检查空间
	if tm.currentSize > tm.maxSize {
		return nil, fmt.Errorf("temp directory full: current=%d, max=%d", tm.currentSize, tm.maxSize)
	}

	// 3. 创建临时文件
	tempDir := filepath.Join(tm.baseDir, category)
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return nil, fmt.Errorf("create temp category directory: %w", err)
	}

	file, err := os.CreateTemp(tempDir, prefix+"_*.tmp")
	if err != nil {
		return nil, fmt.Errorf("create temp file: %w", err)
	}

	// 4. 注册到管理器（通过文件大小）
	info, err := file.Stat()
	if err == nil {
		tm.currentSize += info.Size()
	}

	return file, nil
}

// cleanupExpired 清理过期文件
func (tm *TempFileManager) cleanupExpired() error {
	now := time.Now()
	var totalSize int64

	err := filepath.Walk(tm.baseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}

		// 检查是否过期
		if now.Sub(info.ModTime()) > tm.maxAge {
			os.Remove(path)
		} else {
			totalSize += info.Size()
		}

		return nil
	})

	tm.currentSize = totalSize
	return err
}

// updateCurrentSize 更新当前大小
func (tm *TempFileManager) updateCurrentSize() error {
	var totalSize int64
	err := filepath.Walk(tm.baseDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			totalSize += info.Size()
		}
		return nil
	})

	tm.mu.Lock()
	tm.currentSize = totalSize
	tm.mu.Unlock()

	return err
}

// startCleanup 启动定期清理
func (tm *TempFileManager) startCleanup() {
	ticker := time.NewTicker(tm.cleanupInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			tm.mu.Lock()
			tm.cleanupExpired()
			tm.mu.Unlock()
		case <-tm.stopCh:
			return
		}
	}
}

// Close 关闭临时文件管理器
func (tm *TempFileManager) Close() error {
	if tm == nil {
		return nil
	}
	close(tm.stopCh)
	return nil
}
