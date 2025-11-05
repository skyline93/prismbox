package logger

import (
	"fmt"
	"strings"
)

// ConsoleFormatter 控制台格式化器
type ConsoleFormatter struct{}

// Format 格式化日志条目为控制台格式
func (f *ConsoleFormatter) Format(entry *LogEntry) ([]byte, error) {
	var buf strings.Builder

	// 时间戳
	buf.WriteString(entry.Time.Format("2006-01-02 15:04:05.000"))
	buf.WriteString(" ")

	// 级别
	levelStr := strings.ToUpper(entry.Level)
	buf.WriteString("[")
	buf.WriteString(levelStr)
	buf.WriteString("]")
	buf.WriteString(" ")

	// 模块名
	buf.WriteString(entry.Module)
	buf.WriteString(" ")

	// 消息
	buf.WriteString(entry.Message)

	// 字段
	if len(entry.Fields) > 0 {
		buf.WriteString("\n")
		var fields []string
		for k, v := range entry.Fields {
			fields = append(fields, fmt.Sprintf("  %s=%v", k, v))
		}
		buf.WriteString(strings.Join(fields, "\n"))
	}

	// 调用位置
	if entry.Caller != "" {
		buf.WriteString("\n")
		buf.WriteString(fmt.Sprintf("  caller=%s", entry.Caller))
	}

	// 堆栈信息
	if entry.Stack != "" {
		buf.WriteString("\n")
		buf.WriteString("  stack:\n")
		lines := strings.Split(entry.Stack, "\n")
		for _, line := range lines {
			buf.WriteString(fmt.Sprintf("    %s\n", line))
		}
	}

	buf.WriteString("\n")

	// Console格式已经包含换行符
	return []byte(buf.String()), nil
}
