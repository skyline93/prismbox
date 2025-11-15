# 容器化部署重构变更日志

## 主要改进

### 1. 版本注入 ✅

- **Dockerfile 构建参数**：添加了 `VERSION`、`BUILD_TIME`、`GIT_COMMIT`、`GIT_BRANCH` 构建参数
- **LDFLAGS 注入**：在构建时通过 `-ldflags` 注入版本信息到二进制文件
- **自动版本检测**：`deploy.sh` 脚本自动从 Git 仓库获取版本信息
- **同时构建 CLI**：在构建阶段同时构建 `album-server` 和 `album-cli`

### 2. 自动初始化 ✅

- **启动脚本**：创建了 `docker-entrypoint-backend.sh`，在服务启动前自动检测并执行初始化
- **初始化检测**：自动检测配置文件是否存在，决定是否需要初始化
- **初始化步骤**：
  1. 生成配置文件（如果不存在）
  2. 执行数据库迁移
  3. 初始化存储池
  4. 创建管理员账户（如果提供了邮箱和密码）

### 3. 环境变量统一前缀 ✅

- **ALBUM_ 前缀**：所有环境变量使用 `ALBUM_` 前缀，防止与系统变量冲突
- **完整支持**：支持服务器、数据库、存储、认证、媒体、日志、变更日志等所有配置项
- **默认值**：所有配置都有合理的默认值，可以直接使用

### 4. 一键部署 ✅

- **根目录部署**：所有部署操作在 `backend` 根目录执行，无需切换目录
- **自动架构检测**：`deploy.sh` 自动检测系统架构（AMD64/ARM64）
- **自动初始化**：首次部署自动创建必要目录和配置文件模板

### 5. 完整文档 ✅

- **快速部署指南**：`README_DEPLOY.md` - 快速上手指南
- **完整部署文档**：`deploy/README.md` - 详细的部署说明
- **环境变量列表**：`deploy/ENV_VARS.md` - 所有环境变量的完整列表

## 使用方式

### 首次部署

```bash
cd backend

# 设置管理员信息（首次部署必须）
export ALBUM_INIT_ADMIN_EMAIL=admin@example.com
export ALBUM_INIT_ADMIN_PASSWORD=your-password

# 一键部署
./deploy.sh
```

### 后续部署

```bash
cd backend
./deploy.sh
```

容器会自动检测到数据库已初始化，跳过初始化步骤。

## 关键文件

- `docker-compose.yaml` - 主编排文件（在 backend 根目录）
- `deploy.sh` - 一键部署脚本
- `deploy/docker-entrypoint-backend.sh` - 容器启动脚本（自动初始化）
- `scripts/init-container.sh` - 初始化脚本
- `deploy/linux-*/Dockerfile` - 应用镜像（包含版本注入）
- `deploy/linux-*/Dockerfile.base` - 基础镜像（移除 Python/Node.js）

## 版本信息查看

部署后可以通过以下方式查看版本信息：

```bash
# 查看容器内版本
docker-compose exec album-backend /app/album-cli version

# 或通过 API
curl http://localhost/api/v1/version
```

