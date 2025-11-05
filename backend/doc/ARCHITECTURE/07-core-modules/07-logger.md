# 7.7 日志模块架构设计

## 7.7.1 概述

日志模块是 Album Backend 的核心基础设施模块，提供结构化日志记录能力。该模块采用全局配置统一管理和共享写入器的设计，确保所有模块的日志输出统一、并发安全、易于运维。

## 7.7.2 设计原则

### 核心设计理念

1. **全局配置统一管理**：所有模块共享同一配置和写入器，确保日志输出一致
2. **并发安全**：多 goroutine 环境下安全写入，无竞争条件
3. **结构化日志**：支持 JSON 格式，便于解析、查询和监控集成
4. **模块化设计**：各模块创建独立 logger 实例，通过字段区分来源
5. **性能优化**：支持异步写入、级别过滤，降低对业务性能影响
6. **运维友好**：支持文件轮转、容器化部署、与监控系统集成

## 7.7.3 架构设计

### 目录结构

```
pkg/logger/
├── core.go           # 全局配置管理（单例）
├── logger.go         # Logger 接口和实现
├── config.go         # 配置结构定义
├── fields.go         # 字段构建器
├── formatter.go      # 格式化器接口
├── formatter_json.go # JSON 格式化器
├── formatter_console.go # 控制台格式化器
├── writer.go         # 写入器接口
├── writer_shared.go  # 共享写入器实现（线程安全）
├── writer_file.go    # 文件写入器实现（带轮转）
├── writer_console.go # 控制台写入器实现
├── level.go          # 日志级别定义
└── middleware.go     # Gin 中间件
```

### 核心组件关系

```
┌─────────────────────────────────────────┐
│        全局配置中心 (globalConfig)        │
│  ┌───────────────────────────────────┐  │
│  │ 配置: Level, Format, Output, ...  │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │   共享写入器 (sharedWriter)        │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  Mutex 锁保护               │  │  │
│  │  │  + 异步缓冲通道              │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │   格式化器 (formatter)             │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘
                    ↑
                    │ 共享
    ┌───────────────┼───────────────┐
    │               │               │
┌─────────┐   ┌─────────┐   ┌─────────┐
│Logger   │   │Logger   │   │Logger   │
│(media)  │   │(backup) │   │(storage)│
└─────────┘   └─────────┘   └─────────┘
    │               │               │
    └───────────────┴───────────────┘
                    ↓
           统一输出到同一目标
```

## 7.7.4 核心接口设计

### Logger 接口

```go
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
```

### Logger 实现

```go
type Logger struct {
    module  string        // 模块名，如 "service.media"
    fields  []Field       // 默认字段（如模块名）
    mu      sync.RWMutex  // 保护 fields
}
```

### Field 字段类型

```go
type Field struct {
    Key   string
    Value interface{}
}

// 便捷构造函数
func String(key, value string) Field
func Int(key string, value int) Field
func Int64(key string, value int64) Field
func Uint(key string, value uint) Field
func Float64(key string, value float64) Field
func Bool(key string, value bool) Field
func Error(err error) Field
func UserID(id uint) Field
func RequestID(id string) Field
func Duration(key string, d time.Duration) Field
func Time(key string, t time.Time) Field
```

## 7.7.5 配置管理

### 配置结构

```go
type Config struct {
    // 基础配置
    Level        string  // "debug", "info", "warn", "error"
    Format       string  // "json", "console"
    Output       string  // "stdout", "stderr", "/path/to/file.log"
    
    // 功能开关
    EnableCaller bool    // 是否包含调用位置（文件名:行号）
    EnableStack  bool    // 是否包含堆栈信息（Error 级别）
    
    // 性能配置
    Async      bool      // 是否异步写入
    BufferSize int       // 异步缓冲大小（默认 1000）
    
    // 文件输出配置（Output 为文件路径时生效）
    FileConfig *FileConfig
}

type FileConfig struct {
    Path       string    // 日志文件路径
    MaxSize    int64     // 单个文件最大大小（字节）
    MaxAge     int       // 保留天数
    MaxBackups int       // 保留文件数量
    Compress   bool      // 是否压缩旧文件
}
```

### 全局配置管理器（单例）

```go
type globalConfig struct {
    mu          sync.RWMutex       // 保护配置和写入器
    config      *Config            // 当前配置
    sharedWriter *sharedWriter     // 共享写入器（所有模块共用）
    level       Level              // 当前日志级别（缓存）
    formatter   Formatter          // 格式化器实例
}

var (
    global     *globalConfig
    globalOnce sync.Once
)

// Init 初始化全局配置（应用启动时调用一次）
func Init(config *Config) error {
    globalOnce.Do(func() {
        global = &globalConfig{
            config: config,
            level:  parseLevel(config.Level),
        }
        
        // 创建共享写入器
        writer, err := NewSharedWriter(config)
        if err != nil {
            panic(err)
        }
        global.sharedWriter = writer
        
        // 创建格式化器
        global.formatter = createFormatter(config.Format)
    })
    
    return nil
}
```

