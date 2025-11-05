package logger

import (
	"io"
	"os"
	"sync"
	"sync/atomic"
	"time"
)

// sharedWriter 共享写入器实现（线程安全）
type sharedWriter struct {
	mu        sync.Mutex
	writer    io.Writer
	buffer    chan *LogEntry
	wg        sync.WaitGroup
	closed    atomic.Bool
	formatter Formatter
}

// NewSharedWriter 创建共享写入器
func NewSharedWriter(config *Config) (*sharedWriter, error) {
	var writer io.Writer

	// 根据输出类型创建写入器
	switch config.Output {
	case "stdout":
		writer = os.Stdout
	case "stderr":
		writer = os.Stderr
	default:
		// 文件输出（Output 是文件路径）
		if config.FileConfig != nil {
			fileWriter, err := NewFileWriter(
				config.FileConfig.Path,
				config.FileConfig.MaxSize,
				config.FileConfig.MaxAge,
				config.FileConfig.MaxBackups,
				config.FileConfig.Compress,
			)
			if err != nil {
				return nil, err
			}
			writer = fileWriter
		} else if config.Output != "" && config.Output != "stdout" && config.Output != "stderr" {
			// 如果Output是文件路径，但没有FileConfig，使用Output作为路径
			fileWriter, err := NewFileWriter(
				config.Output,
				0,     // 不限制大小
				0,     // 不限制天数
				0,     // 不限制备份数量
				false, // 不压缩
			)
			if err != nil {
				return nil, err
			}
			writer = fileWriter
		} else {
			writer = os.Stdout // 默认使用 stdout
		}
	}

	sw := &sharedWriter{
		writer:    writer,
		formatter: createFormatter(config.Format),
	}

	// 如果启用异步写入，创建缓冲通道
	if config.Async {
		bufferSize := config.BufferSize
		if bufferSize <= 0 {
			bufferSize = 1000 // 默认缓冲大小
		}
		sw.buffer = make(chan *LogEntry, bufferSize)
		sw.wg.Add(1)
		go sw.flushLoop()
	}

	return sw, nil
}

// Write 同步写入日志条目
func (sw *sharedWriter) Write(entry *LogEntry) error {
	sw.mu.Lock()
	defer sw.mu.Unlock()

	data, err := sw.formatter.Format(entry)
	if err != nil {
		return err
	}

	_, err = sw.writer.Write(data)
	return err
}

// WriteAsync 异步写入日志条目
func (sw *sharedWriter) WriteAsync(entry *LogEntry) error {
	if sw.buffer == nil {
		// 如果没有缓冲通道，降级为同步写入
		return sw.Write(entry)
	}

	if sw.closed.Load() {
		// 如果已关闭，降级为同步写入
		return sw.Write(entry)
	}

	select {
	case sw.buffer <- entry:
		return nil
	default:
		// 缓冲区满，降级为同步写入
		return sw.Write(entry)
	}
}

// flushLoop 异步刷新循环
func (sw *sharedWriter) flushLoop() {
	defer sw.wg.Done()

	ticker := time.NewTicker(100 * time.Millisecond)
	defer ticker.Stop()

	batch := make([]*LogEntry, 0, 100)
	batchSize := 100

	for {
		select {
		case entry, ok := <-sw.buffer:
			if !ok {
				// 通道关闭，刷新剩余条目
				sw.flushBatch(batch)
				return
			}
			batch = append(batch, entry)
			if len(batch) >= batchSize {
				sw.flushBatch(batch)
				batch = batch[:0]
			}
		case <-ticker.C:
			// 定时刷新
			if len(batch) > 0 {
				sw.flushBatch(batch)
				batch = batch[:0]
			}
		}
	}
}

// flushBatch 批量刷新日志条目
func (sw *sharedWriter) flushBatch(batch []*LogEntry) {
	if len(batch) == 0 {
		return
	}

	sw.mu.Lock()
	defer sw.mu.Unlock()

	for _, entry := range batch {
		data, err := sw.formatter.Format(entry)
		if err != nil {
			continue
		}
		sw.writer.Write(data)
	}
}

// Close 关闭写入器
func (sw *sharedWriter) Close() error {
	if sw.buffer != nil {
		sw.closed.Store(true)
		close(sw.buffer)
		sw.wg.Wait()
	}

	// 如果底层写入器实现了 Close 方法，调用它
	if closer, ok := sw.writer.(io.Closer); ok {
		return closer.Close()
	}

	return nil
}
