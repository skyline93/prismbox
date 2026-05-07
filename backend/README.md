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

### 方式一：远程一键安装（无需克隆仓库）

在已安装 **Docker** 与 **Docker Compose** 的机器上执行（默认从 [GitHub prismbox](https://github.com/skyline93/prismbox) 下载 compose 与部署脚本，再由 Docker 拉取 `docker-compose.yaml` 中的后端与 Nginx 镜像）：

```bash
curl -fsSL https://raw.githubusercontent.com/skyline93/prismbox/main/backend/scripts/install.sh | sh
```

可选：固定版本、自定义目录、`--yes` 非交互、`--https` 启用 HTTPS profile 等：

```bash
curl -fsSL https://raw.githubusercontent.com/skyline93/prismbox/main/backend/scripts/install.sh | sh -s -- --dir ~/prismbox-backend --yes
```

若需从其他托管拉取脚本与 compose（例如镜像站），可在管道前设置 `PRISMBOX_GIT_HOST` 与 `PRISMBOX_REPO`。其余变量见 `scripts/install.sh` 头部注释。

### 方式二：容器化部署（克隆仓库）

一键部署，所有配置都有默认值：

```bash
cd backend
./deploy.sh
```

详细说明请参考：[部署文档](./doc/DEPLOYMENT/README.md)

### 方式三：本地开发

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

#### 开发环境（Docker Compose，与生产隔离）

使用开发专用 compose，在容器内挂载源码，进入 shell 后可直接 `go run`，无需构建镜像。开发镜像（`deploy/Dockerfile.dev`）基于 base 并带 **Oh My Zsh** 与 gosu，命令行更友好；**Go 模块缓存**通过命名卷 `go-mod-dev` 持久化，容器销毁后重建不会重新下载依赖。依赖服务（PostgreSQL、Nginx、Certbot）与生产配置一致，数据存放在独立目录 `deploy/data-dev`，与生产 `deploy/data` 隔离。

1. **（可选）构建开发镜像**（首次或 base 更新后，否则 dev-up 时会自动 build）  
   `make docker-build-base` 再 `make docker-build-dev`

2. **初始化开发数据目录**（首次或清理后）  
   `make dev-init`

3. **启动开发环境**（PostgreSQL、album-backend 开发容器、Nginx、可选 Certbot）  
   `make dev-up`

4. **进入容器并在项目根目录使用 zsh（Oh My Zsh）**  
   `make terminal`  
   进入后当前目录为项目根，可执行：
   - `go mod download` 或 `go mod tidy`
   - `go run ./cmd/server` 或 `make build && ./bin/album-server`
   - 首次可生成配置：`./bin/album-cli --config /app/deploy/data-dev/configs/config.yaml init config ...`（需先 `make build`）

5. **挂载目录权限**  
   若容器内对 `/app` 无写权限，在宿主机设置环境变量后重启开发 compose：  
   `export UID GID`（Linux/macOS 通常已设置）  
   开发 compose 会传入 `DEV_UID`/`DEV_GID`，容器启动时会据此 chown `/app` 与 `/home/app`（Go 缓存），保证可写。Windows 下可使用默认 1000:1000。

6. **停止与查看**  
   `make dev-down` 停止；`make dev-logs`、`make dev-ps` 查看日志与状态。

## 📚 文档

完整的文档索引请查看 [文档中心](./doc/INDEX.md)。

### 主要文档

- 📖 [文档索引](./doc/INDEX.md) - 所有文档的入口
- 🚀 [部署文档](./doc/DEPLOYMENT/README.md) - 完整的容器化部署指南
- 🏗️ [架构设计文档](./doc/ARCHITECTURE/README.md) - 完整的架构设计说明
- 📦 [GQ 任务队列框架](./pkg/gq/README.md) - 任务队列框架详细文档
- 📝 [Logger 日志模块](./pkg/logger/README.md) - 结构化日志库文档

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