### 配置传递机制

**关键设计**：
- 应用启动时调用 `logger.Init(config)` 初始化全局配置
- 创建 `globalConfig` 单例，包含共享写入器和格式化器
- 所有模块通过 `logger.New("module.name")` 创建 Logger 实例
- 每个 Logger 实例通过 `getGlobalConfig()` 访问全局配置和共享写入器
- 所有日志输出到统一的目标（文件/stdout），通过 `module` 字段区分来源

## 7.7.6 并发安全机制

### 三层并发安全设计

#### 第一层：全局配置访问保护
```go
// 读取配置时使用读锁（多个模块可并发读取）
func getGlobalConfig() *globalConfig {
    global.mu.RLock()
    defer global.mu.RUnlock()
    // ...
}

// 更新配置时使用写锁（互斥）
func UpdateConfig(config *Config) error {
    global.mu.Lock()
    defer global.mu.Unlock()
    // ...
}
```

#### 第二层：共享写入器保护
```go
type sharedWriter struct {
    mu       sync.Mutex          // 保护底层写入操作
    writer   io.Writer            // 底层写入器
    buffer   chan *LogEntry       // 异步缓冲通道
    wg       sync.WaitGroup       // 等待异步写入完成
    closed   atomic.Bool          // 原子操作的关闭标志
}

// 同步写入（线程安全）
func (sw *sharedWriter) Write(entry *LogEntry) error {
    sw.mu.Lock()
    defer sw.mu.Unlock()
    
    data, _ := formatEntry(entry)
    _, err := sw.writer.Write(data)
    return err
}

// 异步写入（通过缓冲通道，避免阻塞）
func (sw *sharedWriter) WriteAsync(entry *LogEntry) error {
    select {
    case sw.buffer <- entry:
        return nil
    default:
        // 缓冲区满，降级为同步写入
        return sw.Write(entry)
    }
}
```

#### 第三层：Logger 字段保护
```go
// Logger 的字段追加操作保护
func (l *Logger) WithFields(fields ...Field) Logger {
    l.mu.Lock()
    defer l.mu.Unlock()
    
    newFields := append(l.fields, fields...)
    return &Logger{
        module: l.module,
        fields: newFields,
    }
}
```

### 并发场景示例

```
Goroutine 1: mediaLogger.Info(...)
    ↓
检查日志级别（读锁，可并发）
    ↓
写入共享写入器（写入器内部 mutex 排队）
    ↓
文件句柄写入（单一线程，线程安全）

Goroutine 2: backupLogger.Info(...)
    ↓
检查日志级别（读锁，可并发）
    ↓
写入共享写入器（mutex 排队）
    ↓
文件句柄写入（单一线程，线程安全）

结果：所有日志有序写入同一文件，无竞争条件
```

## 7.7.7 写入器实现

### 共享写入器（核心）

**功能**：
- 统一写入接口，支持 stdout、stderr、文件
- 线程安全，支持同步/异步写入
- 所有模块共享同一实例

**异步写入机制**：
- 使用缓冲通道接收日志条目
- 后台协程批量刷新（每 100ms 或达到批量大小）
- 缓冲区满时降级为同步写入，保证不丢失日志

### 文件写入器（带轮转）

**功能**：
- 自动文件轮转（按大小或时间）
- 保留策略（按数量或天数）
- 可选压缩旧文件，节省空间

**轮转逻辑**：
1. 写入前检查文件大小是否超过阈值
2. 超过阈值时：
   - 关闭当前文件
   - 重命名为带时间戳的文件（如 `app.log.20250120-100000`）
   - 创建新文件
   - 清理旧文件（根据保留策略）

## 7.7.8 格式化器

### JSON 格式化器（生产环境）

**输出格式**：
```json
{
  "time": "2025-01-20T10:00:00.123Z",
  "level": "info",
  "module": "service.media",
  "msg": "Uploading media",
  "user_id": 123,
  "media_uuid": "abc-123",
  "file_size": 1024,
  "caller": "service.go:45"
}
```

**优势**：
- 结构化数据，便于解析和查询
- 与 ELK、Loki 等日志系统集成
- 支持字段过滤和聚合

### 控制台格式化器（开发环境）

**输出格式**：
```
2025-01-20 10:00:00 [INFO] service.media Uploading media
  user_id=123 media_uuid=abc-123 file_size=1024
  caller=service.go:45
```

**优势**：
- 人类可读格式
- 彩色输出（支持）
- 适合开发调试

## 7.7.9 使用方式

### 应用启动初始化

```go
// server/main.go
func main() {
    cfg, _ := core.LoadConfig()
    
    // 初始化日志系统
    loggerConfig := &logger.Config{
        Level:        cfg.Logger.Level,      // "info"
        Format:       cfg.Logger.Format,     // "json"
        Output:       cfg.Logger.Output,     // "/var/log/album/app.log"
        EnableCaller: true,
        EnableStack:  true,
        Async:        true,
        BufferSize:   1000,
        FileConfig: &logger.FileConfig{
            Path:       "/var/log/album/app.log",
            MaxSize:    100 * 1024 * 1024,  // 100MB
            MaxBackups: 10,
            MaxAge:     30,
            Compress:   true,
        },
    }
    
    if err := logger.Init(loggerConfig); err != nil {
        log.Fatalf("Failed to init logger: %v", err)
    }
    defer logger.Sync()  // 确保所有日志写入完成
    
    // 后续所有模块都使用这个全局配置
}
```

