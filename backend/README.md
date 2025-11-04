# Album Backend

## 简介

Album Backend 是一个基于 Go 语言开发的照片和视频管理后端服务。本项目包含：

- **Go-Gorm-Queue (GQ)**：一个基于 GORM 和关系型数据库的分布式任务队列框架，参考了 Asynq 的设计思路
- **完整的后端服务**：提供用户认证、媒体管理、相册管理、圈子分享等功能的完整后端服务

## 文档

- [架构设计文档](./doc/ARCHITECTURE/README.md) - 完整的架构设计说明
- [GQ 任务队列框架文档](./pkg/gq/README.md) - 任务队列框架详细文档

## 快速开始

### 1. 安装依赖

```bash
cd backend
go mod tidy
```

### 2. 运行服务

```bash
go run cmd/server/main.go
```

## 项目结构

```
backend/
├── cmd/                    # 应用入口点
│   ├── server/            # HTTP API 服务器
│   └── cli/               # 命令行工具
│
├── internal/              # 内部包（不对外暴露）
│   ├── api/               # API 层（HTTP handlers）
│   ├── service/          # 业务逻辑层
│   ├── repository/       # 数据访问层
│   ├── worker/           # 后台任务处理
│   ├── storage/          # 存储抽象层
│   ├── app/              # 应用组装（依赖注入）
│   ├── config/           # 配置管理
│   ├── database/         # 数据库相关
│   └── version/          # 版本信息
│
├── pkg/                   # 可对外暴露的公共包
│   ├── gq/               # 任务队列框架
│   ├── logger/           # 日志工具
│   ├── validator/        # 验证工具
│   └── utils/            # 工具函数
│
├── configs/              # 配置文件
├── deployments/          # 部署相关
├── scripts/              # 脚本文件
├── doc/                  # 文档
│   └── ARCHITECTURE/     # 架构设计文档
└── README.md
```

## 核心特性

- ✅ 基于关系型数据库（MySQL/PostgreSQL/SQLite）
- ✅ 分层架构（API → Service → Repository → Database）
- ✅ 依赖注入（手动依赖注入）
- ✅ 任务队列（GQ 框架，支持异步任务处理）
- ✅ 存储抽象（支持本地存储、S3、OSS、COS）
- ✅ 容器化部署（Docker 和 docker-compose）
- ✅ 版本管理（构建时注入版本信息）

## 技术栈

- **语言**：Go 1.24+
- **Web 框架**：Gin
- **ORM**：GORM
- **任务队列**：自研 GQ (Go-Gorm-Queue)
- **数据库**：PostgreSQL / SQLite
- **容器化**：Docker, docker-compose
- **命令行工具**：Cobra

## 开发

### 本地开发

```bash
# 1. 启动数据库
docker-compose -f deployments/docker/docker-compose.yml up -d postgres

# 2. 运行服务
go run cmd/server/main.go
```

### 构建

```bash
# 构建
make build VERSION=v1.0.0

# 构建 Docker 镜像
make docker-build VERSION=v1.0.0
```

## 许可证

[待添加]
