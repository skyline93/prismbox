# 4. 依赖注入

## 4.1 设计原则

采用传统的手动依赖注入方式，通过构造函数传递依赖，不使用 Wire 等代码生成工具。这样做的好处是：
- 代码更清晰，依赖关系一目了然
- 便于理解和维护
- 减少构建工具依赖

## 4.2 应用组装器

应用的所有依赖通过 `internal/app` 包进行组装：

```go
// internal/app/app.go
type App struct {
    // 配置
    Config *config.Config
    
    // 数据库
    DB *gorm.DB
    
    // 存储
    PrimaryStorage   storage.PrimaryStorage   // 主存储（本地存储）
    SecondaryStorage storage.SecondaryStorage  // 次存储（云存储，可选）
    StorageManager   *storage.StorageManager  // 存储管理器
    
    // 备份调度器
    BackupScheduler  *backup.Scheduler        // 备份调度器（可选）
    
    // 任务队列
    TaskQueueClient *gq.Client
    TaskQueueServer *gq.Server
    
    // 仓储
    UserRepo   repository.UserRepository
    MediaRepo  repository.MediaRepository
    // ...
    
    // 服务
    AuthService  service.AuthService
    MediaService service.MediaService
    // ...
}
```

## 4.3 构建器模式

使用 Builder 模式逐步构建应用：

```go
// internal/app/builder.go
type Builder struct {
    app *App
}

// 按顺序构建各个组件
func BuildAll(cfg *config.Config) (*App, error) {
    builder := NewBuilder(cfg)
    
    // 按顺序构建各个组件
    if err := builder.BuildLogger(); err != nil {
        return nil, fmt.Errorf("build logger: %w", err)
    }
    
    if err := builder.BuildDatabase(); err != nil {
        return nil, fmt.Errorf("build database: %w", err)
    }
    
    if err := builder.BuildPrimaryStorage(); err != nil {
        return nil, fmt.Errorf("build primary storage: %w", err)
    }
    
    if err := builder.BuildSecondaryStorage(); err != nil {
        return nil, fmt.Errorf("build secondary storage: %w", err)
    }
    
    if err := builder.BuildStorageManager(); err != nil {
        return nil, fmt.Errorf("build storage manager: %w", err)
    }
    
    if err := builder.BuildTaskQueue(); err != nil {
        return nil, fmt.Errorf("build task queue: %w", err)
    }
    
    if err := builder.BuildBackupScheduler(); err != nil {
        return nil, fmt.Errorf("build backup scheduler: %w", err)
    }
    
    if err := builder.BuildRepositories(); err != nil {
        return nil, fmt.Errorf("build repositories: %w", err)
    }
    
    if err := builder.BuildServices(); err != nil {
        return nil, fmt.Errorf("build services: %w", err)
    }
    
    return builder.Build(), nil
}
```

## 4.4 存储相关依赖注入

```go
// internal/app/builder.go
func (b *Builder) BuildPrimaryStorage() error {
    primary, err := storage.NewPrimaryStorage(b.cfg.Storage.Primary)
    if err != nil {
        return err
    }
    b.app.PrimaryStorage = primary
    return nil
}

func (b *Builder) BuildSecondaryStorage() error {
    if !b.cfg.Storage.Secondary.Enabled {
        return nil  // 未启用次存储
    }
    
    secondary, err := storage.NewSecondaryStorage(b.cfg.Storage.Secondary)
    if err != nil {
        return err
    }
    b.app.SecondaryStorage = secondary
    return nil
}

func (b *Builder) BuildStorageManager() error {
    manager := storage.NewStorageManager(b.app.PrimaryStorage)
    b.app.StorageManager = manager
    return nil
}

func (b *Builder) BuildBackupScheduler() error {
    if !b.cfg.Storage.Backup.Enabled {
        return nil  // 未启用备份
    }
    
    scheduler := backup.NewScheduler(
        b.app.DB,
        b.app.SecondaryStorage,
        b.app.TaskQueueClient,
        b.cfg.Storage.Backup,
    )
    b.app.BackupScheduler = scheduler
    return nil
}
```

## 4.5 配置加载

配置通过 `internal/config` 包加载，支持 YAML 文件和环境变量：

```go
// cmd/server/main.go
func main() {
    // 1. 加载配置
    loader := config.NewLoader("configs/config.yaml")
    cfg, err := loader.Load()
    if err != nil {
        log.Fatalf("Could not load config: %v", err)
    }
    
    // 2. 构建应用（使用 Builder 模式）
    builder := app.NewBuilder(cfg)
    
    // 按顺序构建各个组件
    // ...
}
```

## 4.6 日志模块初始化

日志模块采用全局单例模式，不需要通过依赖注入传递，但需要在应用启动时初始化：