### 模块中创建 Logger

```go
// internal/service/media/service.go
type service struct {
    logger logger.Logger
}

func NewService(...) Service {
    return &service{
        logger: logger.New("service.media"),  // 模块名自动加入字段
    }
}
```

### 日志记录示例

```go
// 基础使用
s.logger.Info("Media uploaded",
    logger.String("media_uuid", uuid),
    logger.Uint("user_id", userID),
    logger.Int64("file_size", size),
)

// 带上下文（自动提取 request_id, user_id）
s.logger.WithContext(ctx).Info("Processing request")

// 错误日志（自动包含堆栈）
s.logger.Error("Failed to upload",
    logger.Error(err),
    logger.String("filename", filename),
)

// 追加字段
mediaLogger := s.logger.WithFields(
    logger.String("operation", "upload"),
    logger.String("environment", "production"),
)
mediaLogger.Info("Operation started")
```

### Gin 中间件集成

```go
// api/router.go
func SetupRouter(...) *gin.Engine {
    r := gin.Default()
    
    // 添加日志中间件（自动记录请求日志，注入 request_id）
    r.Use(logger.GinMiddleware())
    
    // 后续所有请求都会自动记录日志
}
```

## 7.7.10 性能优化

### 级别过滤

- 低级别日志在写入前就被过滤，避免不必要的序列化和 I/O 操作
- 生产环境通常设置为 `info`，只输出重要信息

### 异步写入

- 使用缓冲通道接收日志条目
- 后台协程批量刷新，减少 I/O 次数
- 缓冲区满时降级为同步写入，保证不丢失

### 批量刷新

- 每 100ms 或达到批量大小（100 条）时批量写入
- 减少系统调用次数，提高性能

## 7.7.11 运维集成

### 容器化部署

- 输出到 `stdout`，便于容器日志收集
- Docker/Kubernetes 自动收集和聚合日志
- 与 Fluentd、Filebeat 等日志收集器集成

### 监控系统集成

- JSON 格式便于解析和查询
- 与 ELK Stack、Loki、Datadog 等系统集成
- 支持日志告警和仪表盘

### 日志分析

- 通过 `module` 字段过滤特定模块的日志
- 通过 `user_id`、`request_id` 等字段追踪用户行为
- 通过 `level` 字段统计错误率

## 7.7.12 配置示例

```yaml
# configs/config.yaml
logger:
  level: "info"              # debug, info, warn, error
  format: "json"             # json, console
  output: "/var/log/album/app.log"  # stdout, stderr, 或文件路径
  enable_caller: true        # 包含调用位置
  enable_stack: true         # 包含堆栈信息
  async: true                # 异步写入
  buffer_size: 1000          # 缓冲大小
  
  # 文件配置（output 为文件时生效）
  file:
    max_size: 104857600      # 100MB
    max_backups: 10          # 保留10个文件
    max_age: 30              # 保留30天
    compress: true           # 压缩旧文件
```

## 7.7.13 关键设计要点总结

### 全局配置统一管理

- ✅ **单例模式**：全局配置存储在单例中，所有模块共享
- ✅ **共享写入器**：所有模块使用同一个写入器实例，统一输出
- ✅ **配置一致性**：日志级别、输出路径、格式等配置全局统一

### 并发安全保证

- ✅ **三层锁机制**：配置读锁、写入器互斥锁、Logger 字段保护
- ✅ **异步写入**：缓冲通道 + 批量刷新，降低阻塞
- ✅ **原子操作**：关闭标志等使用原子操作

### 文件管理

- ✅ **统一文件路径**：所有模块写入同一文件（如果配置了文件输出）
- ✅ **自动轮转**：按大小自动轮转，避免单文件过大
- ✅ **保留策略**：按数量或天数清理旧文件
- ✅ **压缩支持**：可选压缩旧文件，节省空间

### 性能优化

- ✅ **级别过滤**：低级别日志直接返回，避免不必要的处理
- ✅ **异步写入**：批量刷新，降低 I/O 阻塞
- ✅ **缓冲机制**：缓冲通道，高并发下平滑处理

### 运维友好

- ✅ **结构化 JSON**：便于解析和查询
- ✅ **容器化支持**：输出到 stdout，便于收集
- ✅ **模块标识**：通过 `module` 字段区分来源
- ✅ **上下文追踪**：支持 `request_id` 链路追踪

## 7.7.14 相关文档

- [配置管理](../10-configuration.md) - 日志配置结构
- [监控和运维](../15-monitoring.md) - 日志监控和集成
- [依赖注入](../04-dependency-injection.md) - Logger 的依赖注入方式
