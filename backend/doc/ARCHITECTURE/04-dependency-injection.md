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
    
    builder.BuildDatabase()
    builder.BuildPrimaryStorage()
    builder.BuildSecondaryStorage()
    builder.BuildStorageManager()
    builder.BuildBackupScheduler()
    builder.BuildTaskQueue()
    builder.BuildRepositories()
    builder.BuildServices()
    
    return builder.Build()
}
```

## 4.4 存储相关依赖注入

```go
// internal/app/builder.go
func (b *Builder) BuildPrimaryStorage() error {
    primary, err := storage.NewPrimaryStorage(b.config.Storage)
    if err != nil {
        return err
    }
    b.app.PrimaryStorage = primary
    return nil
}

func (b *Builder) BuildSecondaryStorage() error {
    if !b.config.Storage.Secondary.Enabled {
        return nil  // 未启用次存储
    }
    
    secondary, err := storage.NewSecondaryStorage(b.config.Storage)
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
    if !b.config.Storage.Backup.Enabled {
        return nil  // 未启用备份
    }
    
    scheduler := backup.NewScheduler(
        b.app.DB,
        b.app.SecondaryStorage,
        b.app.TaskQueueClient,
        b.config.Storage.Backup,
    )
    b.app.BackupScheduler = scheduler
    return nil
}
```

## 4.5 服务层依赖注入示例

```go
// internal/service/media/service.go
type service struct {
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
        repo:          repo,
        storageManager: storageManager,
        taskQueue:     taskQueue,
        config:        config,
    }
}
```

