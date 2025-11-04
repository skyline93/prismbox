# Go-Gorm-Queue (GQ) 任务队列框架

## 简介

GQ 是一个基于 GORM 和关系型数据库的分布式任务队列框架，参考了 Asynq 的设计思路。

## 快速开始

### 1. 安装依赖

```bash
cd backend
go mod tidy
```

### 2. 运行示例

```bash
go run main.go
```

## 使用示例

### 创建客户端并入队任务

```go
// 创建客户端
client := gq.NewClient(db)

// 创建任务
payload, _ := json.Marshal(map[string]string{"email": "user@example.com"})
task := gq.NewTask("email:welcome", payload)

// 入队任务（带选项）
err := client.Enqueue(ctx, task,
    gq.Queue("critical"),      // 指定队列
    gq.Priority(10),           // 设置优先级
    gq.MaxRetries(3),          // 最大重试次数
    gq.ProcessAt(time.Now().Add(5 * time.Second)), // 计划执行时间
)
```

### 创建服务端并处理任务

```go
// 创建服务端配置
config := &gq.ServerConfig{
    Concurrency:       5,      // 并发 Worker 数量
    MinPollIntervalMs: 200,    // 最小轮询间隔（毫秒）
    MaxPollIntervalMs: 3000,   // 最大轮询间隔（毫秒）
}

// 创建服务端
server := gq.NewServer(db, config)

// 创建多路复用器并注册处理器
mux := gq.NewServeMux()
mux.HandleFunc("email:welcome", func(ctx context.Context, task *gq.Task) error {
    // 处理任务逻辑
    return nil
})

// 启动服务端
server.Run(mux)
```

## 核心特性

- ✅ 基于关系型数据库（MySQL/PostgreSQL/SQLite）
- ✅ 任务优先级队列
- ✅ 自动重试机制（指数退避）
- ✅ 计划任务（延迟执行）
- ✅ 并发控制
- ✅ 动态轮询间隔优化
- ✅ 优雅关闭

## 项目结构

```
backend/
├── pkg/gq/          # GQ 框架核心代码
│   ├── model.go     # 数据库模型
│   ├── task.go      # 任务定义
│   ├── options.go   # 选项功能
│   ├── client.go    # 客户端实现
│   ├── server.go    # 服务端实现
│   ├── mux.go       # 多路复用器
│   └── gq.go        # 包入口
├── main.go          # 使用示例
└── go.mod           # 依赖管理
```

