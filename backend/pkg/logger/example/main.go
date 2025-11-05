package main

import (
	"context"
	"errors"
	"time"

	"github.com/album/backend/pkg/logger"
)

func main() {
	// 示例1: 基础配置 - 控制台输出
	demonstrateConsoleLogger()

	// 示例2: JSON格式输出
	demonstrateJSONLogger()

	// 示例3: 文件输出（带轮转）
	demonstrateFileLogger()

	// 示例4: 异步写入
	demonstrateAsyncLogger()

	// 示例5: 不同日志级别
	demonstrateLogLevels()

	// 示例6: 带上下文的日志
	demonstrateContextLogger()

	// 示例7: 错误日志（带堆栈）
	demonstrateErrorLogger()

	// 示例8: 多模块日志
	demonstrateMultiModuleLogger()

	// 等待异步写入完成
	time.Sleep(500 * time.Millisecond)
	logger.Sync()
}

// demonstrateConsoleLogger 演示控制台日志
func demonstrateConsoleLogger() {
	println("\n=== 示例1: 控制台日志（Console格式）===")

	config := &logger.Config{
		Level:        "debug",
		Format:       "console",
		Output:       "stdout",
		EnableCaller: true,
		EnableStack:  true,
		Async:        false,
	}

	// 使用Init或UpdateConfig（如果已经初始化过，使用UpdateConfig）
	if err := logger.Init(config); err != nil {
		if err := logger.UpdateConfig(config); err != nil {
			panic(err)
		}
	}
	// 如果Init成功，说明是第一次初始化；如果失败，说明已经初始化过，使用UpdateConfig

	log := logger.New("example.console")
	log.Info("这是一条控制台格式的日志",
		logger.String("user", "张三"),
		logger.Int("age", 25),
		logger.Bool("active", true),
	)
}

// demonstrateJSONLogger 演示JSON格式日志
func demonstrateJSONLogger() {
	println("\n=== 示例2: JSON格式日志 ===")

	config := &logger.Config{
		Level:        "info",
		Format:       "json",
		Output:       "stdout",
		EnableCaller: true,
		EnableStack:  true,
		Async:        false,
	}

	if err := logger.UpdateConfig(config); err != nil {
		panic(err)
	}

	log := logger.New("example.json")
	log.Info("这是一条JSON格式的日志",
		logger.String("operation", "create_user"),
		logger.Uint("user_id", 123),
		logger.Int64("file_size", 1024*1024),
		logger.Duration("duration", 150*time.Millisecond),
	)
}

// demonstrateFileLogger 演示文件日志（带轮转）
func demonstrateFileLogger() {
	println("\n=== 示例3: 文件日志（带轮转）===")

	config := &logger.Config{
		Level:        "info",
		Format:       "json",
		Output:       "/tmp/album_example.log", // 使用文件路径
		EnableCaller: true,
		EnableStack:  true,
		Async:        false,
		FileConfig: &logger.FileConfig{
			Path:       "/tmp/album_example.log",
			MaxSize:    1024 * 1024, // 1MB
			MaxAge:     7,           // 保留7天
			MaxBackups: 5,           // 保留5个文件
			Compress:   false,
		},
	}

	if err := logger.UpdateConfig(config); err != nil {
		panic(err)
	}

	log := logger.New("example.file")
	for i := 0; i < 10; i++ {
		log.Info("写入文件日志",
			logger.Int("iteration", i),
			logger.Time("timestamp", time.Now()),
		)
	}
	println("文件日志已写入到 /tmp/album_example.log")
}

// demonstrateAsyncLogger 演示异步写入
func demonstrateAsyncLogger() {
	println("\n=== 示例4: 异步写入 ===")

	config := &logger.Config{
		Level:        "info",
		Format:       "json",
		Output:       "stdout",
		EnableCaller: false,
		EnableStack:  false,
		Async:        true,
		BufferSize:   1000,
	}

	if err := logger.UpdateConfig(config); err != nil {
		panic(err)
	}

	log := logger.New("example.async")
	println("开始并发写入日志...")
	for i := 0; i < 20; i++ {
		go func(id int) {
			log.Info("异步日志写入",
				logger.Int("goroutine_id", id),
				logger.String("message", "并发写入测试"),
			)
		}(i)
	}
	println("已启动20个goroutine并发写入日志")
}

