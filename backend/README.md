# Album Backend

Album Backend 是一个基于 Go 语言开发的照片和视频管理后端服务。本项目包含：

- **Go-Gorm-Queue (GQ)**：基于 GORM 和关系型数据库的分布式任务队列框架
- **完整的后端服务**：提供用户认证、媒体管理、相册管理、圈子分享等功能的完整后端服务

## ✨ 核心特性

- ✅ 基于关系型数据库（MySQL/PostgreSQL/SQLite）
- ✅ 分层架构（API → Service → Repository → Database）
- ✅ 依赖注入（手动依赖注入）
- ✅ 任务队列（GQ 框架，支持异步任务处理）
- ✅ 存储抽象（支持本地存储、S3、OSS、COS）
- ✅ 容器化部署（Docker 和 docker-compose）
- ✅ 版本管理（构建时注入版本信息）

## 🚀 快速开始

### 方式一：容器化部署（推荐）

一键部署，所有配置都有默认值：

```bash
cd backend
./deploy.sh
```

详细说明请参考：[快速部署指南](./README_DEPLOY.md)

### 方式二：本地开发

#### 前置要求

- Go 1.24+
- Docker & docker-compose（可选，用于本地数据库）

#### 安装依赖

```bash
cd backend
go mod tidy
```

#### 运行服务

```bash
# 1. 启动数据库（可选）
docker-compose -f deployments/docker/docker-compose.yml up -d postgres

# 2. 运行服务
go run cmd/server/main.go
```

## 📚 文档

完整的文档索引请查看 [文档中心](./doc/INDEX.md)。

### 主要文档

- 📖 [文档索引](./doc/INDEX.md) - 所有文档的入口
- 🚀 [快速部署指南](./README_DEPLOY.md) - 容器化一键部署
- 🏗️ [架构设计文档](./doc/ARCHITECTURE/README.md) - 完整的架构设计说明
- 📦 [GQ 任务队列框架](./pkg/gq/README.md) - 任务队列框架详细文档
- 📝 [Logger 日志模块](./pkg/logger/README.md) - 结构化日志库文档
- 📋 [完整部署文档](./deploy/README.md) - 详细的容器化部署说明

## 🛠️ 技术栈

- **语言**：Go 1.24+
- **Web 框架**：Gin
- **ORM**：GORM
- **任务队列**：自研 GQ (Go-Gorm-Queue)
- **数据库**：PostgreSQL / SQLite
- **容器化**：Docker, docker-compose
- **命令行工具**：Cobra

## 🏗️ 构建

```bash
# 构建
make build VERSION=v1.0.0

# 构建 Docker 镜像
make docker-build VERSION=v1.0.0
```
