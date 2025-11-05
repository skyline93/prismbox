# 2. 目录结构

```
backend/
├── cmd/                    # 应用入口点
│   ├── server/            # HTTP API 服务器
│   │   └── main.go
│   └── cli/               # 命令行工具
│       └── main.go
│
├── internal/              # 内部包（不对外暴露）
│   ├── api/               # API 层（HTTP handlers）
│   │   ├── v1/           # API v1 版本
│   │   │   ├── auth/     # 认证相关
│   │   │   ├── media/    # 媒体相关
│   │   │   ├── album/    # 相册相关
│   │   │   ├── group/    # 圈子相关
│   │   │   ├── share/    # 分享相关
│   │   │   └── version/  # 版本信息
│   │   └── middleware/   # 中间件
│   │
│   ├── service/          # 业务逻辑层（核心）
│   │   ├── auth/         # 认证服务
│   │   ├── media/        # 媒体服务
│   │   │   ├── service.go    # 服务接口和实现
│   │   │   ├── processor.go  # 媒体处理逻辑
│   │   │   └── storage.go    # 存储相关逻辑
│   │   ├── album/        # 相册服务
│   │   ├── group/        # 圈子服务
│   │   ├── share/        # 分享服务
│   │   └── sync/         # 同步服务
│   │
│   ├── repository/       # 数据访问层
│   │   ├── interfaces.go # 仓储接口定义
│   │   ├── user.go
│   │   ├── media.go
│   │   ├── album.go
│   │   ├── group.go
│   │   └── share.go
│   │
│   ├── worker/           # 后台任务处理
│   │   ├── media/        # 媒体处理任务
│   │   │   ├── processor.go    # 图片/视频处理
│   │   │   └── uploader.go     # 云端上传（已废弃，由备份调度器处理）
│   │   ├── backup/       # 备份任务处理
│   │   │   └── upload.go # 备份上传处理器
│   │   └── handler.go   # 任务处理器注册
│   │
│   ├── storage/          # 存储抽象层
│   │   ├── interfaces.go # 存储接口定义（PrimaryStorage, SecondaryStorage）
│   │   ├── manager.go    # 存储管理器（只管理主存储）
│   │   ├── factory.go    # 存储工厂（根据配置创建主存储和次存储）
│   │   ├── primary/      # 主存储实现
│   │   │   └── local/    # 本地文件系统存储
│   │   │       ├── storage.go
│   │   │       ├── path_resolver.go
│   │   │       ├── pool_manager.go
│   │   │       └── cache.go
│   │   └── secondary/    # 次存储实现
│   │       ├── openlist/ # OpenList/AList 对接
│   │       │   ├── client.go
│   │       │   ├── storage.go
│   │       │   ├── adapter.go
│   │       │   └── pool_manager.go
│   │       ├── s3/       # AWS S3 直接对接（可选）
│   │       ├── oss/      # 阿里云 OSS 直接对接（可选）
│   │       └── cos/      # 腾讯云 COS 直接对接（可选）
│   │
│   ├── backup/           # 备份调度器
│   │   ├── scheduler.go # 备份调度器
│   │   ├── monitor.go   # 系统监控器
│   │   ├── handler.go   # 备份任务处理器
│   │   └── config.go    # 备份配置
│   │
│   ├── app/              # 应用组装（依赖注入）
│   │   ├── app.go        # 应用主结构体
│   │   └── builder.go    # 依赖注入构建器
│   │
│   ├── config/           # 配置管理
│   │   ├── config.go     # 主配置结构体
│   │   ├── loader.go     # 配置加载器（YAML + 环境变量）
│   │   ├── validator.go  # 配置验证器
│   │   ├── types.go      # 自定义类型（Duration, Size 等）
│   │   └── modules/      # 各模块配置
│   │       ├── server.go
│   │       ├── database.go
│   │       ├── storage.go
│   │       ├── backup.go
│   │       ├── queue.go
│   │       ├── auth.go
│   │       ├── media.go
│   │       └── logger.go
│   │
│   ├── database/         # 数据库相关
│   │   ├── migrations/   # 数据库迁移
│   │   └── connection.go
│   │
│   └── version/          # 版本信息
│       └── version.go
│
├── pkg/                   # 可对外暴露的公共包
│   ├── gq/               # 任务队列框架
│   ├── media-processor/   # 媒体处理包（独立包，可复用）
│   │   ├── processor.go  # 主处理器接口和工厂
│   │   ├── config.go      # 配置结构
│   │   ├── types.go       # 类型定义
│   │   ├── errors.go      # 错误定义
│   │   ├── image/         # 图片处理模块
│   │   │   ├── processor.go
│   │   │   ├── imagick.go  # ImageMagick 实现
│   │   │   ├── manager.go # ImageMagick 生命周期管理
│   │   │   ├── raw.go      # RAW 文件处理
│   │   │   ├── metadata.go # 元数据提取
│   │   │   └── spec.go     # 规格定义
│   │   ├── video/         # 视频处理模块
│   │   │   ├── processor.go
│   │   │   ├── ffmpeg.go   # FFmpeg 实现
│   │   │   ├── metadata.go # 元数据提取
│   │   │   └── spec.go     # 规格定义
│   │   └── internal/      # 内部工具（不对外暴露）
│   │       ├── pool/       # 资源池管理
│   │       └── utils/      # 工具函数
│   ├── logger/           # 日志工具（独立包，可复用）
│   │   ├── core.go           # 全局配置管理（单例）
│   │   ├── logger.go         # Logger 接口和实现
│   │   ├── config.go         # 配置结构定义
│   │   ├── fields.go         # 字段构建器
│   │   ├── formatter.go      # 格式化器接口
│   │   ├── formatter_json.go # JSON 格式化器
│   │   ├── formatter_console.go # 控制台格式化器
│   │   ├── writer.go         # 写入器接口
│   │   ├── writer_shared.go  # 共享写入器实现（线程安全）
│   │   ├── writer_file.go    # 文件写入器实现（带轮转）
│   │   ├── writer_console.go # 控制台写入器实现
│   │   ├── level.go          # 日志级别定义
│   │   └── middleware.go     # Gin 中间件
│   ├── validator/        # 验证工具
│   └── utils/            # 工具函数
│
├── configs/              # 配置文件
│   ├── config.yaml
│   └── config.dev.yaml
│
├── deployments/          # 部署相关
│   ├── docker/
│   │   ├── Dockerfile
│   │   ├── Dockerfile.dev
│   │   └── docker-compose.yml
│   └── k8s/              # Kubernetes 配置（可选）
│
├── scripts/              # 脚本文件
│   ├── build.sh          # 构建脚本（注入版本）
│   └── migration.sh
│
├── Makefile              # 构建和部署命令
├── .dockerignore
└── VERSION               # 版本文件（可选）
```

