# Logger 日志模块

一个高性能、结构化、并发安全的 Go 日志库，专为 Album Backend 设计。

## 目录

- [概述](#概述)
- [功能特性](#功能特性)
- [快速开始](#快速开始)
- [配置说明](#配置说明)
- [使用指南](#使用指南)
- [API 文档](#api-文档)
- [最佳实践](#最佳实践)
- [性能优化](#性能优化)
- [运维集成](#运维集成)

## 概述

Logger 模块是 Album Backend 的核心基础设施模块，提供统一的结构化日志记录能力。该模块采用全局配置统一管理和共享写入器的设计，确保所有模块的日志输出一致、并发安全、易于运维。

### 核心设计理念

- **全局配置统一管理**：所有模块共享同一配置和写入器，确保日志输出一致
- **并发安全**：多 goroutine 环境下安全写入，无竞争条件
- **结构化日志**：支持 JSON 格式，便于解析、查询和监控集成
- **模块化设计**：各模块创建独立 logger 实例，通过字段区分来源
- **性能优化**：支持异步写入、级别过滤，降低对业务性能影响
- **运维友好**：支持文件轮转、容器化部署、与监控系统集成

## 功能特性

### ✨ 核心功能

- ✅ **多日志级别**：支持 Debug、Info、Warn、Error、Fatal 五个级别
- ✅ **结构化日志**：支持 JSON 和控制台两种格式
- ✅ **多输出目标**：支持 stdout、stderr、文件输出
- ✅ **文件轮转**：自动按大小轮转，支持保留策略和压缩
- ✅ **异步写入**：支持异步写入，批量刷新，提高性能
- ✅ **调用位置**：可选记录调用位置（文件名:行号）
- ✅ **堆栈信息**：错误级别自动记录堆栈信息
- ✅ **Context 集成**：自动提取 request_id 和 user_id
- ✅ **Gin 中间件**：自动记录 HTTP 请求日志
- ✅ **并发安全**：线程安全设计，支持高并发场景

### 🎯 适用场景

- 微服务架构的日志记录
- 容器化部署（输出到 stdout）
- 生产环境监控集成（JSON 格式）
- 开发环境调试（Console 格式）
- 高并发场景（异步写入）

## 快速开始

### 安装

```bash
go get github.com/album/backend/pkg/logger
```

### 基础使用

```go
package main

import (
    "github.com/album/backend/pkg/logger"
)

func main() {
    // 1. 初始化日志系统
    config := &logger.Config{
        Level:  "info",
        Format: "json",
        Output: "stdout",
    }
    
    if err := logger.Init(config); err != nil {
        panic(err)
    }
    defer logger.Sync()
    
    // 2. 创建 Logger 实例
    log := logger.New("my.module")
    
    // 3. 记录日志
    log.Info("Application started",
        logger.String("version", "1.0.0"),
        logger.Int("port", 8080),
    )
}
```

### 在 Gin 中使用

```go
import (
    "github.com/gin-gonic/gin"
    "github.com/album/backend/pkg/logger"
)

func main() {
    // 初始化日志
    logger.Init(&logger.Config{
        Level:  "info",
        Format: "json",
        Output: "stdout",
    })
    defer logger.Sync()
    
    // 创建 Gin 引擎
    r := gin.Default()
    
    // 添加日志中间件
    r.Use(logger.GinMiddleware())
    
    // 启动服务
    r.Run(":8080")
}
```

## 配置说明

### 配置结构

```go
type Config struct {
    // 基础配置
    Level  string // "debug", "info", "warn", "error"
    Format string // "json", "console"
    Output string // "stdout", "stderr", "/path/to/file.log"
    
    // 功能开关
    EnableCaller bool // 是否包含调用位置（文件名:行号）
    EnableStack  bool // 是否包含堆栈信息（Error 级别）
    
    // 性能配置
    Async      bool // 是否异步写入
    BufferSize int  // 异步缓冲大小（默认 1000）
    
    // 文件输出配置（Output 为文件路径时生效）
    FileConfig *FileConfig
}

type FileConfig struct {
    Path       string // 日志文件路径
    MaxSize    int64  // 单个文件最大大小（字节）
    MaxAge     int    // 保留天数
    MaxBackups int    // 保留文件数量
    Compress   bool   // 是否压缩旧文件
}
```

### 配置示例

#### 开发环境（控制台输出）

```go
config := &logger.Config{
    Level:        "debug",
    Format:       "console",
    Output:       "stdout",
    EnableCaller: true,
    EnableStack:  false,
    Async:        false,
}
```

#### 生产环境（JSON 格式，文件输出）

```go
config := &logger.Config{
    Level:        "info",
    Format:       "json",
    Output:       "/var/log/album/app.log",
    EnableCaller: true,
    EnableStack:  true,
    Async:        true,
    BufferSize:   1000,
    FileConfig: &logger.FileConfig{
        Path:       "/var/log/album/app.log",
        MaxSize:    100 * 1024 * 1024, // 100MB
        MaxAge:     30,                 // 保留30天
        MaxBackups: 10,                 // 保留10个文件
        Compress:   true,               // 压缩旧文件
    },
}
```

#### 容器化部署（stdout，JSON 格式）

```go
config := &logger.Config{
    Level:        "info",
    Format:       "json",
    Output:       "stdout",
    EnableCaller: true,
    EnableStack:  true,
    Async:        true,
    BufferSize:   1000,
}
```

### 配置参数说明

| 参数 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `Level` | string | 日志级别：debug, info, warn, error | info |
| `Format` | string | 日志格式：json, console | json |
| `Output` | string | 输出目标：stdout, stderr, 或文件路径 | stdout |
| `EnableCaller` | bool | 是否包含调用位置 | false |
| `EnableStack` | bool | 是否包含堆栈信息（Error级别） | false |
| `Async` | bool | 是否异步写入 | false |
| `BufferSize` | int | 异步缓冲大小 | 1000 |
| `FileConfig.Path` | string | 日志文件路径 | - |
| `FileConfig.MaxSize` | int64 | 单个文件最大大小（字节） | 0（不限制） |
| `FileConfig.MaxAge` | int | 保留天数 | 0（不限制） |
| `FileConfig.MaxBackups` | int | 保留文件数量 | 0（不限制） |
| `FileConfig.Compress` | bool | 是否压缩旧文件 | false |

## 使用指南

### 创建 Logger 实例

每个模块应该创建自己的 Logger 实例：

```go
// 创建 Logger
log := logger.New("service.media")
log := logger.New("service.album")
log := logger.New("service.backup")
```

### 基础日志记录

```go
log := logger.New("my.module")

// Debug 级别
log.Debug("调试信息",
    logger.String("key", "value"),
)

// Info 级别
log.Info("操作成功",
    logger.String("operation", "create_user"),
    logger.Uint("user_id", 123),
)

// Warn 级别
log.Warn("警告信息",
    logger.String("warning_type", "deprecated"),
)

// Error 级别
log.Error("操作失败",
    logger.Error(err),
    logger.String("operation", "save_data"),
)

// Fatal 级别（会触发 panic）
log.Fatal("致命错误，程序无法继续")
```

### 使用字段构建器

Logger 提供了丰富的字段构建器：

```go
// 字符串
logger.String("name", "value")

// 数字
logger.Int("count", 42)
logger.Int64("file_size", 1024*1024)
logger.Uint("user_id", 123)
logger.Float64("ratio", 0.95)

// 布尔值
logger.Bool("enabled", true)

// 错误
logger.Error(err)

// 时间
logger.Time("created_at", time.Now())
logger.Duration("latency", 150*time.Millisecond)

// 便捷字段
logger.UserID(123)
logger.RequestID("req-12345")
```

### 添加上下文信息

使用 `WithContext` 自动提取 context 中的 `request_id` 和 `user_id`：

```go
import (
    "context"
    "github.com/album/backend/pkg/logger"
)

// 在 context 中设置值
ctx := context.WithValue(context.Background(), logger.RequestIDKey, "req-12345")
ctx = context.WithValue(ctx, logger.UserIDKey, uint(123))

// 创建带上下文的 logger
log := logger.New("my.module").WithContext(ctx)
log.Info("处理请求") // 自动包含 request_id 和 user_id
```

### 添加固定字段

使用 `WithFields` 添加固定字段：

```go
// 创建带固定字段的 logger
log := logger.New("my.module").WithFields(
    logger.String("environment", "production"),
    logger.String("service", "media-service"),
)

// 后续所有日志都会包含这些字段
log.Info("操作开始")
log.Info("操作完成")
```

### 在 Gin 中使用中间件

```go
import (
    "github.com/gin-gonic/gin"
    "github.com/album/backend/pkg/logger"
)

func SetupRouter() *gin.Engine {
    r := gin.Default()
    
    // 添加日志中间件（自动记录请求日志）
    r.Use(logger.GinMiddleware())
    
    // 后续所有请求都会自动记录日志
    r.GET("/api/users", getUserHandler)
    
    return r
}
```

中间件会自动：
- 生成 `request_id` 并添加到响应头 `X-Request-ID`
- 记录请求开始和结束
- 根据状态码选择日志级别（500+ 为 Error，400+ 为 Warn，其他为 Info）
- 记录请求方法、路径、状态码、延迟等信息

### 更新配置

如果需要运行时更新配置：

```go
newConfig := &logger.Config{
    Level:  "warn", // 提高日志级别
    Format: "json",
    Output: "stdout",
}

if err := logger.UpdateConfig(newConfig); err != nil {
    log.Error("更新日志配置失败", logger.Error(err))
}
```

## API 文档

### 核心函数

#### `Init(config *Config) error`

初始化全局日志配置。应用启动时调用一次。

```go
if err := logger.Init(&logger.Config{
    Level:  "info",
    Format: "json",
    Output: "stdout",
}); err != nil {
    panic(err)
}
```

#### `New(module string) Logger`

创建新的 Logger 实例。

```go
log := logger.New("service.media")
```

#### `Sync() error`

同步所有日志写入。应用关闭时调用，确保所有日志写入完成。

```go
defer logger.Sync()
```

#### `UpdateConfig(config *Config) error`

更新全局日志配置。

```go
if err := logger.UpdateConfig(newConfig); err != nil {
    return err
}
```

#### `GinMiddleware() gin.HandlerFunc`

返回 Gin 中间件，自动记录 HTTP 请求日志。

```go
r.Use(logger.GinMiddleware())
```

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

### Context Key

```go
const (
    RequestIDKey ContextKey = "request_id"
    UserIDKey    ContextKey = "user_id"
)
```

使用示例：

```go
ctx := context.WithValue(ctx, logger.RequestIDKey, "req-12345")
ctx = context.WithValue(ctx, logger.UserIDKey, uint(123))
```

## 最佳实践

### 1. 模块命名规范

使用分层命名，便于过滤和查找：

```go
// 服务层
logger.New("service.media")
logger.New("service.album")
logger.New("service.backup")

// 仓储层
logger.New("repository.user")
logger.New("repository.media")

// 处理器层
logger.New("handler.auth")
logger.New("handler.media")
```

### 2. 日志级别选择

- **Debug**：详细的调试信息，开发环境使用
- **Info**：重要的业务操作，如用户注册、数据创建
- **Warn**：需要注意的问题，如配置过期、性能警告
- **Error**：错误信息，需要处理的问题
- **Fatal**：致命错误，程序无法继续运行

```go
// ✅ 正确
log.Info("用户注册成功", logger.Uint("user_id", userID))
log.Error("数据库连接失败", logger.Error(err))

// ❌ 错误
log.Debug("用户注册成功") // 应该用 Info
log.Info("致命错误")      // 应该用 Fatal
```

### 3. 字段命名规范

使用一致的字段命名：

```go
// ✅ 推荐
logger.Uint("user_id", userID)
logger.String("media_uuid", uuid)
logger.Int64("file_size", size)
logger.Duration("latency", duration)

// ❌ 不推荐
logger.Uint("userId", userID)  // 使用下划线
logger.String("mediaUuid", uuid) // 使用下划线
```

### 4. 错误处理

始终记录错误信息：

```go
if err != nil {
    log.Error("操作失败",
        logger.Error(err),
        logger.String("operation", "save_data"),
        logger.Uint("user_id", userID),
    )
    return err
}
```

### 5. 性能敏感场景

在高性能场景下，使用异步写入：

```go
config := &logger.Config{
    Async:      true,
    BufferSize: 1000,
}
```

### 6. 生产环境配置

生产环境推荐配置：

```go
config := &logger.Config{
    Level:        "info",              // 生产环境使用 info
    Format:       "json",              // 使用 JSON 格式
    Output:       "/var/log/app.log",  // 文件输出
    EnableCaller: true,                // 记录调用位置
    EnableStack:  true,                // 记录堆栈信息
    Async:        true,                // 异步写入
    BufferSize:   1000,                // 缓冲大小
    FileConfig: &logger.FileConfig{
        MaxSize:    100 * 1024 * 1024, // 100MB
        MaxAge:     30,                 // 保留30天
        MaxBackups: 10,                 // 保留10个文件
        Compress:   true,               // 压缩旧文件
    },
}
```

### 7. 容器化部署

容器化部署时，输出到 stdout：

```go
config := &logger.Config{
    Level:        "info",
    Format:       "json",  // JSON 格式便于日志收集系统解析
    Output:       "stdout",
    EnableCaller: true,
    EnableStack:  true,
    Async:        true,
}
```

Docker/Kubernetes 会自动收集 stdout 日志。

## 性能优化

### 异步写入

异步写入可以显著提高性能，特别是在高并发场景下：

```go
config := &logger.Config{
    Async:      true,
    BufferSize: 1000, // 缓冲大小，根据实际情况调整
}
```

### 日志级别过滤

低级别日志在写入前就被过滤，避免不必要的序列化和 I/O 操作：

```go
// 生产环境使用 info 级别，debug 日志会被直接过滤
config := &logger.Config{
    Level: "info",
}
```

### 批量刷新

异步写入器会批量刷新日志，减少系统调用次数：

- 每 100ms 自动刷新一次
- 或达到批量大小（100 条）时刷新
- 缓冲区满时降级为同步写入

## 运维集成

### 日志格式

#### JSON 格式（生产环境）

```json
{
  "time": "2025-01-20T10:00:00.123Z",
  "level": "info",
  "module": "service.media",
  "msg": "上传媒体成功",
  "user_id": 123,
  "media_uuid": "abc-123",
  "file_size": 1048576,
  "caller": "service.go:45"
}
```

#### Console 格式（开发环境）

```
2025-01-20 10:00:00.123 [INFO] service.media 上传媒体成功 user_id=123 media_uuid=abc-123 file_size=1048576 caller=service.go:45
```

**注意**：
- 所有字段都在同一行显示，使用空格分隔
- `module` 字段不会出现在字段列表中，因为模块名已经在消息前面显示了
- 堆栈信息（Error 级别）仍然会换行显示，便于阅读

### 日志收集

#### Docker/Kubernetes

输出到 stdout，容器平台自动收集：

```go
config := &logger.Config{
    Output: "stdout",
    Format: "json",
}
```

#### ELK Stack

JSON 格式的日志可以直接被 Logstash 收集和解析：

```json
{
  "time": "2025-01-20T10:00:00.123Z",
  "level": "info",
  "module": "service.media",
  "msg": "操作成功"
}
```

#### Loki

Loki 可以直接收集 JSON 格式的日志，支持结构化查询。

### 监控集成

#### 错误率监控

通过查询 Error 级别的日志数量来监控错误率：

```bash
# 查询最近1小时的错误日志
grep '"level":"error"' /var/log/app.log | wc -l
```

#### 性能监控

通过查询包含 `latency` 字段的日志来监控性能：

```bash
# 查询慢请求
grep '"latency"' /var/log/app.log | jq 'select(.latency | tonumber > 1000)'
```

#### 业务指标

通过结构化字段查询业务指标：

```bash
# 查询用户注册数量
grep '"operation":"register"' /var/log/app.log | wc -l
```

## 示例程序

详细的使用示例请参考 `example/main.go`：

```bash
cd pkg/logger/example
go run main.go
```

示例程序演示了：
1. 控制台日志输出
2. JSON 格式日志
3. 文件日志（带轮转）
4. 异步写入
5. 不同日志级别
6. 带上下文的日志
7. 错误日志（带堆栈）
8. 多模块日志

## 常见问题

### Q: 如何在不同环境使用不同配置？

A: 根据环境变量或配置文件加载不同配置：

```go
var config *logger.Config
if os.Getenv("ENV") == "production" {
    config = &logger.Config{
        Level:  "info",
        Format: "json",
        Output: "/var/log/app.log",
    }
} else {
    config = &logger.Config{
        Level:  "debug",
        Format: "console",
        Output: "stdout",
    }
}
logger.Init(config)
```

### Q: 如何过滤特定模块的日志？

A: 使用 `module` 字段过滤：

```bash
# 只查看 service.media 模块的日志
grep '"module":"service.media"' /var/log/app.log
```

### Q: 如何追踪特定请求的所有日志？

A: 使用 `request_id` 字段：

```bash
# 追踪特定请求
grep '"request_id":"req-12345"' /var/log/app.log
```

### Q: 文件轮转不工作？

A: 检查 `FileConfig.MaxSize` 是否设置，以及文件路径是否有写权限。

### Q: 异步写入导致日志丢失？

A: 应用关闭时确保调用 `logger.Sync()`：

```go
defer logger.Sync()
```
