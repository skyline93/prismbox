# Album Backend 部署文档

## 📋 目录

- [概述](#概述)
- [快速开始](#快速开始)
- [前置要求](#前置要求)
- [一键部署](#一键部署)
- [环境变量配置](#环境变量配置)
- [首次部署](#首次部署)
- [构建镜像](#构建镜像)
- [生产环境部署](#生产环境部署)
- [部署服务](#部署服务)
- [配置说明](#配置说明)
- [故障排查](#故障排查)

## 概述

本项目提供了完整的容器化部署方案，包括：

- **Album Backend**: Go 语言编写的后端 API 服务
- **PostgreSQL**: 数据库服务
- **Nginx**: 反向代理服务器，处理 CORS、大文件上传下载等

### 架构说明

```
┌─────────────────┐
│   Nginx (80/443)│  ← 反向代理、CORS、大文件处理
└────────┬────────┘
         │ /api → proxy_pass
         ▼
┌─────────────────┐
│ Album Backend   │  ← Go API服务 (8080)
│ (Go + Gin)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  PostgreSQL     │  ← 数据库 (5432)
└─────────────────┘
```

## 快速开始

### 方式一：一键部署（推荐）

在 `backend` 根目录下执行：

```bash
cd backend
./deploy.sh
```

脚本会自动：
- 检测系统架构（AMD64/ARM64）
- 初始化必要的目录
- 构建并启动所有服务
- 注入版本信息

**首次部署需要设置管理员信息**：
```bash
export ALBUM_INIT_ADMIN_EMAIL=admin@example.com
export ALBUM_INIT_ADMIN_PASSWORD=your-password
./deploy.sh
```

### 方式二：手动部署

#### 1. 初始化部署环境

```bash
cd backend
bash deploy/init.sh
```

初始化脚本会：
- 创建必要的目录结构
- 生成 `.env` 环境变量文件模板
- 检查配置文件

#### 2. 配置环境变量

编辑 `.env` 文件，修改必要的配置：

```bash
# 首次部署必须设置
ALBUM_INIT_ADMIN_EMAIL=admin@example.com
ALBUM_INIT_ADMIN_PASSWORD=your-password

# 生产环境请修改
ALBUM_AUTH_JWT_SECRET=your-secret-key-here
ALBUM_AUTH_URL_SIGNER_SECRET=your-signer-secret-here
ALBUM_POSTGRES_PASSWORD=your-database-password

# 服务器地址
ALBUM_SERVER_PUBLIC_BASE_URL=http://your-domain.com
```

#### 3. 启动服务

```bash
docker-compose up -d
```

#### 4. 查看服务状态

```bash
docker-compose ps
docker-compose logs -f album-backend
```

## 前置要求

- Docker 20.10+
- Docker Compose 2.0+
- 至少 2GB 可用内存
- 至少 10GB 可用磁盘空间

## 一键部署

在 `backend` 根目录下执行：

```bash
./deploy.sh
```

就这么简单！脚本会自动：
- 检测系统架构（AMD64/ARM64）
- 初始化必要的目录
- 构建并启动所有服务

### 默认配置

所有配置都有合理的默认值，可以直接使用：

- **数据库**: PostgreSQL，用户名/密码/数据库名均为 `album`
- **服务器**: 监听 `0.0.0.0:8080`
- **Nginx**: HTTP 端口 80，HTTPS 端口 443（默认禁用 HTTPS）
- **文件大小**: 最大 2GB
- **认证密钥**: 使用开发环境默认值（生产环境请修改）

### 自定义配置

如果需要自定义配置，可以：

1. **使用环境变量**（推荐）：
   ```bash
   export ALBUM_POSTGRES_PASSWORD=your-password
   export ALBUM_AUTH_JWT_SECRET=your-secret
   ./deploy.sh
   ```

2. **创建 .env 文件**：
   ```bash
   # 首次运行会自动创建 .env 模板
   ./deploy.sh
   # 然后编辑 .env 文件
   vim .env
   # 再次运行
   ./deploy.sh
   ```

3. **直接修改 docker-compose.yaml**：
   编辑 `docker-compose.yaml` 中的环境变量

### 常用命令

```bash
# 启动服务
./deploy.sh

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f album-backend
docker-compose logs -f nginx

# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新并重启
docker-compose up -d --build
```

### 构建基础镜像（可选）

如果需要构建自定义基础镜像：

```bash
./deploy.sh --build-base
```

### 架构支持

脚本会自动检测系统架构：
- **AMD64/x86_64**: 使用 `linux-amd64` 配置
- **ARM64/aarch64**: 使用 `linux-arm64` 配置

### 目录结构

部署后的目录结构：

```
backend/
├── docker-compose.yaml      # 主编排文件
├── deploy.sh                # 一键部署脚本
├── .env                     # 环境变量配置（可选）
├── configs/                 # 配置文件目录
├── deploy/
│   ├── data/               # 数据目录
│   │   ├── postgresql/     # 数据库数据
│   │   ├── logs/           # 日志文件
│   │   └── cert/           # SSL 证书（如果启用 HTTPS）
│   └── public/             # 静态文件目录
└── ...
```

## 环境变量配置

所有环境变量使用 `ALBUM_` 前缀，防止与系统变量冲突。

### 数据库配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ALBUM_POSTGRES_USER` | PostgreSQL 用户名 | `album` |
| `ALBUM_POSTGRES_PASSWORD` | PostgreSQL 密码 | `album` |
| `ALBUM_POSTGRES_DB` | 数据库名 | `album` |

### 服务器配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ALBUM_SERVER_HOST` | 服务器监听地址 | `0.0.0.0` |
| `ALBUM_SERVER_PORT` | 服务器端口 | `8080` |
| `ALBUM_SERVER_PUBLIC_BASE_URL` | 公共访问地址 | `http://localhost` |

### 认证配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ALBUM_AUTH_JWT_SECRET` | JWT 密钥 | `change-me-in-production` |
| `ALBUM_AUTH_URL_SIGNER_SECRET` | URL 签名密钥 | `change-me-in-production` |
| `ALBUM_AUTH_ACCESS_TOKEN_EXPIRES_IN` | Access Token 过期时间 | `30m` |
| `ALBUM_AUTH_REFRESH_TOKEN_EXPIRES_IN` | Refresh Token 过期时间 | `720h` |

### 媒体配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ALBUM_MEDIA_MAX_FILE_SIZE` | 最大文件大小 | `2GB` |
| `ALBUM_MEDIA_PROCESSOR_IMAGICK_POOL_SIZE` | ImageMagick 池大小 | `10` |
| `ALBUM_MEDIA_PROCESSOR_IMAGICK_MEMORY_LIMIT` | ImageMagick 内存限制 | `2GB` |
| `ALBUM_MEDIA_PROCESSOR_FFMPEG_BINARY_PATH` | FFmpeg 二进制路径 | `/usr/bin/ffmpeg` |

### 日志配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ALBUM_LOGGER_LEVEL` | 日志级别 | `info` |
| `ALBUM_LOGGER_FORMAT` | 日志格式 | `json` |
| `ALBUM_LOGGER_OUTPUT` | 日志输出 | `stdout` |

### Nginx 配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ALBUM_HTTP_PORT` | HTTP 端口 | `80` |
| `ALBUM_HTTPS_PORT` | HTTPS 端口 | `443` |
| `ALBUM_ENABLE_HTTPS` | 是否启用 HTTPS | `false` |
| `ALBUM_NGINX_CLIENT_MAX_BODY_SIZE` | 最大上传文件大小 | `2G` |
| `ALBUM_NGINX_ACCESS_LOG_LEVEL` | 访问日志级别 | `combined` |
| `ALBUM_NGINX_ERROR_LOG_LEVEL` | 错误日志级别 | `warn` |

### 完整环境变量列表

更多环境变量请参考 [环境变量完整列表](./ENV_VARS.md)

## 首次部署

### 一键部署（推荐）

在 `backend` 根目录下：

```bash
# 1. 设置管理员信息（首次部署必须）
export ALBUM_INIT_ADMIN_EMAIL=admin@example.com
export ALBUM_INIT_ADMIN_PASSWORD=your-password

# 2. 一键部署
./deploy.sh
```

### 手动部署步骤

#### 步骤 1: 初始化

```bash
cd backend
bash deploy/init.sh
```

#### 步骤 2: 配置环境变量

编辑 `.env` 文件，设置必要的配置项，特别是：
- `ALBUM_INIT_ADMIN_EMAIL` - 管理员邮箱
- `ALBUM_INIT_ADMIN_PASSWORD` - 管理员密码

#### 步骤 3: 构建基础镜像（可选）

如果使用自定义镜像仓库，需要先构建基础镜像：

```bash
# 在 backend 目录下
./deploy.sh --build-base
```

#### 步骤 4: 启动服务

```bash
# 在 backend 目录下
docker-compose up -d --build
```

#### 步骤 5: 验证部署

```bash
# 检查服务状态
docker-compose ps

# 查看日志
docker-compose logs -f album-backend

# 测试 API
curl http://localhost/api/v1/health
```

### 首次部署初始化

首次部署时，容器会自动执行以下初始化步骤：

1. **生成配置文件** - 如果 `configs/config.yaml` 不存在
2. **执行数据库迁移** - 创建所有必要的数据库表
3. **初始化存储池** - 创建默认的本地存储池
4. **创建管理员账户** - 使用提供的邮箱和密码创建管理员

**首次部署需要设置**：
```bash
export ALBUM_INIT_ADMIN_EMAIL=admin@example.com
export ALBUM_INIT_ADMIN_PASSWORD=your-password
./deploy.sh
```

或者在 `.env` 文件中设置：
```bash
ALBUM_INIT_ADMIN_EMAIL=admin@example.com
ALBUM_INIT_ADMIN_PASSWORD=your-password
```

**注意**：初始化完成后，可以删除这些环境变量，容器会检测到数据库已初始化并跳过初始化步骤。

## 构建镜像

### 构建基础镜像

基础镜像包含 Go、ImageMagick、FFmpeg 等运行时依赖。

```bash
# AMD64
docker build -f deploy/linux-amd64/Dockerfile.base \
    -t registry.cn-shenzhen.aliyuncs.com/greene/album-base:linux-amd64-latest .

# ARM64
docker build -f deploy/linux-arm64/Dockerfile.base \
    -t registry.cn-shenzhen.aliyuncs.com/greene/album-base:linux-arm64-latest .
```

### 构建应用镜像

本项目包含两个应用镜像：
- **album-backend**: 后端 API 服务镜像
- **album-nginx**: Nginx 反向代理镜像（包含配置和脚本）

#### 方式一：使用 Makefile（推荐）

```bash
# 构建所有镜像（backend + nginx）
make docker-build

# 仅构建 backend 镜像
make docker-build-backend

# 仅构建 nginx 镜像
make docker-build-nginx

# 推送所有镜像到 registry
make docker-push

# 仅推送 backend 镜像
make docker-push-backend

# 仅推送 nginx 镜像
make docker-push-nginx
```

#### 方式二：使用 deploy.sh

```bash
# 在 backend 目录下
./deploy.sh
```

脚本会自动：
1. 检测系统架构
2. 获取 Git 版本信息（如果有 `.git` 目录）
3. 注入版本信息到构建参数
4. 构建并启动服务

#### 方式三：手动构建

**构建 Backend 镜像**：

```bash
# 在 backend 目录下
docker build -f deploy/linux-amd64/Dockerfile \
    --build-arg VERSION=v1.0.0 \
    --build-arg BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    --build-arg GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") \
    --build-arg GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown") \
    -t registry.cn-shenzhen.aliyuncs.com/greene/album-backend:latest-amd64 .
```

**构建 Nginx 镜像**：

```bash
# 在 backend 目录下
docker build -f deploy/linux-amd64/Dockerfile.nginx \
    -t registry.cn-shenzhen.aliyuncs.com/greene/album-nginx:latest-amd64 .
```

**镜像标签说明**：

- Backend 镜像：`registry.cn-shenzhen.aliyuncs.com/greene/album-backend:VERSION-ARCH` 和 `latest-ARCH`
- Nginx 镜像：`registry.cn-shenzhen.aliyuncs.com/greene/album-nginx:VERSION-ARCH` 和 `latest-ARCH`

其中：
- `VERSION` 是版本号（如 `v1.0.0` 或 `dev`）
- `ARCH` 是架构（`amd64` 或 `arm64`）

### 版本信息注入

应用在构建时会注入版本信息到二进制文件中，包括：

| 字段 | 说明 | 默认值 |
|------|------|--------|
| `VERSION` | 版本号 | `dev` |
| `BUILD_TIME` | 构建时间 | 自动生成 |
| `GIT_COMMIT` | Git 提交哈希 | `unknown` |
| `GIT_BRANCH` | Git 分支名 | `unknown` |
| `GoVersion` | Go 版本 | 运行时获取 |
| `Platform` | 构建平台 | 运行时获取 |

#### 自动注入（推荐）

使用 `deploy.sh` 脚本时，会自动检测并注入版本信息：

```bash
# 脚本会自动获取以下信息：
# - Version: 从 git describe 获取（如有 tag）
# - BuildTime: 当前 UTC 时间
# - GitCommit: git rev-parse --short HEAD
# - GitBranch: git rev-parse --abbrev-ref HEAD
./deploy.sh
```

脚本会：
1. 自动检测 `.git` 目录
2. 获取 git 版本、提交哈希、分支名
3. 设置构建时间
4. 通过环境变量传递给 Docker 构建

#### 手动注入

如果需要手动指定版本信息，可以设置环境变量：

```bash
export ALBUM_VERSION=v1.0.0
export ALBUM_BUILD_TIME=2025-01-15T10:30:00Z
export ALBUM_GIT_COMMIT=abc1234
export ALBUM_GIT_BRANCH=main
./deploy.sh
```

或者在 `.env` 文件中设置：

```bash
ALBUM_VERSION=v1.0.0
ALBUM_BUILD_TIME=2025-01-15T10:30:00Z
ALBUM_GIT_COMMIT=abc1234
ALBUM_GIT_BRANCH=main
```

#### 在 CI/CD 中注入

在 CI/CD 环境中，可以通过环境变量注入版本信息：

**GitHub Actions 示例**：

```yaml
- name: Set version info
  run: |
    export ALBUM_VERSION=${GITHUB_REF#refs/tags/}
    export ALBUM_GIT_COMMIT=${GITHUB_SHA:0:7}
    export ALBUM_GIT_BRANCH=${GITHUB_REF#refs/heads/}
    export ALBUM_BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "ALBUM_VERSION=$ALBUM_VERSION" >> $GITHUB_ENV
    echo "ALBUM_GIT_COMMIT=$ALBUM_GIT_COMMIT" >> $GITHUB_ENV
    echo "ALBUM_GIT_BRANCH=$ALBUM_GIT_BRANCH" >> $GITHUB_ENV
    echo "ALBUM_BUILD_TIME=$ALBUM_BUILD_TIME" >> $GITHUB_ENV

- name: Build and deploy
  run: |
    ./deploy.sh
```

**GitLab CI 示例**：

```yaml
build:
  variables:
    ALBUM_VERSION: $CI_COMMIT_TAG
    ALBUM_GIT_COMMIT: ${CI_COMMIT_SHA:0:7}
    ALBUM_GIT_BRANCH: $CI_COMMIT_REF_NAME
    ALBUM_BUILD_TIME: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
  script:
    - ./deploy.sh
```

#### 查看版本信息

构建完成后，可以通过 API 查询版本信息：

```bash
# 查询版本信息
curl http://localhost/api/v1/version

# 返回示例
{
  "version": "v1.0.0",
  "build_time": "2025-01-15T10:30:00Z",
  "git_commit": "abc1234",
  "git_branch": "main",
  "go_version": "go1.23.6",
  "platform": "linux/arm64"
}
```

**注意**：
- 如果没有 `.git` 目录或无法获取 git 信息，`git_commit` 和 `git_branch` 会显示为 `unknown`
- 构建时间始终会自动生成，即使未手动指定
- 版本信息在构建时注入到二进制文件中，运行时无法修改

## 生产环境部署

### 前置条件

生产环境部署使用已构建并推送到镜像仓库的镜像，只需要：

1. ✅ `docker-compose.yaml` 文件
2. ✅ `.env` 环境变量配置文件
3. ✅ 创建必要的目录

**不需要**：
- ❌ Makefile
- ❌ Dockerfile
- ❌ 源代码
- ❌ 构建工具

### 部署步骤

#### 1. 准备环境

确保已安装：
- Docker 20.10+
- Docker Compose 2.0+

#### 2. 创建必要目录

在 `backend` 目录下执行：

```bash
cd backend

# 创建所有必需目录
mkdir -p deploy/data/postgresql \
         deploy/data \
         deploy/public \
         deploy/data/cert \
         deploy/data/logs/nginx \
         configs
```

#### 3. 配置环境变量

确保 `.env` 文件已配置（在 `backend` 目录下）：

```bash
# 首次部署必须设置
ALBUM_INIT_ADMIN_EMAIL=admin@example.com
ALBUM_INIT_ADMIN_PASSWORD=your-secret-password

# 数据库配置（生产环境请修改）
ALBUM_POSTGRES_USER=album
ALBUM_POSTGRES_PASSWORD=your-database-password
ALBUM_POSTGRES_DB=album

# 服务器配置
ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com

# 认证配置（生产环境请务必修改）
ALBUM_AUTH_JWT_SECRET=your-jwt-secret-key
ALBUM_AUTH_URL_SIGNER_SECRET=your-signer-secret-key

# 架构配置（重要：根据服务器架构设置）
ALBUM_ARCH=amd64  # 或 arm64
```

#### 4. 设置架构环境变量

```bash
# 自动检测架构
export ALBUM_ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')

# 或手动设置
export ALBUM_ARCH=amd64  # 或 arm64
```

#### 5. 启动服务

```bash
# 使用 docker compose（推荐）
ALBUM_ARCH=${ALBUM_ARCH:-amd64} docker compose up -d

# 或使用 docker-compose
ALBUM_ARCH=${ALBUM_ARCH:-amd64} docker-compose up -d
```

#### 6. 验证部署

```bash
# 查看服务状态
docker compose ps
# 或
docker-compose ps

# 查看日志
docker compose logs -f
# 或
docker-compose logs -f

# 测试 API
curl http://localhost/api/v1/health

# 查看版本信息
curl http://localhost/api/v1/version
```

### 生产环境部署完整示例

```bash
# 1. 进入 backend 目录
cd backend

# 2. 创建必要目录
mkdir -p deploy/data/postgresql \
         deploy/data \
         deploy/public \
         deploy/data/cert \
         deploy/data/logs/nginx \
         configs

# 3. 设置架构（根据服务器架构）
export ALBUM_ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')

# 4. 确保 .env 文件已配置（包含 ALBUM_INIT_ADMIN_EMAIL 等）

# 5. 启动服务
ALBUM_ARCH=${ALBUM_ARCH} docker compose up -d

# 6. 查看状态
docker compose ps
docker compose logs -f
```

### 镜像说明

生产环境使用的镜像：

- **Backend**: `registry.cn-shenzhen.aliyuncs.com/greene/album-backend:latest-ARCH`
- **Nginx**: `registry.cn-shenzhen.aliyuncs.com/greene/album-nginx:latest-ARCH`
- **PostgreSQL**: `postgres:14`（官方镜像）

Nginx 镜像已包含：
- ✅ 配置模板文件（`default.conf.template`）
- ✅ 启动脚本（`docker-entrypoint.sh`）
- ✅ 所有必需的目录结构

因此不需要挂载配置文件和脚本，只需挂载：
- SSL 证书目录（如果启用 HTTPS）
- 日志目录

### 生产环境注意事项

1. **修改认证密钥**：
   ```bash
   export ALBUM_AUTH_JWT_SECRET=your-secure-jwt-secret
   export ALBUM_AUTH_URL_SIGNER_SECRET=your-secure-signer-secret
   ```

2. **修改数据库密码**：
   ```bash
   export ALBUM_POSTGRES_PASSWORD=your-secure-password
   ```

3. **启用 HTTPS**：
   ```bash
   # 将证书放置到 deploy/data/cert/
   cp your-cert.pem deploy/data/cert/cert.pem
   cp your-key.pem deploy/data/cert/key.pem
   
   # 启用 HTTPS
   export ALBUM_ENABLE_HTTPS=true
   ./deploy.sh
   ```

4. **配置服务器地址**：
   ```bash
   export ALBUM_SERVER_PUBLIC_BASE_URL=https://your-domain.com
   ```

## 部署服务

### 启动所有服务

```bash
docker-compose up -d
```

### 停止所有服务

```bash
docker-compose down
```

### 重启服务

```bash
docker-compose restart
```

### 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f album-backend
docker-compose logs -f nginx
docker-compose logs -f postgresql
```

### 更新服务

```bash
# 拉取最新镜像
docker-compose pull

# 重新构建并启动
docker-compose up -d --build
```

## 配置说明

### 大文件上传下载

Nginx 和应用程序都配置了支持大文件上传下载：

- **Nginx**: `client_max_body_size` 默认 2GB（可通过 `ALBUM_NGINX_CLIENT_MAX_BODY_SIZE` 配置）
- **应用层**: `ALBUM_MEDIA_MAX_FILE_SIZE` 默认 2GB
- **流式传输**: 已启用，支持大文件流式上传下载

### CORS 配置

CORS 由 Nginx 统一处理，支持：

- 预检请求（OPTIONS）
- 自定义请求头（包括文件上传相关头）
- 凭证支持
- 暴露响应头（Content-Disposition 等）

应用层 CORS 默认禁用，可通过 `ALBUM_ENABLE_APP_CORS=true` 启用。

### HTTPS 配置

1. 将 SSL 证书放置到 `data/cert/` 目录：
   - `data/cert/cert.pem` - 证书文件
   - `data/cert/key.pem` - 私钥文件

2. 在 `.env` 文件中启用 HTTPS：
   ```bash
   ALBUM_ENABLE_HTTPS=true
   ALBUM_SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
   ALBUM_SSL_KEY_PATH=/etc/nginx/ssl/key.pem
   ```

3. 重启服务：
   ```bash
   docker-compose restart nginx
   ```

### 数据持久化

以下目录会被持久化：

- `./data/postgresql` - PostgreSQL 数据
- `./data` - 应用数据（媒体文件等）
- `./data/logs/nginx` - Nginx 日志
- `./configs` - 配置文件（只读挂载）

## 验证部署

部署完成后，访问：

- **API 地址**: http://localhost/api/v1
- **健康检查**: http://localhost/api/v1/health
- **版本信息**: http://localhost/api/v1/version

## 故障排查

### 服务无法启动

1. 检查日志：
   ```bash
   docker-compose logs album-backend
   ```

2. 检查端口占用：
   ```bash
   netstat -tulpn | grep -E '80|443|8080|5432'
   ```

3. 检查环境变量：
   ```bash
   docker-compose config
   ```

### 数据库连接失败

1. 检查 PostgreSQL 服务状态：
   ```bash
   docker-compose ps postgresql
   docker-compose logs postgresql
   ```

2. 检查数据库连接配置：
   ```bash
   # 检查环境变量
   docker-compose exec album-backend env | grep ALBUM_DATABASE
   ```

3. 手动连接数据库测试：
   ```bash
   docker-compose exec postgresql psql -U album -d album
   ```

### 大文件上传失败

1. 检查 Nginx 配置：
   ```bash
   docker-compose exec nginx cat /etc/nginx/conf.d/default.conf | grep client_max_body_size
   ```

2. 检查应用配置：
   ```bash
   docker-compose exec album-backend env | grep ALBUM_MEDIA_MAX_FILE_SIZE
   ```

3. 查看 Nginx 错误日志：
   ```bash
   docker-compose exec nginx tail -f /var/log/nginx/error.log
   ```

### CORS 问题

1. 检查 Nginx CORS 配置：
   ```bash
   docker-compose exec nginx cat /etc/nginx/conf.d/default.conf | grep -A 10 "location /api"
   ```

2. 检查请求头：
   ```bash
   curl -v -H "Origin: http://localhost" http://localhost/api/v1/health
   ```

## 目录结构

```
deploy/
├── README.md                    # 本文档（已迁移到 doc/DEPLOYMENT/README.md）
├── init.sh                      # 初始化脚本
├── default.conf.template        # Nginx 配置模板
├── docker-entrypoint.sh         # Nginx 启动脚本
├── linux-amd64/                 # AMD64 平台配置
│   ├── Dockerfile.base          # 基础镜像
│   ├── Dockerfile               # 应用镜像
│   └── docker-compose.yaml      # 编排文件
└── linux-arm64/                 # ARM64 平台配置
    ├── Dockerfile.base
    ├── Dockerfile
    └── docker-compose.yaml
```

## 支持

如有问题，请查看：
- [项目文档](../INDEX.md)
- [架构文档](../ARCHITECTURE/README.md)
- [环境变量完整列表](./ENV_VARS.md)

