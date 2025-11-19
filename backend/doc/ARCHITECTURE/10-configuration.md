# 10. 配置管理

## 10.1 设计原则

配置模块的设计遵循以下原则：

1. **模块化设计**：按功能模块组织配置结构，便于维护和扩展
2. **类型安全**：使用 Go 结构体定义配置，避免 `map[string]interface{}`，提供编译时类型检查
3. **优先级清晰**：命令行参数 > 环境变量 > 配置文件 > 默认值
4. **简化维护**：使用成熟的 Viper 库统一管理配置，减少手动代码
5. **运行时验证**：移除启动时验证，让运行时错误自然暴露，更直观
6. **依赖注入优化**：各服务只接收自己需要的配置块，职责清晰
7. **扩展性**：易于添加新模块和配置项，不影响现有代码

## 10.2 目录结构

```
internal/config/
├── config.go          # 主配置结构体定义（移除 Validate 方法）
├── loader.go          # Viper 配置加载器
├── flags.go           # 命令行参数定义（新增）
└── types/
    └── types.go       # 自定义类型（Duration, Size，从 modules 重命名）
```

**变更说明**：
- 删除 `validator.go`：移除配置验证器
- 删除 `modules/` 目录：重命名为 `types/`，更清晰的命名
- 新增 `flags.go`：命令行参数定义

## 10.3 核心设计

### 10.3.1 主配置结构

```go
// internal/config/config.go
package config

import (
    "github.com/album/backend/internal/changelog"
    "github.com/album/backend/internal/config/types"  // 从 modules 改为 types
    "github.com/album/backend/internal/database"
    "github.com/album/backend/internal/server"
    "github.com/album/backend/internal/service/auth"
    "github.com/album/backend/internal/storage"
    "github.com/album/backend/pkg/gq"
    "github.com/album/backend/pkg/logger"
    mediaprocessor "github.com/album/backend/pkg/media-processor"
)

// APIConfig API 配置
type APIConfig struct {
    MaxFileSize types.Size `yaml:"max_file_size"`
}

// Config 应用主配置
// 所有模块配置都通过独立的结构体组织，便于维护和扩展
type Config struct {
    Server    *server.Config         `yaml:"server"`
    Database  *database.Config       `yaml:"database"`
    Storage   *storage.Config        `yaml:"storage"`
    Auth      *auth.Config           `yaml:"auth"`
    API       *APIConfig             `yaml:"api"`
    Logger    *logger.Config         `yaml:"logger"`
    Changelog *changelog.Config      `yaml:"changelog"`
    Queue     *gq.ServerConfig       `yaml:"queue"`
    Media     *mediaprocessor.Config `yaml:"media"`
}

// 注意：已移除 Validate 方法，让运行时错误自然暴露
```

### 10.3.2 配置加载器（使用 Viper）

