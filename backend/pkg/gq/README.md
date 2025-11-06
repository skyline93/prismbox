# Go-Gorm-Queue (GQ)

**Go-Gorm-Queue (GQ)** 是一个受 Asynq 启发的、使用 Go 语言编写的分布式任务队列框架。与 Asynq 使用 Redis 作为消息代理不同，GQ 将使用 GORM 支持的关系型数据库（如 MySQL, PostgreSQL）来存储和管理任务队列信息。

项目旨在提供一个简单、可靠且易于集成的异步任务处理方案，其架构和 API 设计将高度参考 Asynq，以便熟悉 Asynq 的开发者能够快速上手。

## 核心概念

*   **任务 (Task):** 需要异步执行的工作单元。每个任务包含一个唯一的 **类型 (Type)** 和一个用于传递数据的 **载荷 (Payload)**。
*   **队列 (Queue):** 任务的逻辑分组。不同的队列可以有不同的优先级。
*   **客户端 (Client):** 负责创建任务并将其推送到数据库中（入队）。
*   **服务端 (Server):** 负责从数据库中拉取任务，并根据其类型分发给对应的处理器执行。服务端管理着一个工作者池（Worker Pool）来并发处理任务。
*   **处理器 (Handler):** 处理特定类型任务的函数。`func(ctx context.Context, t *Task) error`。
*   **多路复用器 (ServeMux):** 类似于 `net/http` 的 `ServeMux`，用于注册任务类型和其对应的处理器。

## 数据库模型设计 (GORM Model)

我们将设计一张核心的 `tasks` 表来存储所有任务信息。

```go
// gorm.Model 包含了 ID, CreatedAt, UpdatedAt, DeletedAt
type Task struct {
    gorm.Model

    // UUID 用于对外暴露和追踪，避免暴露自增ID
    UUID        string `gorm:"type:varchar(36);uniqueIndex;not null"`

    // 任务所属的队列名称
    Queue       string `gorm:"type:varchar(255);index;not null"`

    // 任务类型，用于匹配 Handler
    Type        string `gorm:"type:varchar(255);not null"`

    // 任务的载荷，以 JSON 格式存储
    Payload     []byte `gorm:"type:json"`

    // 任务状态: pending, active, retrying, archived, failed
    Status      string `gorm:"type:varchar(50);index;not null"`

    // 任务优先级，数值越大，优先级越高
    Priority    int `gorm:"default:0;not null"`

    // 当前重试次数
    RetryCount  int `gorm:"default:0"`

    // 最大允许重试次数
    MaxRetries  int `gorm:"default:3"`

    // 最后一次执行的错误信息
    LastError   string `gorm:"type:text"`

    // 下次处理时间（用于计划任务和重试退避）
    ProcessAt   time.Time

    // 处理完成时间
    ProcessedAt sql.NullTime

    // 永久失败时间
    FailedAt    sql.NullTime
}
```

**字段解释:**

*   `UUID`: 保证任务的唯一性，方便日志追踪和排查问题。
*   `Queue`: 任务被投递到的队列名。
*   `Status`: 核心字段，用于管理任务的生命周期。
    *   `pending`: 待处理。
    *   `active`: 正在被 Worker 处理。
    *   `retrying`: 处理失败，等待重试。
    *   `archived`: 处理成功，归档（或可被清理）。
    *   `failed`: 达到最大重试次数后，永久失败。
*   `Priority`: 用于优先级队列的实现。
*   `ProcessAt`: 控制任务何时可以被执行。新任务的 `ProcessAt` 通常是 `time.Now()`，而计划任务或重试任务的 `ProcessAt` 则是未来的某个时间点。

## 架构设计

GQ 遵循 Asynq 的 Client-Server 模型。

### 客户端 (Client)

*   **职责**:
    1.  接收任务类型、载荷和选项（如队列、优先级、重试次数）。
    2.  构造一个 `Task` 结构体实例。
    3.  将其状态设置为 `pending`。
    4.  通过 GORM 将其保存到数据库的 `tasks` 表中。

*   **实现**:
    ```go
    type Client struct {
        db *gorm.DB
    }

    func NewClient(db *gorm.DB) *Client {
        return &Client{db: db}
    }

    // Enqueue 将一个任务添加到队列中
    func (c *Client) Enqueue(ctx context.Context, task *Task, opts ...Option) error {
        // ... 应用选项设置 ...
        task.UUID = generateUUID()
        task.Status = "pending"
        task.ProcessAt = time.Now()
        return c.db.WithContext(ctx).Create(task).Error
    }
    ```

### 服务端 (Server)

服务端是整个框架的核心，负责任务的调度和执行。