```go
// internal/app/builder.go
func (b *Builder) BuildLogger() error {
    // 使用配置中的日志配置初始化日志系统
    loggerConfig := &logger.Config{
        Level:        b.cfg.Logger.Level,
        Format:       b.cfg.Logger.Format,
        Output:       b.cfg.Logger.Output,
        EnableCaller: b.cfg.Logger.EnableCaller,
        EnableStack:  b.cfg.Logger.EnableStack,
        Async:        b.cfg.Logger.Async,
        BufferSize:   b.cfg.Logger.BufferSize,
        FileConfig:   b.cfg.Logger.FileConfig,
    }
    
    if err := logger.Init(loggerConfig); err != nil {
        return fmt.Errorf("init logger: %w", err)
    }
    
    return nil
}

// cmd/server/main.go
func main() {
    // 1. 加载配置
    loader := config.NewLoader("configs/config.yaml")
    cfg, err := loader.Load()
    if err != nil {
        log.Fatalf("Could not load config: %v", err)
    }
    
    // 2. 构建应用（使用 Builder 模式）
    builder := app.NewBuilder(cfg)
    
    // 3. 初始化日志系统（在构建其他组件之前）
    if err := builder.BuildLogger(); err != nil {
        log.Fatalf("Failed to build logger: %v", err)
    }
    defer logger.Sync()  // 确保所有日志写入完成
    
    // 4. 后续构建其他组件...
}
```

**日志模块在服务中的使用**：

```go
// internal/service/media/service.go
type service struct {
    logger        logger.Logger  // 模块级 logger（通过 logger.New() 创建）
    repo          repository.MediaRepository
    storageManager *storage.StorageManager
    taskQueue     *gq.Client
    config        *Config
}

// 构造函数中创建模块 logger
func NewService(
    repo repository.MediaRepository,
    storageManager *storage.StorageManager,
    taskQueue *gq.Client,
    config *Config,
) Service {
    return &service{
        logger:        logger.New("service.media"),  // 模块名，共享全局配置
        repo:          repo,
        storageManager: storageManager,
        taskQueue:     taskQueue,
        config:        config,
    }
}
```

**关键点**：
- 日志模块通过全局单例初始化，不存储在 App 结构体中
- 各模块通过 `logger.New("module.name")` 创建自己的 logger 实例
- 所有 logger 实例共享全局配置和写入器
- 日志模块初始化应在应用启动的最早阶段，确保所有组件都能使用日志

## 4.7 服务层依赖注入示例

```go
// internal/service/media/service.go
type service struct {
    logger        logger.Logger  // 模块级 logger
    repo          repository.MediaRepository
    storageManager *storage.StorageManager  // 使用存储管理器
    taskQueue     *gq.Client
    config        *Config
}

// 构造函数接收所有依赖
func NewService(
    repo repository.MediaRepository,
    storageManager *storage.StorageManager,  // 只使用主存储管理器
    taskQueue *gq.Client,
    config *Config,
) Service {
    return &service{
        logger:        logger.New("service.media"),  // 创建模块 logger
        repo:          repo,
        storageManager: storageManager,
        taskQueue:     taskQueue,
        config:        config,
    }
}
```

## 4.8 API 层依赖注入

API 层的依赖注入在 `cmd/server/main.go` 中完成，不在 `internal/app` 中构建，因为 API 层是应用启动时的入口点。

```go
// cmd/server/main.go
func main() {
    // 1. 加载配置
    cfg := loadConfig()
    
    // 2. 初始化日志系统
    initLogger(cfg)
    
    // 3. 构建应用（依赖注入）
    app := buildApp(cfg)
    
    // 4. 创建路由（API 层依赖注入）
    router := api.NewRouter(app)  // 传入 app 实例
    router.Setup()                // 注册所有路由和中间件
    
    // 5. 创建并启动服务器
    // ...
}
```

**API Handler 的依赖注入**：

```go
// internal/api/v1/media/handler.go
type Handler struct {
    mediaService service.MediaService  // 依赖 Service 层
    logger       logger.Logger         // 使用 pkg/logger
}

func NewHandler(mediaService service.MediaService) *Handler {
    return &Handler{
        mediaService: mediaService,
        logger:       logger.New("api.v1.media"),
    }
}

// internal/api/v1/media/routes.go
func RegisterRoutes(rg *gin.RouterGroup, app *app.App) {
    // 从 app 实例获取依赖的服务
    handler := NewHandler(app.MediaService)
    
    // 注册路由
    // ...
}
```

**关键点**：
- API 层通过 `app.App` 实例获取所有依赖的服务
- Handler 只依赖 Service 层，不直接依赖 Repository 或 Storage
- 日志使用 `pkg/logger`，通过 `logger.New("module.name")` 创建模块级 logger
- 路由注册在 `router.Setup()` 中统一完成

