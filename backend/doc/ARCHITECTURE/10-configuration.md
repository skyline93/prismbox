# 10. 配置管理

## 10.1 设计原则

配置模块的设计遵循以下原则：

1. **模块化设计**：按功能模块组织配置结构，便于维护和扩展
2. **类型安全**：使用 Go 结构体定义配置，避免 `map[string]interface{}`，提供编译时类型检查
3. **优先级清晰**：环境变量 > YAML 配置文件 > 默认值
4. **验证机制**：启动时验证必填项和格式，及早发现问题
5. **与 Builder 集成**：配置加载后直接用于依赖注入构建，无缝集成
6. **扩展性**：易于添加新模块和配置项，不影响现有代码

## 10.2 目录结构

```
internal/config/
├── config.go          # 主配置结构体
├── loader.go          # 配置加载器（YAML + 环境变量）
├── validator.go       # 配置验证器
├── types.go           # 自定义类型（Duration, Size 等）
└── modules/           # 各模块配置
    ├── server.go      # 服务器配置
    ├── database.go    # 数据库配置
    ├── storage.go     # 存储配置（主存储、次存储）
    ├── backup.go      # 备份调度配置
    ├── queue.go       # 队列配置
    ├── auth.go        # 认证配置
    ├── media.go        # 媒体配置
    └── logger.go      # 日志配置
```

## 10.3 核心设计

### 10.3.1 主配置结构

```go
// internal/config/config.go
package config

import (
    "internal/config/modules"
)

// Config 应用主配置
// 所有模块配置都通过独立的结构体组织，便于维护和扩展
type Config struct {
    // 服务器配置
    Server *modules.ServerConfig `yaml:"server"`
    
    // 数据库配置
    Database *modules.DatabaseConfig `yaml:"database"`
    
    // 存储配置（最复杂，包含主存储、次存储、备份）
    Storage *modules.StorageConfig `yaml:"storage"`
    
    // 队列配置
    Queue *modules.QueueConfig `yaml:"queue"`
    
    // 认证配置
    Auth *modules.AuthConfig `yaml:"auth"`
    
    // 媒体配置
    Media *modules.MediaConfig `yaml:"media"`
    
    // 日志配置
    Logger *modules.LoggerConfig `yaml:"logger"`
}
```

### 10.3.2 配置加载器

配置加载器负责按优先级加载配置：环境变量 > YAML 文件 > 默认值

```go
// internal/config/loader.go
type Loader struct {
    configPath string
    envPrefix  string // 环境变量前缀，如 "ALBUM_"
}

// Load 加载配置
// 优先级：环境变量 > YAML 文件 > 默认值
func (l *Loader) Load() (*Config, error) {
    cfg := &Config{}
    
    // 1. 设置默认值
    l.setDefaults(cfg)
    
    // 2. 加载 YAML 文件（如果存在）
    if l.configPath != "" {
        if err := l.loadYAML(cfg); err != nil {
            return nil, fmt.Errorf("load YAML config: %w", err)
        }
    }
    
    // 3. 环境变量覆盖（最高优先级）
    if err := l.loadEnv(cfg); err != nil {
        return nil, fmt.Errorf("load env config: %w", err)
    }
    
    // 4. 验证配置
    validator := NewValidator()
    if err := validator.Validate(cfg); err != nil {
        return nil, fmt.Errorf("validate config: %w", err)
    }
    
    return cfg, nil
}
```

### 10.3.3 自定义类型

配置模块提供了自定义类型，支持 YAML 中的友好格式：

**Duration 类型**：支持 `"30m"`, `"24h"`, `"5m"` 等格式
```go
type Duration time.Duration

func (d *Duration) UnmarshalYAML(unmarshal func(interface{}) error) error {
    var s string
    if err := unmarshal(&s); err != nil {
        return err
    }
    dur, err := time.ParseDuration(s)
    if err != nil {
        return err
    }
    *d = Duration(dur)
    return nil
}
```

**Size 类型**：支持 `"1TB"`, `"500GB"`, `"100MB"`, `"64KB"` 等格式
```go
type Size int64

func (s *Size) UnmarshalYAML(unmarshal func(interface{}) error) error {
    var str string
    if err := unmarshal(&str); err != nil {
        return err
    }
    size, err := parseSize(str)
    if err != nil {
        return err
    }
    *s = Size(size)
    return nil
}
```

### 10.3.4 配置验证器

配置验证器在启动时验证配置的有效性：

```go
// internal/config/validator.go
type Validator struct{}

// Validate 验证配置
func (v *Validator) Validate(cfg *Config) error {
    if err := v.validateServer(cfg.Server); err != nil {
        return fmt.Errorf("server: %w", err)
    }
    
    if err := v.validateDatabase(cfg.Database); err != nil {
        return fmt.Errorf("database: %w", err)
    }
    
    if err := v.validateStorage(cfg.Storage); err != nil {
        return fmt.Errorf("storage: %w", err)
    }
    
    // ... 其他验证
    
    return nil
}
```

