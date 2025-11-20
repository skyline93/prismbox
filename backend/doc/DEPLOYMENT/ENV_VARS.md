# Album Backend 环境变量完整列表

所有环境变量使用 `ALBUM_` 前缀，防止与系统变量冲突。

## 服务器配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_SERVER_HOST` | 服务器监听地址 | string | `0.0.0.0` | `0.0.0.0` |
| `ALBUM_SERVER_PORT` | 服务器端口 | int | `8080` | `8080` |
| `ALBUM_SERVER_PUBLIC_BASE_URL` | 公共访问地址 | string | `http://localhost` | `https://api.example.com` |

## 数据库配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_DATABASE_TYPE` | 数据库类型 | string | `postgres` | `postgres`, `sqlite` |
| `ALBUM_DATABASE_DSN` | 数据库连接字符串 | string | - | `host=postgresql user=album password=album dbname=album port=5432` |

## 存储配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_STORAGE_PRIMARY_LOCAL_BASE_PATH` | 主存储路径 | string | `/app/data` | `/app/data` |

## 认证配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_AUTH_JWT_SECRET` | JWT 密钥 | string | `change-me` | `your-secret-key` |
| `ALBUM_AUTH_URL_SIGNER_SECRET` | URL 签名密钥 | string | `change-me-too` | `your-signer-secret` |
| `ALBUM_AUTH_ACCESS_TOKEN_EXPIRES_IN` | Access Token 过期时间 | duration | `30m` | `30m`, `1h` |
| `ALBUM_AUTH_REFRESH_TOKEN_EXPIRES_IN` | Refresh Token 过期时间 | duration | `720h` | `720h`, `30d` |
| `ALBUM_AUTH_APPLE_APP_BUNDLE_ID` | Apple App Bundle ID | string | - | `com.example.app` |
| `ALBUM_AUTH_AVATAR_SAVE_PATH` | 头像保存路径 | string | `./public/avatars` | `/app/public/avatars` |
| `ALBUM_AUTH_MAX_AVATAR_SIZE` | 最大头像大小 | size | `5MB` | `5MB`, `10MB` |
| `ALBUM_AUTH_SIGNED_URL_LOAD_TTL` | 签名 URL 过期时间 | duration | `30m` | `30m`, `1h` |

## 媒体配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_MEDIA_MAX_FILE_SIZE` | 最大文件大小 | size | `2GB` | `2GB`, `5GB` |
| `ALBUM_MEDIA_PROCESSOR_CONCURRENCY` | 媒体处理并发数 | int | `4` | `4`, `8` |
| `ALBUM_MEDIA_PROCESSOR_IMAGICK_POOL_SIZE` | ImageMagick 池大小 | int | `10` | `10`, `20` |
| `ALBUM_MEDIA_PROCESSOR_IMAGICK_MEMORY_LIMIT` | ImageMagick 内存限制 | size | `2GB` | `2GB`, `4GB` |
| `ALBUM_MEDIA_PROCESSOR_IMAGICK_DISK_LIMIT` | ImageMagick 磁盘限制 | size | `10GB` | `10GB`, `20GB` |
| `ALBUM_MEDIA_PROCESSOR_FFMPEG_BINARY_PATH` | FFmpeg 二进制路径 | string | `/usr/bin/ffmpeg` | `/usr/bin/ffmpeg` |
| `ALBUM_MEDIA_PROCESSOR_FFMPEG_PROBE_PATH` | FFprobe 二进制路径 | string | `/usr/bin/ffprobe` | `/usr/bin/ffprobe` |
| `ALBUM_MEDIA_PROCESSOR_FFMPEG_MAX_CONCURRENCY` | FFmpeg 最大并发数 | int | `4` | `4`, `8` |

## 日志配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_LOGGER_LEVEL` | 日志级别 | string | `info` | `debug`, `info`, `warn`, `error` |
| `ALBUM_LOGGER_FORMAT` | 日志格式 | string | `json` | `json`, `console` |
| `ALBUM_LOGGER_OUTPUT` | 日志输出 | string | `stdout` | `stdout`, `stderr`, `/path/to/log` |

## 变更日志配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_CHANGELOG_ENABLED` | 是否启用变更日志 | bool | `true` | `true`, `false` |
| `ALBUM_CHANGELOG_CLEANUP_INTERVAL` | 清理任务运行周期 | duration | `24h` | `24h`, `48h` |
| `ALBUM_CHANGELOG_DEFAULT_PAGE_LIMIT` | 默认分页大小 | int | `500` | `500`, `1000` |

