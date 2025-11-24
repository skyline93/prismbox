# Album Backend 部署文档

## 📋 目录

- [概述](#概述)
- [快速开始](#快速开始)
- [部署场景](#部署场景)
  - [场景一：本地开发/测试](#场景一本地开发测试)
  - [场景二：生产环境（HTTP）](#场景二生产环境http)
  - [场景三：生产环境（HTTPS）](#场景三生产环境https)
- [HTTPS 配置](#https-配置)
  - [方式一：自签名证书（测试用）](#方式一自签名证书测试用)
  - [方式二：Let's Encrypt 证书（生产环境）](#方式二lets-encrypt-证书生产环境)
- [常用命令](#常用命令)
- [环境变量配置](#环境变量配置)
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

### 使用 Makefile（推荐）

```bash
cd backend

# 查看所有可用命令
make help

# 一键部署（构建镜像并启动服务）
make deploy

# 仅启动服务（镜像已存在）
make deploy-up
```

### 使用 Docker Compose

```bash
cd backend

# 启动服务
docker compose up -d

# 查看状态
docker compose ps

# 查看日志
docker compose logs -f
```

## 前置要求

- Docker 20.10+
- Docker Compose 2.0+ 或 `docker compose` 命令
- 至少 2GB 可用内存
- 至少 10GB 可用磁盘空间

## 部署场景

### 场景一：本地开发/测试

**目标**：快速启动服务进行开发测试

```bash
cd backend

# 1. 设置管理员信息（首次部署）
export ALBUM_INIT_ADMIN_EMAIL=admin@example.com
export ALBUM_INIT_ADMIN_PASSWORD=your-password

# 2. 一键部署
make deploy

# 3. 访问服务
curl http://localhost/api/v1/version
```

**特点**：
- 使用默认配置
- HTTP 模式（端口 80）
- 适合本地开发和测试

### 场景二：生产环境（HTTP）

**目标**：生产环境部署，使用 HTTP（不加密）

```bash
cd backend

# 1. 设置必要的环境变量
export ALBUM_INIT_ADMIN_EMAIL=admin@example.com
export ALBUM_INIT_ADMIN_PASSWORD=your-secure-password
export ALBUM_POSTGRES_PASSWORD=your-db-password
export ALBUM_AUTH_JWT_SECRET=your-jwt-secret
export ALBUM_AUTH_URL_SIGNER_SECRET=your-signer-secret
export ALBUM_SERVER_PUBLIC_BASE_URL=http://your-domain.com

# 2. 部署服务
make deploy

# 3. 验证
curl http://your-domain.com/api/v1/version
```

**注意**：生产环境建议使用 HTTPS，见场景三。

### 场景三：生产环境（HTTPS）

**目标**：生产环境部署，使用 HTTPS（加密）

#### 步骤 1：部署服务（HTTP 模式）

```bash
cd backend

# 设置基本配置
export ALBUM_INIT_ADMIN_EMAIL=admin@example.com
export ALBUM_INIT_ADMIN_PASSWORD=your-secure-password
export ALBUM_POSTGRES_PASSWORD=your-db-password
export ALBUM_AUTH_JWT_SECRET=your-jwt-secret
export ALBUM_AUTH_URL_SIGNER_SECRET=your-signer-secret

# 确保 HTTPS 未启用
export ALBUM_ENABLE_HTTPS=false

# 部署服务
make deploy
```

#### 步骤 2：获取 SSL 证书

选择以下方式之一：

**方式 A：自签名证书（仅用于测试）**

```bash
# 生成自签名证书
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout deploy/data/cert/key.pem \
  -out deploy/data/cert/cert.pem \
  -subj "/CN=YOUR_IP_OR_DOMAIN" \
  -addext "subjectAltName=IP:YOUR_IP"

chmod 600 deploy/data/cert/key.pem
```

**方式 B：Let's Encrypt 证书（生产环境推荐）**

```bash
# 设置域名和邮箱
export ALBUM_CERTBOT_DOMAIN=api.example.com
export ALBUM_CERTBOT_EMAIL=admin@example.com

# 获取证书（首次测试使用 staging）
export ALBUM_CERTBOT_STAGING=true
./scripts/certbot-init.sh

# 验证成功后，切换到生产环境
export ALBUM_CERTBOT_STAGING=false
./scripts/certbot-init.sh
```

#### 步骤 3：启用 HTTPS

```bash
# 启用 HTTPS
export ALBUM_ENABLE_HTTPS=true
export ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com

# 重启 Nginx
docker compose up -d nginx

# 验证
curl -k https://api.example.com/api/v1/version
```

**完整流程示例**：

```bash
# 1. 部署（HTTP）
export ALBUM_INIT_ADMIN_EMAIL=admin@example.com
export ALBUM_INIT_ADMIN_PASSWORD=secure-password
make deploy

# 2. 获取 Let's Encrypt 证书
export ALBUM_CERTBOT_DOMAIN=api.example.com
export ALBUM_CERTBOT_EMAIL=admin@example.com
./scripts/certbot-init.sh

# 3. 启用 HTTPS
export ALBUM_ENABLE_HTTPS=true
export ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com
docker compose up -d nginx
```

## 常用命令

### Makefile 命令

```bash
# 查看帮助
make help

# 构建镜像
make docker-build              # 构建所有镜像
make docker-build-backend      # 仅构建 backend
make docker-build-nginx        # 仅构建 nginx

# 部署服务
make deploy                    # 构建并部署
make deploy-up                 # 启动服务
make deploy-down               # 停止服务
make deploy-logs               # 查看日志
make deploy-ps                 # 查看状态
```

### Docker Compose 命令

```bash
# 服务管理
docker compose up -d           # 启动服务
docker compose down             # 停止服务
docker compose restart          # 重启服务
docker compose ps               # 查看状态

# 日志查看
docker compose logs -f          # 查看所有日志
docker compose logs -f nginx    # 查看 Nginx 日志
docker compose logs -f album-backend  # 查看后端日志

# 进入容器
docker compose exec nginx sh    # 进入 Nginx 容器
docker compose exec album-backend sh  # 进入后端容器
```

### HTTPS 相关命令

```bash
# 生成自签名证书
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout deploy/data/cert/key.pem \
  -out deploy/data/cert/cert.pem \
  -subj "/CN=YOUR_DOMAIN_OR_IP"

# 获取 Let's Encrypt 证书
export ALBUM_CERTBOT_DOMAIN=api.example.com
export ALBUM_CERTBOT_EMAIL=admin@example.com
./scripts/certbot-init.sh

# 检查证书状态
./scripts/certbot-check.sh

# 检查网络配置
./scripts/check-firewall.sh
```

## 环境变量配置

### 必需配置（首次部署）

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `ALBUM_INIT_ADMIN_EMAIL` | 管理员邮箱 | `admin@example.com` |
| `ALBUM_INIT_ADMIN_PASSWORD` | 管理员密码 | `secure-password` |

### 生产环境推荐配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ALBUM_POSTGRES_PASSWORD` | 数据库密码 | `album` |
| `ALBUM_AUTH_JWT_SECRET` | JWT 密钥 | `change-me-in-production` |
| `ALBUM_AUTH_URL_SIGNER_SECRET` | URL 签名密钥 | `change-me-in-production` |
| `ALBUM_SERVER_PUBLIC_BASE_URL` | 公共访问地址 | `http://localhost` |

### HTTPS 配置

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `ALBUM_ENABLE_HTTPS` | 启用 HTTPS | `false` |
| `ALBUM_CERTBOT_DOMAIN` | 域名（Let's Encrypt） | - |
| `ALBUM_CERTBOT_EMAIL` | 邮箱（Let's Encrypt） | - |
| `ALBUM_CERTBOT_STAGING` | 使用测试环境 | `false` |

### 完整环境变量列表

更多环境变量请参考 [环境变量完整列表](./ENV_VARS.md)


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

## HTTPS 配置

### 方式一：自签名证书（测试用）

适用于：本地测试、内网环境、IP 地址访问

```bash
# 1. 生成自签名证书
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout deploy/data/cert/key.pem \
  -out deploy/data/cert/cert.pem \
  -subj "/CN=47.107.63.140" \
  -addext "subjectAltName=IP:47.107.63.140"

chmod 600 deploy/data/cert/key.pem

# 2. 启用 HTTPS
export ALBUM_ENABLE_HTTPS=true
docker compose up -d nginx

# 3. 测试（使用 -k 忽略证书警告）
curl -k https://localhost/api/v1/version
```

**特点**：
- ✅ 无需域名，支持 IP 地址
- ✅ 无需外部验证
- ⚠️ 浏览器会显示"不安全"警告
- ⚠️ 仅用于测试，不适合生产环境

### 方式二：Let's Encrypt 证书（生产环境）

适用于：生产环境、有域名、需要浏览器信任

#### 前置条件

1. **域名已解析**：域名正确解析到服务器 IP
2. **80 端口开放**：Let's Encrypt 需要通过 80 端口验证
3. **防火墙配置**：确保 80 和 443 端口对外开放

#### 部署步骤

```bash
# 1. 确保服务以 HTTP 模式运行
export ALBUM_ENABLE_HTTPS=false
docker compose up -d nginx

# 2. 设置域名和邮箱
export ALBUM_CERTBOT_DOMAIN=api.example.com
export ALBUM_CERTBOT_EMAIL=admin@example.com

# 3. 首次测试使用 staging 环境（避免速率限制）
export ALBUM_CERTBOT_STAGING=true
./scripts/certbot-init.sh

# 4. 验证成功后，切换到生产环境
export ALBUM_CERTBOT_STAGING=false
./scripts/certbot-init.sh

# 5. 启用 HTTPS
export ALBUM_ENABLE_HTTPS=true
export ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com
docker compose up -d nginx

# 6. 验证
curl https://api.example.com/api/v1/version
```

**特点**：
- ✅ 浏览器完全信任，无警告
- ✅ 免费，自动续期
- ✅ 适合生产环境
- ⚠️ 需要域名（不支持 IP）
- ⚠️ 需要域名验证（80 端口必须可访问）

#### 常见问题

**问题 1：证书获取失败 - Connection refused**

**原因**：80 端口无法从外网访问

**解决**：
1. 检查防火墙：`sudo ufw allow 80/tcp` 或配置云服务商安全组
2. 检查 frp/内网穿透：确保 80 端口已映射
3. 运行诊断脚本：`./scripts/check-firewall.sh`

**问题 2：证书获取失败 - 403 Forbidden**

**原因**：Nginx 配置问题或目录权限问题

**解决**：
1. 检查 Nginx 配置：`docker compose exec nginx cat /etc/nginx/conf.d/default.conf | grep acme-challenge`
2. 检查目录权限：`ls -la deploy/data/certbot-www/`
3. 查看 Nginx 日志：`docker compose logs nginx`

**问题 3：证书自动续期**

Certbot 容器会自动每 12 小时检查一次，剩余时间少于 30 天时自动续期。

手动检查证书状态：
```bash
./scripts/certbot-check.sh
```

更多详细信息请参考 [HTTPS 部署指南](./HTTPS.md)。

## 验证部署

部署完成后，访问：

- **API 地址**: http://localhost/api/v1
- **健康检查**: http://localhost/api/v1/health
- **版本信息**: http://localhost/api/v1/version

## 故障排查

### 服务无法启动

```bash
# 1. 查看日志
docker compose logs album-backend
docker compose logs nginx

# 2. 检查容器状态
docker compose ps

# 3. 检查端口占用
ss -tuln | grep -E '80|443|8080|5432'
```

### 数据库连接失败

```bash
# 1. 检查数据库容器
docker compose ps postgresql
docker compose logs postgresql

# 2. 测试数据库连接
docker compose exec postgresql psql -U album -d album
```

### HTTPS 证书问题

```bash
# 1. 检查证书文件
ls -la deploy/data/cert/

# 2. 检查 Nginx 配置
docker compose exec nginx nginx -t

# 3. 查看 Nginx 日志
docker compose logs nginx | grep -i ssl

# 4. 检查证书获取（Let's Encrypt）
./scripts/certbot-check.sh
./scripts/check-firewall.sh
```

### 网络问题

```bash
# 运行网络诊断脚本
./scripts/check-firewall.sh

# 检查域名解析
nslookup your-domain.com

# 测试端口访问
curl -I http://your-domain.com
```

更多故障排查信息请参考 [HTTPS 部署指南](./HTTPS.md) 的故障排查章节。

## 相关文档

- [HTTPS 部署指南](./HTTPS.md) - 详细的 HTTPS 配置和故障排查
- [环境变量完整列表](./ENV_VARS.md) - 所有环境变量说明
- [架构文档](../ARCHITECTURE/README.md) - 系统架构设计

