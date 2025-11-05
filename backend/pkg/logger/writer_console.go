package logger

import (
	"io"
	"os"
)

// ConsoleWriter 控制台写入器
type ConsoleWriter struct {
	writer io.Writer
}

// NewConsoleWriter 创建控制台写入器
func NewConsoleWriter(output string) (*ConsoleWriter, error) {
	var writer io.Writer
	switch output {
	case "stdout":
		writer = os.Stdout
	case "stderr":
		writer = os.Stderr
	default:
		writer = os.Stdout // 默认使用 stdout
	}

	return &ConsoleWriter{
		writer: writer,
	}, nil
}

// Write 写入日志条目
func (w *ConsoleWriter) Write(entry *LogEntry) error {
	// 写入器不需要格式化，格式化由共享写入器处理
	// 这里只负责写入，实际上不会被直接调用
	return nil
}

// Close 关闭写入器
func (w *ConsoleWriter) Close() error {
	return nil
}