## CORS 配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_ENABLE_APP_CORS` | 是否启用应用层 CORS | bool | `false` | `true`, `false` |
| `ALBUM_CORS_ALLOW_ORIGINS` | 允许的源（应用层） | string | `*` | `https://example.com` |

## Nginx 配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_HTTP_PORT` | HTTP 端口 | int | `80` | `80`, `8080` |
| `ALBUM_HTTPS_PORT` | HTTPS 端口 | int | `443` | `443`, `8443` |
| `ALBUM_ENABLE_HTTPS` | 是否启用 HTTPS | bool | `false` | `true`, `false` |
| `ALBUM_SSL_CERT_PATH` | SSL 证书路径 | string | `/etc/nginx/ssl/cert.pem` | `/etc/nginx/ssl/cert.pem` |
| `ALBUM_SSL_KEY_PATH` | SSL 私钥路径 | string | `/etc/nginx/ssl/key.pem` | `/etc/nginx/ssl/key.pem` |
| `ALBUM_NGINX_CLIENT_MAX_BODY_SIZE` | 最大上传文件大小 | size | `2G` | `2G`, `5G` |
| `ALBUM_NGINX_ACCESS_LOG_LEVEL` | 访问日志级别 | string | `combined` | `combined`, `json` |
| `ALBUM_NGINX_ERROR_LOG_LEVEL` | 错误日志级别 | string | `warn` | `debug`, `info`, `warn`, `error` |

## 初始化配置

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_INIT_ADMIN_EMAIL` | 管理员邮箱（首次部署需要） | string | - | `admin@example.com` |
| `ALBUM_INIT_ADMIN_PASSWORD` | 管理员密码（首次部署需要） | string | - | `your-password` |
| `ALBUM_INIT_ADMIN_USERNAME` | 管理员用户名 | string | `admin` | `admin` |
| `ALBUM_INIT_STORAGE_MAX_SIZE` | 存储池最大大小 | size | `1TB` | `1TB`, `2TB` |
| `ALBUM_INIT_FORCE` | 强制初始化 | bool | `true` | `true`, `false` |
| `ALBUM_CONFIG_PATH` | 配置文件路径 | string | `/app/data/configs/config.yaml` | `/app/data/configs/config.yaml` |

## PostgreSQL 配置（docker-compose）

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_POSTGRES_USER` | PostgreSQL 用户名 | string | `album` | `album` |
| `ALBUM_POSTGRES_PASSWORD` | PostgreSQL 密码 | string | `album` | `your-password` |
| `ALBUM_POSTGRES_DB` | 数据库名 | string | `album` | `album` |

## 构建配置（版本注入）

| 变量名 | 说明 | 类型 | 默认值 | 示例 |
|--------|------|------|--------|------|
| `ALBUM_VERSION` | 版本号 | string | `dev` | `v1.0.0` |
| `ALBUM_BUILD_TIME` | 构建时间 | string | 当前时间 | `2024-01-01T00:00:00Z` |
| `ALBUM_GIT_COMMIT` | Git 提交哈希 | string | `unknown` | `abc1234` |
| `ALBUM_GIT_BRANCH` | Git 分支 | string | `unknown` | `main` |

## 数据类型说明

### duration（时长）

支持格式：`1h`, `30m`, `5s`, `24h`, `720h` 等

### size（大小）

支持格式：`1GB`, `500MB`, `100KB`, `2G`, `5M` 等

### bool（布尔值）

支持格式：`true`, `false`, `1`, `0`

## 使用示例

### .env 文件示例

```bash
# 数据库配置
ALBUM_POSTGRES_USER=album
ALBUM_POSTGRES_PASSWORD=secure-password-here
ALBUM_POSTGRES_DB=album

# 服务器配置
ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com

# 认证配置
ALBUM_AUTH_JWT_SECRET=your-jwt-secret-key-here
ALBUM_AUTH_URL_SIGNER_SECRET=your-url-signer-secret-here

# 媒体配置
ALBUM_MEDIA_MAX_FILE_SIZE=5GB

# 日志配置
ALBUM_LOGGER_LEVEL=info
ALBUM_LOGGER_FORMAT=json

# Nginx 配置
ALBUM_ENABLE_HTTPS=true
ALBUM_NGINX_CLIENT_MAX_BODY_SIZE=5G
```

### 在 docker-compose.yaml 中使用

```yaml
environment:
  - ALBUM_SERVER_PORT=8080
  - ALBUM_MEDIA_MAX_FILE_SIZE=${ALBUM_MEDIA_MAX_FILE_SIZE:-2GB}
```

