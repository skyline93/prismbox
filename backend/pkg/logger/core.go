package logger

import (
	"runtime"
	"strconv"
	"sync"
)

// globalConfig 全局配置管理器（单例）
type globalConfig struct {
	mu           sync.RWMutex
	config       *Config
	sharedWriter *sharedWriter
	level        Level
	formatter    Formatter
}

var (
	global     *globalConfig
	globalOnce sync.Once
)

// Init 初始化全局配置（应用启动时调用一次）
func Init(config *Config) error {
	var initErr error
	globalOnce.Do(func() {
		global = &globalConfig{
			config: config,
			level:  parseLevel(config.Level),
		}

		// 创建共享写入器
		writer, err := NewSharedWriter(config)
		if err != nil {
			initErr = err
			return
		}
		global.sharedWriter = writer

		// 创建格式化器
		global.formatter = createFormatter(config.Format)
	})

	return initErr
}

// getGlobalConfig 获取全局配置（读锁保护）
func getGlobalConfig() *globalConfig {
	global.mu.RLock()
	defer global.mu.RUnlock()
	return global
}

// UpdateConfig 更新配置（写锁保护）
func UpdateConfig(config *Config) error {
	global.mu.Lock()
	defer global.mu.Unlock()

	// 关闭旧的写入器
	if global.sharedWriter != nil {
		global.sharedWriter.Close()
	}

	// 创建新的写入器
	writer, err := NewSharedWriter(config)
	if err != nil {
		return err
	}

	global.config = config
	global.sharedWriter = writer
	global.level = parseLevel(config.Level)
	global.formatter = createFormatter(config.Format)

	return nil
}

// Sync 同步所有日志写入（应用关闭时调用）
func Sync() error {
	if global == nil {
		return nil
	}

	global.mu.Lock()
	defer global.mu.Unlock()

	if global.sharedWriter != nil {
		return global.sharedWriter.Close()
	}

	return nil
}

// getCaller 获取调用位置
func getCaller(skip int) string {
	_, file, line, ok := runtime.Caller(skip)
	if !ok {
		return ""
	}
	// 简化文件路径，只显示文件名
	for i := len(file) - 1; i > 0; i-- {
		if file[i] == '/' {
			file = file[i+1:]
			break
		}
	}
	return file + ":" + strconv.Itoa(line)
}

// getStack 获取堆栈信息
func getStack() string {
	buf := make([]byte, 4096)
	n := runtime.Stack(buf, false)
	if n > 0 {
		return string(buf[:n])
	}
	return ""
}
