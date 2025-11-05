package logger

import (
	"context"
	"sync"
	"time"
)

// Logger 日志接口
type Logger interface {
	// 基础日志方法
	Debug(msg string, fields ...Field)
	Info(msg string, fields ...Field)
	Warn(msg string, fields ...Field)
	Error(msg string, fields ...Field)
	Fatal(msg string, fields ...Field)

	// 上下文和字段增强
	WithContext(ctx context.Context) Logger
	WithFields(fields ...Field) Logger

	// 获取模块名
	Module() string
}

// logger Logger实现
type logger struct {
	module string       // 模块名，如 "service.media"
	fields []Field      // 默认字段（如模块名）
	mu     sync.RWMutex // 保护 fields
}

// New 创建新的Logger实例
func New(module string) Logger {
	return &logger{
		module: module,
		fields: []Field{
			Field{Key: "module", Value: module},
		},
	}
}

// Module 获取模块名
func (l *logger) Module() string {
	return l.module
}

// WithFields 添加字段
func (l *logger) WithFields(fields ...Field) Logger {
	l.mu.RLock()
	defer l.mu.RUnlock()

	newFields := make([]Field, len(l.fields))
	copy(newFields, l.fields)
	newFields = append(newFields, fields...)

	return &logger{
		module: l.module,
		fields: newFields,
	}
}

// WithContext 添加上下文信息
func (l *logger) WithContext(ctx context.Context) Logger {
	fields := []Field{}

	// 提取 request_id（支持ContextKey和字符串key）
	if requestID := ctx.Value(RequestIDKey); requestID != nil {
		if id, ok := requestID.(string); ok {
			fields = append(fields, RequestID(id))
		}
	} else if requestID := ctx.Value("request_id"); requestID != nil {
		if id, ok := requestID.(string); ok {
			fields = append(fields, RequestID(id))
		}
	}

	// 提取 user_id（支持ContextKey和字符串key）
	if userID := ctx.Value(UserIDKey); userID != nil {
		if id, ok := userID.(uint); ok {
			fields = append(fields, UserID(id))
		}
	} else if userID := ctx.Value("user_id"); userID != nil {
		if id, ok := userID.(uint); ok {
			fields = append(fields, UserID(id))
		}
	}

	if len(fields) > 0 {
		return l.WithFields(fields...)
	}

	return l
}

// log 记录日志的通用方法
func (l *logger) log(level Level, msg string, fields ...Field) {
	// 获取全局配置
	gc := getGlobalConfig()
	if gc == nil {
		return // 未初始化，不记录日志
	}

	// 检查日志级别
	if !level.enabled(gc.level) {
		return
	}

	// 合并字段
	l.mu.RLock()
	allFields := make([]Field, len(l.fields))
	copy(allFields, l.fields)
	allFields = append(allFields, fields...)
	l.mu.RUnlock()

	// 构建字段映射
	fieldMap := make(map[string]interface{})
	for _, field := range allFields {
		fieldMap[field.Key] = field.Value
	}

	// 创建日志条目
	entry := &LogEntry{
		Time:    time.Now(),
		Level:   level.String(),
		Module:  l.module,
		Message: msg,
		Fields:  fieldMap,
	}

	// 添加调用位置
	if gc.config != nil && gc.config.EnableCaller {
		entry.Caller = getCaller(3) // skip: log() -> Debug/Info/etc -> log()
	}

	// 添加堆栈信息（Error 和 Fatal 级别）
	if (level == LevelError || level == LevelFatal) && gc.config != nil && gc.config.EnableStack {
		entry.Stack = getStack()
	}

	// 写入日志
	if gc.config != nil && gc.config.Async {
		gc.sharedWriter.WriteAsync(entry)
	} else {
		gc.sharedWriter.Write(entry)
	}

	// Fatal 级别直接退出
	if level == LevelFatal {
		Sync()     // 确保日志写入完成
		panic(msg) // 使用 panic 触发退出
	}
}

// Debug 记录调试级别日志
func (l *logger) Debug(msg string, fields ...Field) {
	l.log(LevelDebug, msg, fields...)
}

// Info 记录信息级别日志
func (l *logger) Info(msg string, fields ...Field) {
	l.log(LevelInfo, msg, fields...)
}

// Warn 记录警告级别日志
func (l *logger) Warn(msg string, fields ...Field) {
	l.log(LevelWarn, msg, fields...)
}

// Error 记录错误级别日志
func (l *logger) Error(msg string, fields ...Field) {
	l.log(LevelError, msg, fields...)
}

// Fatal 记录致命错误级别日志并退出
func (l *logger) Fatal(msg string, fields ...Field) {
	l.log(LevelFatal, msg, fields...)
}