验证内容包括：
- 必填项检查
- 路径存在性和可写性检查
- 格式验证（日志级别、数据库类型等）
- 数值范围验证（端口号、超时时间等）

### 10.3.5 与 Builder 模式集成

配置加载后直接用于依赖注入构建：

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
    if err := builder.BuildLogger(); err != nil {
        log.Fatalf("Failed to build logger: %v", err)
    }
    defer logger.Sync()
    
    if err := builder.BuildDatabase(); err != nil {
        log.Fatalf("Failed to build database: %v", err)
    }
    
    // ... 构建其他组件
    
    app := builder.Build()
    
    // 3. 启动服务
    // ...
}
```

## 10.4 配置文件结构

```yaml
# configs/config.yaml
server:
  address: "0.0.0.0:8080"
  read_timeout: 30s
  write_timeout: 30s

database:
  type: "postgres"  # postgres, mysql, sqlite
  host: "localhost"
  port: 5432
  user: "mobile"
  password: "mobile"
  dbname: "mobile"
  sslmode: "disable"

storage:
  # 主存储配置（本地存储）
  primary:
    type: "local"
    local:
      base_path: "/data/uploads"
      
      # 存储池配置
      pools:
        - id: "pool-1"
          path: "/data/storage1"
          max_size: "1TB"
          priority: 1
          enabled: true
          auto_disable_threshold: 0.9
        - id: "pool-2"
          path: "/data/storage2"
          max_size: "2TB"
          priority: 2
          enabled: true
          auto_disable_threshold: 0.9
      
      # 临时文件配置
      temp:
        base_path: "/data/temp"
        max_age: "24h"
        max_size: "10GB"
        cleanup_interval: "1h"
      
      # 处理配置
      processing:
        enable_compression: true
        compression_level: 6
        enable_encryption: false
        encryption_key_path: "/etc/album/encryption.key"
      
      # 性能配置
      performance:
        cache_enabled: true
        cache_size: "1GB"
        cache_ttl: "24h"
        read_buffer_size: "64KB"
        write_buffer_size: "64KB"
  
  # 次存储配置（云存储备份，可选）
  secondary:
    enabled: true
    type: "openlist"  # openlist, s3, oss, cos
    openlist:
      # OpenList 服务配置
      base_url: "http://openlist:5244"
      api_key: "your-api-key"
      
      # 连接配置
      timeout: 30s
      max_retries: 3
      retry_backoff: 1s
      
      # 连接池配置
      max_connections: 100
      idle_timeout: 90s
      
      # 缓存配置
      cache:
        enabled: true
        ttl: 5m
        max_size: 100MB
      
      # 存储池配置（对应 OpenList 的 Drivers）
      pools:
        - id: "s3-backup"
          name: "S3 备份存储"
          driver_id: "s3-driver-1"
          type: "s3"
          max_size: "10TB"
          priority: 1
          enabled: true
        - id: "baidu-cloud"
          name: "百度网盘"
          driver_id: "baidu-driver-1"
          type: "baidu"
          max_size: "2TB"
          priority: 2
          enabled: true
      
      # 路径映射
      path_mapping:
        base_path: "/album"
        virtual_paths:
          - virtual: "/files"
            physical: "/album/files"
    
    # 直接对接的云存储（可选）
    s3:
      region: "us-east-1"
      bucket: "my-bucket"
      access_key: "..."
      secret_key: "..."
  
  # 备份调度配置
  backup:
    enabled: true
    scheduler:
      scan_interval: "5m"        # 扫描间隔：5分钟
      batch_size: 100            # 批量处理大小：100个文件
      idle_threshold: 0.3        # 系统空闲阈值：30%
      max_concurrency: 5         # 最大并发数：5
      delay_execution: "5m"      # 延迟执行：5分钟
    
    # 备份策略
    strategy:
      priority: 1                # 低优先级
      retry_times: 3             # 重试次数
      retry_interval: "10m"      # 重试间隔：10分钟
      max_age: "24h"              # 最大等待时间：24小时

queue:
  concurrency: 10
  min_poll_interval_ms: 200
  max_poll_interval_ms: 3000

auth:
  jwt_secret: "..."
  access_token_expires_in: 30m
  refresh_token_expires_in: 720h

media:
  upload_dir: "./uploads"
  max_file_size: 100MB
  allowed_types: ["image/jpeg", "image/png", "video/mp4"]

