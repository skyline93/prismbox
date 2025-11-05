package logger

import (
	"encoding/json"
	"time"
)

// JSONFormatter JSON格式化器
type JSONFormatter struct{}

// Format 格式化日志条目为JSON格式
func (f *JSONFormatter) Format(entry *LogEntry) ([]byte, error) {
	// 构建输出结构
	output := make(map[string]interface{})
	output["time"] = entry.Time.Format(time.RFC3339Nano)
	output["level"] = entry.Level
	output["module"] = entry.Module
	output["msg"] = entry.Message

	// 添加字段
	if len(entry.Fields) > 0 {
		for k, v := range entry.Fields {
			output[k] = v
		}
	}

	// 添加调用位置
	if entry.Caller != "" {
		output["caller"] = entry.Caller
	}

	// 添加堆栈信息
	if entry.Stack != "" {
		output["stack"] = entry.Stack
	}

	data, err := json.Marshal(output)
	if err != nil {
		return nil, err
	}
	// 添加换行符，便于每行一条日志
	return append(data, '\n'), nil
}
