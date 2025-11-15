# Album Backend 快速部署指南

## 一键部署

在 `backend` 根目录下执行：

```bash
./deploy.sh
```

就这么简单！脚本会自动：
- 检测系统架构（AMD64/ARM64）
- 初始化必要的目录
- 构建并启动所有服务

## 部署说明

### 默认配置

所有配置都有合理的默认值，可以直接使用：

- **数据库**: PostgreSQL，用户名/密码/数据库名均为 `album`
- **服务器**: 监听 `0.0.0.0:8080`
- **Nginx**: HTTP 端口 80，HTTPS 端口 443（默认禁用 HTTPS）
- **文件大小**: 最大 2GB
- **认证密钥**: 使用开发环境默认值（生产环境请修改）

### 首次部署初始化

首次部署时，容器会自动执行初始化（如果提供了管理员信息）：

1. **生成配置文件**（如果不存在）
2. **执行数据库迁移**
3. **初始化存储池**
4. **创建管理员账户**（如果提供了邮箱和密码）

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

### 版本信息注入

在构建镜像时，系统会自动注入版本信息，包括：
- **Version**: 版本号（从 git tag 获取，如 v1.0.0）
- **BuildTime**: 构建时间（自动生成）
- **GitCommit**: Git 提交哈希（short commit hash）
- **GitBranch**: Git 分支名
- **GoVersion**: Go 版本
- **Platform**: 构建平台

#### 自动注入（推荐）

使用 `deploy.sh` 脚本会自动检测并注入版本信息：

```bash
# 在有 .git 目录的情况下，自动获取 git 信息
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

```bash
# GitHub Actions 示例
export ALBUM_VERSION=${GITHUB_REF#refs/tags/}
export ALBUM_GIT_COMMIT=${GITHUB_SHA:0:7}
export ALBUM_GIT_BRANCH=${GITHUB_REF#refs/heads/}
export ALBUM_BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# GitLab CI 示例
export ALBUM_VERSION=$CI_COMMIT_TAG
export ALBUM_GIT_COMMIT=${CI_COMMIT_SHA:0:7}
export ALBUM_GIT_BRANCH=$CI_COMMIT_REF_NAME
export ALBUM_BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
```

#### 查看版本信息

部署后，可以通过 API 查看版本信息：

```bash
# 查询版本信息
curl http://localhost/api/v1/version

# 返回 JSON 格式
{
  "version": "v1.0.0",
  "build_time": "2025-01-15T10:30:00Z",
  "git_commit": "abc1234",
  "git_branch": "main",
  "go_version": "go1.23.6",
  "platform": "linux/arm64"
}
```

### 验证部署

部署完成后，访问：

- **API 地址**: http://localhost/api/v1
- **健康检查**: http://localhost/api/v1/health
- **版本信息**: http://localhost/api/v1/version

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

### 故障排查

如果遇到问题，请查看：

1. **服务日志**：
   ```bash
   docker-compose logs -f
   ```

2. **服务状态**：
   ```bash
   docker-compose ps
   ```

3. **详细文档**：
   - [完整部署文档](deploy/README.md)
   - [环境变量列表](deploy/ENV_VARS.md)

### 更多信息

- 完整的部署文档请参考：[deploy/README.md](deploy/README.md)
- 环境变量完整列表：[deploy/ENV_VARS.md](deploy/ENV_VARS.md)

