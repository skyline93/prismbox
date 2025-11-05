package logger

// Writer 写入器接口
type Writer interface {
	// Write 写入日志条目
	Write(entry *LogEntry) error
	// Close 关闭写入器
	Close() error
}
