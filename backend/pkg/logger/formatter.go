package logger

import (
	"time"
)

// LogEntry 日志条目
type LogEntry struct {
	Time    time.Time              `json:"time"`
	Level   string                 `json:"level"`
	Module  string                 `json:"module"`
	Message string                 `json:"msg"`
	Fields  map[string]interface{} `json:"fields,omitempty"`
	Caller  string                 `json:"caller,omitempty"`
	Stack   string                 `json:"stack,omitempty"`
}

// Formatter 格式化器接口
type Formatter interface {
	// Format 格式化日志条目
	Format(entry *LogEntry) ([]byte, error)
}

// createFormatter 根据格式类型创建格式化器
func createFormatter(format string) Formatter {
	switch format {
	case "json":
		return &JSONFormatter{}
	case "console":
		return &ConsoleFormatter{}
	default:
		return &JSONFormatter{} // 默认使用 JSON
	}
}