配置加载器使用 [Viper](https://github.com/spf13/viper) 统一管理配置，自动处理配置文件、环境变量和命令行参数。

**核心特性**：
- 自动读取环境变量（支持嵌套结构）
- 支持多种配置文件格式（YAML、JSON、TOML 等）
- 命令行参数支持（通过 Pflag）
- 自动合并配置（无需手动合并逻辑）

```go
// internal/config/loader.go
package config

import (
    "fmt"
    "strings"
    "github.com/spf13/viper"
    "github.com/spf13/pflag"
)

type Loader struct {
    v          *viper.Viper
    configPath string
}

// NewLoader 创建配置加载器
func NewLoader(configPath string) *Loader {
    v := viper.New()
    
    // 设置环境变量前缀和替换规则
    v.SetEnvPrefix("ALBUM")
    v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
    v.AutomaticEnv() // 自动读取环境变量
    
    // 设置配置文件
    if configPath != "" {
        v.SetConfigFile(configPath)
    } else {
        v.SetConfigName("config")
        v.SetConfigType("yaml")
        v.AddConfigPath("./configs")
        v.AddConfigPath(".")
    }
    
    return &Loader{v: v, configPath: configPath}
}

// BindPFlags 绑定命令行参数到 Viper
func (l *Loader) BindPFlags(flags *pflag.FlagSet) {
    l.v.BindPFlags(flags)
}

// Load 加载配置
// 优先级：命令行参数 > 环境变量 > 配置文件 > 默认值
func (l *Loader) Load() (*Config, error) {
    // 1. 先创建完整默认配置
    cfg := l.defaultConfig()
    
    // 2. 读取配置文件（如果存在）
    if err := l.v.ReadInConfig(); err != nil {
        if _, ok := err.(viper.ConfigFileNotFoundError); !ok {
            return nil, fmt.Errorf("read config file: %w", err)
        }
        // 配置文件不存在，直接返回默认配置
        return cfg, nil
    }
    
    // 3. 使用 Viper 的 Unmarshal 自动覆盖存在的字段
    // Viper 只会覆盖配置文件中存在的字段，不存在的字段保持默认值
    if err := l.v.Unmarshal(cfg); err != nil {
        return nil, fmt.Errorf("unmarshal config: %w", err)
    }
    
    // 4. 处理自定义类型（Duration 和 Size）
    // 因为 Viper 可能无法直接处理这些自定义类型，需要手动转换
    if err := l.bindCustomTypes(cfg); err != nil {
        return nil, fmt.Errorf("bind custom types: %w", err)
    }
    
    // 不再验证，让运行时错误自然暴露
    return cfg, nil
}

// bindCustomTypes 处理自定义类型（Duration 和 Size）
// 从 Viper 读取字符串值，然后转换为自定义类型
func (l *Loader) bindCustomTypes(cfg *Config) error {
    // 遍历配置结构体，找到所有 Duration 和 Size 类型的字段
    // 从 Viper 读取对应的字符串值，然后转换
    // 可以使用反射实现，或者手动处理关键字段
    // ... 实现细节
    return nil
}

// defaultConfig 返回完整默认配置
func (l *Loader) defaultConfig() *Config {
    return &Config{
        Server: &server.Config{
            Host:          "0.0.0.0",
            Port:          8080,
            PublicBaseURL: "http://10.168.1.161:8080",
        },
        Database: &database.Config{
            Type: "postgres",
            DSN:  "host=127.0.0.1 user=album password=album@2025 dbname=album port=15432 sslmode=disable TimeZone=Asia/Shanghai",
        },
        // ... 其他默认配置
        Changelog: changelog.DefaultConfig(),
        Queue:     gq.DefaultServerConfig(),
        Media:     mediaprocessor.DefaultConfig(),
    }
}
```

**关键优势**：
- **无需手动合并**：Viper 自动处理配置合并，只需先设置默认值，然后 Unmarshal
- **自动环境变量支持**：通过 `AutomaticEnv()` 和 `SetEnvKeyReplacer` 自动读取环境变量
- **支持嵌套结构**：环境变量 `ALBUM_STORAGE_PRIMARY_LOCAL_BASE_PATH` 自动映射到 `storage.primary.local.base_path`

### 10.3.3 命令行参数支持

使用 [Pflag](https://github.com/spf13/pflag) 定义命令行参数，与 Viper 无缝集成。

```go
// internal/config/flags.go
package config

import (
    "github.com/spf13/pflag"
)

// AddFlags 添加命令行参数到 FlagSet
func AddFlags(flags *pflag.FlagSet) {
    // 配置文件路径
    flags.StringP("config", "c", "configs/config.yaml", "配置文件路径")
    
    // 服务器配置
    flags.String("server.host", "", "服务器主机地址")
    flags.Int("server.port", 0, "服务器端口")
    flags.String("server.public_base_url", "", "服务器公共基础URL")
    
    // 数据库配置
    flags.String("database.type", "", "数据库类型")
    flags.String("database.dsn", "", "数据库连接字符串")
    
    // 存储配置（只添加最常用的）
    flags.String("storage.primary.type", "", "主存储类型")
    flags.String("storage.primary.local.base_path", "", "本地存储基础路径")
    
    // 认证配置
    flags.String("auth.jwt_secret", "", "JWT 密钥")
    flags.String("auth.access_token_expires_in", "", "访问令牌过期时间")
    
    // 日志配置
    flags.String("logger.level", "", "日志级别")
    flags.String("logger.format", "", "日志格式")
    flags.String("logger.output", "", "日志输出")
}
```

**使用示例**：
```bash
# 使用命令行参数
./server --config configs/prod.yaml --server.port 9090

# 组合使用（命令行参数优先级最高）
ALBUM_SERVER_PORT=8080 ./server --server.port 9090
# 最终 port = 9090（命令行参数覆盖环境变量）
```

### 10.3.4 自定义类型

配置模块提供了自定义类型，支持 YAML 中的友好格式：

**Duration 类型**：支持 `"30m"`, `"24h"`, `"5m"` 等格式
```go
// internal/config/types/types.go
package types

import (
    "fmt"
    "time"
)

type Duration time.Duration

func (d *Duration) UnmarshalYAML(unmarshal func(interface{}) error) error {
    var s string
    if err := unmarshal(&s); err != nil {
        return err
    }
    dur, err := time.ParseDuration(s)
    if err != nil {
        return fmt.Errorf("invalid duration format: %s", s)
    }
    *d = Duration(dur)
    return nil
}

func (d Duration) Duration() time.Duration {
    return time.Duration(d)
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

func (s Size) Int64() int64 {
    return int64(s)
}
```

**注意**：这些自定义类型需要特殊处理，因为 Viper 可能无法直接 Unmarshal。需要在 `bindCustomTypes` 中手动转换。

### 10.3.5 配置验证策略

**设计决策**：移除启动时配置验证，让运行时错误自然暴露。

**理由**：
1. **更直观**：运行时错误（如数据库连接失败）比验证错误更清晰
2. **减少维护成本**：无需维护大量验证逻辑
3. **更灵活**：允许部分配置为空，由业务逻辑决定是否必需
4. **Viper 已提供基本检查**：类型检查由 Viper 自动完成

**示例**：
```go
// 不再需要这样的验证代码
func (c *Config) Validate() error {
    if c.Server.Port <= 0 {
        return fmt.Errorf("port must be > 0")
    }
    // ...
}

// 运行时错误更清晰
// 如果端口无效，服务器启动时会直接报错：
// "listen tcp :invalid: bind: invalid argument"
```

### 10.3.6 配置注入优化

**原则**：各服务只接收自己需要的配置块，服务内部处理 nil 配置。

**优势**：
1. **职责清晰**：Builder 只负责传递配置，不处理配置细节
2. **易于测试**：服务可独立测试，不依赖 Builder
3. **减少耦合**：Builder 不需要了解配置的内部结构

**示例**：

```go
// internal/app/builder.go

// BuildMediaProcessor 构建媒体处理器
func (b *Builder) BuildMediaProcessor() error {
    // 直接传递配置，不需要合并
    processor, err := mediaprocessor.NewProcessor(b.cfg.Media)
    if err != nil {
        return fmt.Errorf("create media processor: %w", err)
    }
    
    b.app.MediaProcessor = processor
    // 保存实际使用的配置
    if b.cfg.Media != nil {
        b.app.MediaProcessorConfig = b.cfg.Media
    } else {
        b.app.MediaProcessorConfig = mediaprocessor.DefaultConfig()
    }
    return nil
}

// BuildTaskQueue 构建任务队列
func (b *Builder) BuildTaskQueue() error {
    if b.app.DB == nil {
        return fmt.Errorf("database is required")
    }
    
    b.app.TaskQueueClient = gq.NewClient(b.app.DB)
    // 直接传递配置，服务内部处理 nil
    b.app.TaskQueueServer = gq.NewServer(b.app.DB, b.cfg.Queue)
    return nil
}

// 删除 mergeMediaConfig 函数（不再需要！）
```

**服务内部处理 nil**：

```go
// pkg/media-processor/processor.go
func NewProcessor(cfg *Config) (*Processor, error) {
    // 如果配置为 nil，使用默认值
    if cfg == nil {
        cfg = DefaultConfig()
    }
    
    // 直接使用配置，Viper 已经处理了合并
    // ... 初始化逻辑
}

// pkg/gq/server.go
func NewServer(db *gorm.DB, cfg *ServerConfig) *Server {
    // 如果配置为 nil，使用默认值
    if cfg == nil {
        cfg = DefaultServerConfig()
    }
    
    // ... 初始化逻辑
}
```

### 10.3.7 与 Builder 模式集成

配置加载后直接用于依赖注入构建：

```go
// cmd/server/main.go
package main

import (
    "github.com/spf13/pflag"
    "github.com/album/backend/internal/config"
    // ...
)

func main() {
    // 1. 定义命令行参数
    flags := pflag.NewFlagSet("server", pflag.ExitOnError)
    config.AddFlags(flags)
    flags.Parse(os.Args[1:])
    
    // 2. 加载配置
    configPath, _ := flags.GetString("config")
    loader := config.NewLoader(configPath)
    loader.BindPFlags(flags) // 绑定命令行参数
    
    cfg, err := loader.Load()
    if err != nil {
        log.Fatalf("Could not load config: %v", err)
    }
    
    // 3. 构建应用（使用 Builder 模式）
    builder := app.NewBuilder(cfg)
    if err := builder.BuildAll(); err != nil {
        log.Fatalf("Failed to build app: %v", err)
    }
    defer logger.Sync()
    
    app := builder.Build()
    
    // 4. 启动服务
    // ...
}
```

## 10.4 配置加载优先级

配置加载遵循以下优先级（从高到低）：

```
命令行参数 > 环境变量 > 配置文件 > 默认值
```

**工作流程**：
1. 创建完整默认配置（所有字段都有值）
2. 读取配置文件（如果存在），Viper 自动覆盖存在的字段
3. 读取环境变量（如果存在），Viper 自动覆盖存在的字段
4. 读取命令行参数（如果存在），Viper 自动覆盖存在的字段
5. 最终配置传递给服务

**示例**：
```bash
# 方式1：使用配置文件
./server --config configs/config.yaml

# 方式2：使用环境变量
ALBUM_SERVER_PORT=9090 ./server

# 方式3：使用命令行参数
./server --server.port 9090

# 方式4：组合使用（命令行参数优先级最高）
ALBUM_SERVER_PORT=8080 ./server --server.port 9090
# 最终 port = 9090（命令行参数覆盖环境变量）
```

## 10.5 配置文件结构

配置文件使用 YAML 格式，结构清晰，支持嵌套：

```yaml
# configs/config.yaml
server:
  host: 0.0.0.0
  port: 8080
  public_base_url: http://10.168.1.161:8080

database:
  type: postgres
  dsn: host=127.0.0.1 user=album password=album@2025 dbname=album port=15432 sslmode=disable TimeZone=Asia/Shanghai

storage:
  primary:
    type: local
    local:
      base_path: ./base
      pool_manager:
        delta_channel_size: 1024
        delta_batch_size: 128
        flush_interval: 2s
        cache_refresh_interval: 5m0s
        reconcile_interval: 0s
      temp:
        base_path: ./data/temp
        max_age: 24h0m0s
        max_size: 10.00GB
        cleanup_interval: 1h0m0s
      processing:
        enable_compression: false
        compression_level: 6
        enable_encryption: false
        encryption_key_path: ""
      performance:
        cache_enabled: false
        cache_size: 100.00MB
        cache_ttl: 24h0m0s
        read_buffer_size: 64.00KB
        write_buffer_size: 64.00KB

auth:
  jwt_secret: 920b2d7afc726e01d92c28ab556ffef552ce650632be1fd7a47476220fda5b72
  access_token_expires_in: 30m0s
  refresh_token_expires_in: 720h0m0s
  apple_app_bundle_id: ""
  avatar_save_path: ./data/public/avatars
  max_avatar_size: 5.00MB
  url_signer_secret: 400c2793c98192b46fbda4102c83db9e4c6246d953f7d1827bfeceba9d939c9e
  signed_url_load_ttl: 30m0s

api:
  max_file_size: 100.00MB

logger:
  level: debug
  format: console
  output: stdout

changelog:
  enabled: true
  cleanup_interval: 24h0m0s
  device_active_threshold: 5m0s
  default_changelog_page_limit: 50
  full_changelog_tables: {}

queue:
  concurrency: 10
  minpollintervalms: 100
  maxpollintervalms: 5000

media:
  defaultimagespecs:
    - name: thumbnail
      max_width: 400
      max_height: 400
      quality: 75
      format: jpg
      crop: true
  concurrency: 4
  imagick:
    poolsize: 10
    memorylimit: 2GB
    disklimit: 10GB
  ffmpeg:
    binarypath: /usr/bin/ffmpeg
    probepath: /usr/bin/ffprobe
    maxconcurrency: 4
    processtimeout: 10m0s
    thumbnailoffset: 1.5
```

## 10.6 环境变量支持

配置可以通过环境变量覆盖，优先级：**命令行参数 > 环境变量 > 配置文件 > 默认值**

环境变量统一使用 `ALBUM_` 前缀，嵌套结构使用下划线分隔。

### 10.6.1 环境变量命名规则

- 前缀：`ALBUM_`
- 分隔符：嵌套结构使用下划线 `_` 替代点号 `.`
- 示例：`storage.primary.local.base_path` → `ALBUM_STORAGE_PRIMARY_LOCAL_BASE_PATH`

### 10.6.2 常用环境变量

#### 服务器配置
- `ALBUM_SERVER_HOST`: 服务器主机地址
- `ALBUM_SERVER_PORT`: 服务器端口
- `ALBUM_SERVER_PUBLIC_BASE_URL`: 公共基础URL

#### 数据库配置
- `ALBUM_DATABASE_TYPE`: 数据库类型
- `ALBUM_DATABASE_DSN`: 数据库连接字符串

#### 存储配置
- `ALBUM_STORAGE_PRIMARY_TYPE`: 主存储类型
- `ALBUM_STORAGE_PRIMARY_LOCAL_BASE_PATH`: 本地存储基础路径
- `ALBUM_STORAGE_PRIMARY_LOCAL_TEMP_BASE_PATH`: 临时文件基础路径
- `ALBUM_STORAGE_PRIMARY_LOCAL_TEMP_MAX_AGE`: 临时文件最大存活时间
- `ALBUM_STORAGE_PRIMARY_LOCAL_TEMP_MAX_SIZE`: 临时文件最大大小

#### 认证配置
- `ALBUM_AUTH_JWT_SECRET`: JWT 密钥
- `ALBUM_AUTH_ACCESS_TOKEN_EXPIRES_IN`: 访问令牌过期时间
- `ALBUM_AUTH_REFRESH_TOKEN_EXPIRES_IN`: 刷新令牌过期时间

#### 日志配置
- `ALBUM_LOGGER_LEVEL`: 日志级别（debug, info, warn, error）
- `ALBUM_LOGGER_FORMAT`: 日志格式（json, console）
- `ALBUM_LOGGER_OUTPUT`: 输出目标（stdout, stderr, 或文件路径）

#### 队列配置
- `ALBUM_QUEUE_CONCURRENCY`: 并发处理数量
- `ALBUM_QUEUE_MIN_POLL_INTERVAL_MS`: 最小轮询间隔（毫秒）
- `ALBUM_QUEUE_MAX_POLL_INTERVAL_MS`: 最大轮询间隔（毫秒）

#### Changelog 配置
- `ALBUM_CHANGELOG_ENABLED`: 是否启用（true/false）
- `ALBUM_CHANGELOG_CLEANUP_INTERVAL`: 清理周期（如 24h）
- `ALBUM_CHANGELOG_DEVICE_ACTIVE_THRESHOLD`: 设备活跃阈值（如 5m0s）
- `ALBUM_CHANGELOG_DEFAULT_PAGE_LIMIT`: 默认分页大小

### 10.6.3 使用示例

```bash
# 通过环境变量覆盖配置
export ALBUM_SERVER_PORT=9090
export ALBUM_DATABASE_DSN="host=prod-db.example.com user=album password=secret dbname=album"
export ALBUM_LOGGER_LEVEL=warn
export ALBUM_STORAGE_PRIMARY_LOCAL_BASE_PATH="/data/uploads"

# 运行服务
./server

# 或者一行设置
ALBUM_SERVER_PORT=9090 ALBUM_LOGGER_LEVEL=warn ./server

# 组合使用（命令行参数优先级最高）
ALBUM_SERVER_PORT=8080 ./server --server.port 9090
# 最终 port = 9090
```

## 10.7 重构优势总结

### 10.7.1 代码简化

**删除的代码**：
- `overrideWithEnv` 方法：~300 行（环境变量覆盖逻辑）
- 所有 `Validate` 方法：~200 行（配置验证逻辑）
- `mergeMediaConfig` 函数：~60 行（配置合并逻辑）
- `validator.go` 文件：~30 行
- **总计：约 590 行代码**

**新增的代码**：
- 新的 `loader.go`：~200 行（使用 Viper）
- `flags.go`：~50 行（命令行参数定义）
- 服务内部 nil 处理：~30 行
- **总计：约 280 行代码**

**净减少**：约 310 行代码

### 10.7.2 功能增强

1. **命令行参数支持**：通过 Pflag 支持命令行参数
2. **自动环境变量**：Viper 自动读取环境变量，无需手动处理
3. **自动配置合并**：Viper 自动处理配置合并，无需手动逻辑
4. **多种配置格式**：支持 YAML、JSON、TOML 等多种格式

### 10.7.3 维护性提升

1. **更易扩展**：新增配置项只需在结构体中添加字段，无需修改加载逻辑
2. **职责清晰**：配置加载、服务初始化各司其职
3. **更易测试**：各组件可独立测试
4. **使用成熟库**：基于 Viper 和 Pflag，社区支持好

## 10.8 迁移指南

### 10.8.1 依赖添加

```bash
go get github.com/spf13/viper
go get github.com/spf13/pflag
```

### 10.8.2 代码变更

1. **重命名 modules → types**
   - 移动文件：`internal/config/modules/types.go` → `internal/config/types/types.go`
   - 更新包名：`package modules` → `package types`
   - 更新所有导入路径

2. **删除验证代码**
   - 删除所有 `Validate()` 方法
   - 删除 `internal/config/validator.go`

3. **删除配置合并逻辑**
   - 删除 `mergeMediaConfig` 函数
   - 简化 Builder 中的配置处理

4. **更新服务构造函数**
   - 添加 nil 配置处理
   - 使用默认配置

### 10.8.3 向后兼容

- 配置文件格式保持不变
- 环境变量命名规则保持不变
- 配置结构体定义保持不变

## 10.9 最佳实践

1. **使用默认值**：在 `defaultConfig()` 中提供完整的默认配置
2. **服务处理 nil**：服务构造函数应处理 nil 配置，使用默认值
3. **避免手动合并**：让 Viper 自动处理配置合并
4. **自定义类型处理**：在 `bindCustomTypes` 中处理 Duration 和 Size
5. **运行时验证**：让运行时错误自然暴露，而不是启动时验证

## 10.10 参考资源

- [Viper 文档](https://github.com/spf13/viper)
- [Pflag 文档](https://github.com/spf13/pflag)
- [Go 配置管理最佳实践](https://github.com/golang-standards/project-layout)