logger:
  level: "info"              # debug, info, warn, error
  format: "json"             # json, console
  output: "/var/log/album/app.log"  # stdout, stderr, 或文件路径
  enable_caller: true        # 包含调用位置（文件名:行号）
  enable_stack: true         # 包含堆栈信息（Error 级别）
  async: true                # 异步写入
  buffer_size: 1000          # 异步缓冲大小
  
  # 文件配置（output 为文件时生效）
  file:
    max_size: 104857600      # 单个文件最大大小（字节），100MB
    max_backups: 10          # 保留文件数量
    max_age: 30              # 保留天数
    compress: true           # 是否压缩旧文件
```

## 10.5 环境变量支持

配置可以通过环境变量覆盖，优先级：**环境变量 > YAML 配置文件 > 默认值**

环境变量统一使用 `ALBUM_` 前缀，便于区分和管理。

### 10.5.1 服务器配置

- `ALBUM_SERVER_ADDRESS`: 服务器监听地址（如 `0.0.0.0:8080`）
- `ALBUM_PUBLIC_BASE_URL`: 公共基础 URL（如 `http://localhost:8080`）
- `ALBUM_SERVER_READ_TIMEOUT`: 读超时时间（如 `30s`）
- `ALBUM_SERVER_WRITE_TIMEOUT`: 写超时时间（如 `30s`）

### 10.5.2 数据库配置

- `ALBUM_DB_TYPE`: 数据库类型（`postgres`, `mysql`, `sqlite`）
- `ALBUM_DB_HOST`: 数据库主机地址
- `ALBUM_DB_PORT`: 数据库端口
- `ALBUM_DB_USER`: 数据库用户名
- `ALBUM_DB_PASSWORD`: 数据库密码
- `ALBUM_DB_NAME`: 数据库名称
- `ALBUM_DB_SSLMODE`: SSL 模式（`disable`, `require`, `verify-full` 等）

### 10.5.3 存储配置

- `ALBUM_STORAGE_PRIMARY_BASE_PATH`: 主存储基础路径
- `ALBUM_STORAGE_SECONDARY_ENABLED`: 是否启用次存储（`true`/`false`）
- `ALBUM_STORAGE_SECONDARY_TYPE`: 次存储类型（`openlist`, `s3`, `oss`, `cos`）
- `ALBUM_STORAGE_SECONDARY_OPENLIST_BASE_URL`: OpenList 服务地址
- `ALBUM_STORAGE_SECONDARY_OPENLIST_API_KEY`: OpenList API 密钥
- `ALBUM_STORAGE_BACKUP_ENABLED`: 是否启用备份调度（`true`/`false`）

### 10.5.4 认证配置

- `ALBUM_AUTH_JWT_SECRET`: JWT 密钥
- `ALBUM_AUTH_ACCESS_TOKEN_EXPIRES_IN`: 访问令牌过期时间（如 `30m`）
- `ALBUM_AUTH_REFRESH_TOKEN_EXPIRES_IN`: 刷新令牌过期时间（如 `720h`）

### 10.5.5 日志配置

- `ALBUM_LOG_LEVEL`: 日志级别（`debug`, `info`, `warn`, `error`）
- `ALBUM_LOG_FORMAT`: 日志格式（`json`, `console`）
- `ALBUM_LOG_OUTPUT`: 输出目标（`stdout`, `stderr`, 或文件路径）
- `ALBUM_LOG_ENABLE_CALLER`: 是否包含调用位置（`true`/`false`）
- `ALBUM_LOG_ENABLE_STACK`: 是否包含堆栈信息（`true`/`false`）
- `ALBUM_LOG_ASYNC`: 是否异步写入（`true`/`false`）
- `ALBUM_LOG_BUFFER_SIZE`: 异步缓冲大小（整数）
- `ALBUM_LOG_FILE_MAX_SIZE`: 文件最大大小（字节）
- `ALBUM_LOG_FILE_MAX_BACKUPS`: 保留文件数量
- `ALBUM_LOG_FILE_MAX_AGE`: 保留天数

### 10.5.6 队列配置

- `ALBUM_QUEUE_CONCURRENCY`: 并发处理数量
- `ALBUM_QUEUE_MIN_POLL_INTERVAL_MS`: 最小轮询间隔（毫秒）
- `ALBUM_QUEUE_MAX_POLL_INTERVAL_MS`: 最大轮询间隔（毫秒）

### 10.5.7 使用示例

```bash
# 通过环境变量覆盖配置
export ALBUM_SERVER_ADDRESS="0.0.0.0:9090"
export ALBUM_DB_HOST="production-db.example.com"
export ALBUM_LOG_LEVEL="warn"
export ALBUM_STORAGE_PRIMARY_BASE_PATH="/data/uploads"

# 运行服务
go run cmd/server/main.go
```

