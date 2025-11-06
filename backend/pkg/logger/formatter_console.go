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
		buf.WriteString(" ")
		var fields []string
		for k, v := range entry.Fields {
			// 排除 module 字段，因为模块名已经在前面显示了
			if k != "module" {
				fields = append(fields, fmt.Sprintf("%s=%v", k, v))
			}
		}
		if len(fields) > 0 {
			buf.WriteString(strings.Join(fields, " "))
		}
	}

	// 调用位置（在同一行显示）
	if entry.Caller != "" {
		buf.WriteString(" ")
		buf.WriteString(fmt.Sprintf("caller=%s", entry.Caller))
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