*   **职责**:
    1.  维护一个 Worker 池（goroutine 池）来并发执行任务。
    2.  管理一个 `ServeMux` 来存储任务类型到 Handler 的映射。
    3.  启动一个调度循环 (Scheduler Loop)，定期从数据库中拉取可执行的任务。
    4.  将拉取到的任务分发给空闲的 Worker。
    5.  处理任务执行结果（成功、失败、重试）。

*   **调度循环 (Scheduler Loop) 的关键逻辑**:
    这是与 Asynq 的 `BRPOP` 阻塞式拉取最大的不同点。我们需要通过**数据库轮询**实现。

    1.  **开启事务**: 为了保证数据一致性，整个"拉取-锁定"过程必须在事务中进行。
    2.  **查询任务**:
        *   使用 `SELECT ... FOR UPDATE SKIP LOCKED` 来查询任务。这是一个关键技术，它能让多个 Server 实例（或多个调度器）同时查询 `tasks` 表而不会因为行锁而相互阻塞。查询到的行会被当前事务锁定，其他事务会跳过这些锁定的行。
        *   **查询条件**:
            *   `status IN ('pending', 'retrying')`
            *   `process_at <= NOW()`
        *   **排序规则**:
            *   `ORDER BY priority DESC, process_at ASC` (先按优先级，同优先级下按计划执行时间)
        *   **限制数量**: `LIMIT [concurrency - active_workers]` (一次最多拉取可用的 worker 数量的任务)
    3.  **锁定任务**:
        *   将查询到的任务状态更新为 `active`。
        *   `UPDATE tasks SET status = 'active' WHERE id IN (...)`
    4.  **提交事务**: 释放锁，此时任务已经安全地被当前 Server 实例获取。
    5.  **分发任务**: 将获取到的任务列表发送到一个内部的 channel 中，由 Worker 池消费。

## 核心功能实现方案

### 任务注册 (Handler & ServeMux)

*   `Handler` 是一个接口或函数类型。
    ```go
    type Handler interface {
        ProcessTask(context.Context, *Task) error
    }

    type HandlerFunc func(context.Context, *Task) error
    ```
*   `ServeMux` 内部使用 `map[string]Handler` 来存储映射。
    ```go
    type ServeMux struct {
        mu sync.Mutex
        m  map[string]Handler
    }

    func (mux *ServeMux) Handle(taskType string, handler Handler) {
        // ... 注册逻辑 ...
    }
    ```
*   `Server` 包含一个 `ServeMux` 实例。当 Worker 拿到一个任务时，会根据 `task.Type` 从 `ServeMux` 中查找对应的 `Handler` 并执行。

### 队列优先级

*   **实现**: 在调度器拉取任务的 SQL 查询中，通过 `ORDER BY priority DESC` 实现。优先级高的任务会先被查询出来。
*   **API**: 在 `Client.Enqueue` 的选项中提供设置优先级的函数。
    ```go
    // 示例
    client.Enqueue(ctx, task, GQ.Priority(10))
    ```

### 并发控制

*   **实现**: `Server` 在启动时，根据配置的 `Concurrency` 值，创建相应数量的 Worker goroutine。
*   `Server` 内部维护一个带缓冲的 channel，作为任务分发队列。调度器将从数据库取出的任务放入此 channel，Worker 从中取出任务执行。Channel 的缓冲区大小可以设置为 `Concurrency` 的值。
    ```go
    type Server struct {
        // ...
        concurrency int
        tasksChan   chan *Task
    }

    func (s *Server) Run() {
        s.tasksChan = make(chan *Task, s.concurrency)

        // 启动 Workers
        for i := 0; i < s.concurrency; i++ {
            go s.worker()
        }

        // 启动调度器
        go s.scheduler()
    }
    ```

### 任务重试

*   **实现**: 当一个 Worker 执行 `Handler` 并收到一个 `error` 时：
    1.  Worker 检查任务的 `RetryCount` 是否小于 `MaxRetries`。
    2.  **如果可以重试**:
        *   `RetryCount` 加 1。
        *   记录 `LastError` 信息。
        *   计算下一次的 `ProcessAt`（可以使用指数退避算法 `now + initial_delay * 2^retry_count`）。
        *   将任务状态更新为 `retrying`。
        *   将更新后的任务信息写回数据库。
    3.  **如果达到最大重试次数**:
        *   将任务状态更新为 `failed`。
        *   记录 `LastError` 和 `FailedAt` 时间。
        *   将更新后的任务信息写回数据库。

## API 设计（初稿）

