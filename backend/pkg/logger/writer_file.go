package logger

import (
	"os"
	"path/filepath"
	"sync"
	"time"
)

// FileWriter 文件写入器（带轮转）
type FileWriter struct {
	mu         sync.Mutex
	file       *os.File
	path       string
	maxSize    int64
	maxAge     int
	maxBackups int
	compress   bool
}

// NewFileWriter 创建文件写入器
func NewFileWriter(path string, maxSize int64, maxAge, maxBackups int, compress bool) (*FileWriter, error) {
	// 确保目录存在
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, err
	}

	// 打开或创建文件
	file, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return nil, err
	}

	return &FileWriter{
		file:       file,
		path:       path,
		maxSize:    maxSize,
		maxAge:     maxAge,
		maxBackups: maxBackups,
		compress:   compress,
	}, nil
}

// Write 写入日志条目
func (w *FileWriter) Write(data []byte) (int, error) {
	w.mu.Lock()
	defer w.mu.Unlock()

	// 检查是否需要轮转
	if err := w.rotateIfNeeded(); err != nil {
		return 0, err
	}

	return w.file.Write(data)
}

// rotateIfNeeded 如果需要则进行文件轮转
func (w *FileWriter) rotateIfNeeded() error {
	// 检查文件大小
	info, err := w.file.Stat()
	if err != nil {
		return err
	}

	// 如果文件大小超过限制，进行轮转
	if w.maxSize > 0 && info.Size() >= w.maxSize {
		return w.rotate()
	}

	return nil
}

// rotate 执行文件轮转
func (w *FileWriter) rotate() error {
	// 关闭当前文件
	if err := w.file.Close(); err != nil {
		return err
	}

	// 生成时间戳文件名
	timestamp := time.Now().Format("20060102-150405")
	rotatedPath := w.path + "." + timestamp

	// 重命名当前文件
	if err := os.Rename(w.path, rotatedPath); err != nil {
		// 如果重命名失败，尝试重新打开原文件
		file, err := os.OpenFile(w.path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
		if err != nil {
			return err
		}
		w.file = file
		return err
	}

	// 创建新文件
	file, err := os.OpenFile(w.path, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return err
	}
	w.file = file

	// 清理旧文件
	go w.cleanup()

	return nil
}

// cleanup 清理旧文件
func (w *FileWriter) cleanup() {
	dir := filepath.Dir(w.path)
	baseName := filepath.Base(w.path)

	// 读取目录中的所有文件
	entries, err := os.ReadDir(dir)
	if err != nil {
		return
	}

	now := time.Now()
	var files []os.FileInfo

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		// 检查是否是日志文件
		name := entry.Name()
		if name != baseName && len(name) > len(baseName) && name[:len(baseName)] == baseName {
			info, err := entry.Info()
			if err != nil {
				continue
			}
			files = append(files, info)
		}
	}

	// 按修改时间排序（最新的在前）
	for i := 0; i < len(files)-1; i++ {
		for j := i + 1; j < len(files); j++ {
			if files[i].ModTime().Before(files[j].ModTime()) {
				files[i], files[j] = files[j], files[i]
			}
		}
	}

	// 删除超过保留数量的文件
	if w.maxBackups > 0 && len(files) > w.maxBackups {
		for i := w.maxBackups; i < len(files); i++ {
			filePath := filepath.Join(dir, files[i].Name())
			os.Remove(filePath)
		}
		files = files[:w.maxBackups]
	}

	// 删除超过保留天数的文件
	if w.maxAge > 0 {
		cutoff := now.AddDate(0, 0, -w.maxAge)
		for _, file := range files {
			if file.ModTime().Before(cutoff) {
				filePath := filepath.Join(dir, file.Name())
				os.Remove(filePath)
			}
		}
	}
}

// Close 关闭写入器
func (w *FileWriter) Close() error {
	w.mu.Lock()
	defer w.mu.Unlock()

	if w.file != nil {
		return w.file.Close()
	}
	return nil
}
