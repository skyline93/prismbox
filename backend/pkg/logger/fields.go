package logger

import (
	"time"
)

// Field 日志字段类型
type Field struct {
	Key   string
	Value interface{}
}

// String 创建字符串字段
func String(key, value string) Field {
	return Field{Key: key, Value: value}
}

// Int 创建整数字段
func Int(key string, value int) Field {
	return Field{Key: key, Value: value}
}

// Int64 创建64位整数字段
func Int64(key string, value int64) Field {
	return Field{Key: key, Value: value}
}

// Uint 创建无符号整数字段
func Uint(key string, value uint) Field {
	return Field{Key: key, Value: value}
}

// Float64 创建浮点数字段
func Float64(key string, value float64) Field {
	return Field{Key: key, Value: value}
}

// Bool 创建布尔字段
func Bool(key string, value bool) Field {
	return Field{Key: key, Value: value}
}

// Error 创建错误字段
func Error(err error) Field {
	if err == nil {
		return Field{Key: "error", Value: nil}
	}
	return Field{Key: "error", Value: err.Error()}
}

// UserID 创建用户ID字段
func UserID(id uint) Field {
	return Field{Key: "user_id", Value: id}
}

// RequestID 创建请求ID字段
func RequestID(id string) Field {
	return Field{Key: "request_id", Value: id}
}

// Duration 创建时长字段
func Duration(key string, d time.Duration) Field {
	return Field{Key: key, Value: d.String()}
}

// Time 创建时间字段
func Time(key string, t time.Time) Field {
	return Field{Key: key, Value: t.Format(time.RFC3339)}
}