// demonstrateLogLevels 演示不同日志级别
func demonstrateLogLevels() {
	println("\n=== 示例5: 不同日志级别 ===")

	config := &logger.Config{
		Level:        "debug",
		Format:       "console",
		Output:       "stdout",
		EnableCaller: true,
		EnableStack:  false,
		Async:        false,
	}

	if err := logger.UpdateConfig(config); err != nil {
		panic(err)
	}

	log := logger.New("example.levels")
	log.Debug("调试信息：详细的调试信息")
	log.Info("普通信息：操作成功完成")
	log.Warn("警告信息：需要注意的问题",
		logger.String("warning_type", "deprecated"),
	)
	log.Error("错误信息：发生了错误",
		logger.String("error_type", "validation"),
	)

	// 注意：Fatal会panic，这里注释掉
	// log.Fatal("致命错误：程序无法继续运行")
}

// demonstrateContextLogger 演示带上下文的日志
func demonstrateContextLogger() {
	println("\n=== 示例6: 带上下文的日志 ===")

	config := &logger.Config{
		Level:        "info",
		Format:       "json",
		Output:       "stdout",
		EnableCaller: true,
		EnableStack:  false,
		Async:        false,
	}

	if err := logger.UpdateConfig(config); err != nil {
		panic(err)
	}

	// 创建带上下文的logger（使用logger包导出的context key）
	ctx := context.WithValue(context.Background(), logger.RequestIDKey, "req-12345")
	ctx = context.WithValue(ctx, logger.UserIDKey, uint(67890))

	log := logger.New("example.context").WithContext(ctx)
	log.Info("处理用户请求",
		logger.String("action", "upload_media"),
		logger.String("media_type", "image"),
	)

	// 使用WithFields添加更多字段
	logWithFields := log.WithFields(
		logger.String("environment", "production"),
		logger.String("service", "media-service"),
	)
	logWithFields.Info("带额外字段的日志")
}

// demonstrateErrorLogger 演示错误日志（带堆栈）
func demonstrateErrorLogger() {
	println("\n=== 示例7: 错误日志（带堆栈信息）===")

	config := &logger.Config{
		Level:        "error",
		Format:       "console",
		Output:       "stdout",
		EnableCaller: true,
		EnableStack:  true, // 启用堆栈信息
		Async:        false,
	}

	if err := logger.UpdateConfig(config); err != nil {
		panic(err)
	}

	log := logger.New("example.error")

	// 模拟一个错误
	err := errors.New("数据库连接失败")
	log.Error("处理请求时发生错误",
		logger.Error(err),
		logger.String("operation", "save_user"),
		logger.Uint("user_id", 123),
	)
}

// demonstrateMultiModuleLogger 演示多模块日志
func demonstrateMultiModuleLogger() {
	println("\n=== 示例8: 多模块日志 ===")

	config := &logger.Config{
		Level:        "info",
		Format:       "json",
		Output:       "stdout",
		EnableCaller: true,
		EnableStack:  false,
		Async:        false,
	}

	if err := logger.UpdateConfig(config); err != nil {
		panic(err)
	}

	// 创建不同模块的logger
	mediaLogger := logger.New("service.media")
	backupLogger := logger.New("service.backup")
	storageLogger := logger.New("service.storage")

	// 各模块记录日志
	mediaLogger.Info("媒体上传成功",
		logger.String("media_uuid", "abc-123"),
		logger.Int64("file_size", 1024*1024*5),
	)

	backupLogger.Info("备份任务开始",
		logger.String("backup_id", "backup-001"),
		logger.String("target", "s3://bucket/backup"),
	)

	storageLogger.Warn("存储空间不足",
		logger.Float64("usage_percent", 85.5),
		logger.String("pool_id", "pool-1"),
	)
}