```go
package GQ

// --- Client Side ---

// 任务定义
type Task struct {
    Type    string
    Payload []byte
}

func NewTask(typeName string, payload []byte) *Task { /* ... */ }

// 客户端
type Client struct { /* ... */ }
func NewClient(db *gorm.DB) *Client { /* ... */ }
func (c *Client) Enqueue(ctx context.Context, task *Task, opts ...Option) error { /* ... */ }

// 选项
type Option interface { /* ... */ }
func Queue(name string) Option { /* ... */ }
func Priority(p int) Option { /* ... */ }
func MaxRetries(n int) Option { /* ... */ }


// --- Server Side ---

// 服务端
type Server struct { /* ... */ }
type ServerConfig struct {
    Concurrency       int // 并发 Worker 数量
    MinPollIntervalMs int // 最小轮询间隔（毫秒）
    MaxPollIntervalMs int // 最大轮询间隔（毫秒）
}
func NewServer(db *gorm.DB, config *ServerConfig) *Server { /* ... */ }
func (s *Server) Run(mux *ServeMux) error { /* ... */ }
func (s *Server) Shutdown(ctx context.Context) error { /* ... */ }

// 处理器
type Handler interface {
    ProcessTask(context.Context, *Task) error
}

// 多路复用器
type ServeMux struct { /* ... */ }
func NewServeMux() *ServeMux { /* ... */ }
func (mux *ServeMux) Handle(taskType string, handler Handler) { /* ... */ }


// --- Example Usage ---

// main.go
func main() {
    // 0. 初始化日志系统（Server 内部使用 logger 包进行日志记录）
    logger.Init(&logger.Config{
        Level:  "info",
        Format: "console",
        Output: "stdout",
    })
    defer logger.Sync()

    // 1. 设置数据库
    db, _ := gorm.Open(...)

    // 2. 客户端入队
    client := GQ.NewClient(db)
    taskPayload, _ := json.Marshal(map[string]string{"email": "user@example.com"})
    client.Enqueue(context.Background(),
        GQ.NewTask("email:welcome", taskPayload),
        GQ.Queue("critical"),
        GQ.Priority(10),
    )

    // 3. 服务端处理
    config := &GQ.ServerConfig{
        Concurrency:       20,
        MinPollIntervalMs: 100,
        MaxPollIntervalMs: 5000,
    }
    server := GQ.NewServer(db, config)
    mux := GQ.NewServeMux()
    mux.Handle("email:welcome", welcomeEmailHandler)

    server.Run(mux)
}
```

## 日志记录

GQ 使用 `pkg/logger` 包进行日志记录。Server 内部会自动创建 logger 实例，模块名为 `"gq.server"`。

### 日志初始化

在使用 GQ 之前，需要先初始化 logger 系统：

```go
import "github.com/album/backend/pkg/logger"

func main() {
    // 初始化日志系统
    logger.Init(&logger.Config{
        Level:  "info",
        Format: "console", // 或 "json"
        Output: "stdout",
    })
    defer logger.Sync()

    // ... 使用 GQ ...
}
```

### Server 日志输出

Server 会输出以下类型的日志：

- **Info 级别**：
  - Server 启动和停止
  - Worker 启动和停止
  - 任务成功完成
  - 任务重试计划

- **Warn 级别**：
  - 未找到任务处理器

- **Error 级别**：
  - 数据库查询错误
  - 任务执行失败
  - 任务永久失败（达到最大重试次数）

### 日志模块名

Server 内部使用的 logger 模块名为 `"gq.server"`，可以通过日志过滤查看 GQ 相关的日志：

```bash
# 查看 GQ Server 的日志
grep '"module":"gq.server"' /var/log/app.log
```

## 潜在挑战与优化方向

1.  **数据库轮询性能**:
    *   **挑战**: 频繁的轮询会给数据库带来压力，尤其是在任务量不大的情况下。
    *   **优化**: 可以实现动态轮询间隔。当队列为空时，逐渐增加轮询间隔（如 1s -> 2s -> 5s）；当检测到新任务时，恢复到最小间隔。
2.  **`FOR UPDATE SKIP LOCKED` 的兼容性**:
    *   **挑战**: 这个特性在 PostgreSQL, MySQL 8+, MariaDB 10.6+ 中支持良好，但对于旧版本数据库或 SQLite 可能不兼容。设计时需要明确声明支持的数据库版本。
3.  **事务隔离与长任务**:
    *   **挑战**: `FOR UPDATE` 会锁定行直到事务提交。如果从查询到分发任务的逻辑过长，会增加锁的持有时间。
    *   **优化**: 调度器逻辑应尽可能快，只负责"查询-锁定-更新状态"，然后立即提交事务，再进行内存中的分发操作。
4.  **死信队列 (Dead-Letter Queue)**:
    *   **初版未包含**: 达到最大重试次数的任务状态被设为 `failed`。后续版本可以增加一个功能，将这些任务移动到一张单独的 `dead_tasks` 表，方便人工介入和分析。
5.  **高可用性**:
    *   可以同时运行多个 Server 实例，连接到同一个数据库。`FOR UPDATE SKIP LOCKED` 保证了它们不会重复执行同一个任务，天然地实现了水平扩展和高可用。

这个设计方案为您提供了一个坚实的起点，用于构建一个功能完备且可靠的、基于 GORM 的任务队列框架。

