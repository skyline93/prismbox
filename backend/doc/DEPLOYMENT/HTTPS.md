# HTTPS 部署指南

本文档介绍如何为 Album Backend 启用 HTTPS 支持。

## 快速开始

### 方式一：使用 Let's Encrypt 自动获取证书（推荐）

#### 1. 设置环境变量

```bash
# 设置域名和邮箱
export ALBUM_CERTBOT_DOMAIN=api.example.com
export ALBUM_CERTBOT_EMAIL=admin@example.com

# 首次测试使用测试环境（避免速率限制）
export ALBUM_CERTBOT_STAGING=true
```

#### 2. 初始化证书

```bash
cd backend
./scripts/certbot-init.sh
```

#### 3. 验证证书后切换到生产环境

```bash
# 验证证书是否正常工作
curl https://api.example.com/api/v1/version

# 切换到生产环境
export ALBUM_CERTBOT_STAGING=false
./scripts/certbot-init.sh
```

#### 4. 启用 HTTPS

```bash
# 设置环境变量
export ALBUM_ENABLE_HTTPS=true
export ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com

# 启动服务（包含 certbot 容器）
docker-compose --profile https up -d
```

### 方式二：使用已有证书

#### 1. 放置证书文件

```bash
# 将证书文件放置到指定目录
cp your-cert.pem backend/deploy/data/cert/cert.pem
cp your-key.pem backend/deploy/data/cert/key.pem

# 设置正确的权限
chmod 600 backend/deploy/data/cert/key.pem
```

#### 2. 启用 HTTPS

```bash
export ALBUM_ENABLE_HTTPS=true
export ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com
docker-compose up -d
```

## 证书管理

### 检查证书状态

```bash
./scripts/certbot-check.sh
```

### 手动续期证书

```bash
./scripts/certbot-renew.sh
```

### 证书自动续期

Certbot 容器会自动每 12 小时检查一次证书，如果剩余时间少于 30 天会自动续期。

## 环境变量说明

| 变量名 | 说明 | 默认值 | 示例 |
|--------|------|--------|------|
| `ALBUM_ENABLE_HTTPS` | 是否启用 HTTPS | `false` | `true` |
| `ALBUM_SSL_CERT_PATH` | SSL 证书路径 | `/etc/nginx/ssl/cert.pem` | `/etc/nginx/ssl/cert.pem` |
| `ALBUM_SSL_KEY_PATH` | SSL 私钥路径 | `/etc/nginx/ssl/key.pem` | `/etc/nginx/ssl/key.pem` |
| `ALBUM_CERTBOT_EMAIL` | Let's Encrypt 通知邮箱 | - | `admin@example.com` |
| `ALBUM_CERTBOT_DOMAIN` | 域名 | - | `api.example.com` |
| `ALBUM_CERTBOT_STAGING` | 是否使用测试环境 | `false` | `true` |

## 故障排查

### 证书获取失败

**问题**：`certbot-init.sh` 执行失败

**排查步骤**：
1. 检查域名 DNS 解析是否正确
2. 检查 80 端口是否可访问（HTTP-01 验证需要）
3. 检查防火墙规则
4. 查看 Certbot 日志：`docker-compose logs certbot`

**解决方案**：
- 确保域名正确解析到服务器 IP
- 确保 80 端口对外开放
- 首次测试使用 `ALBUM_CERTBOT_STAGING=true` 避免速率限制

### Nginx SSL 错误

**问题**：Nginx 无法加载 SSL 证书

**排查步骤**：
1. 检查证书文件是否存在：`ls -la deploy/data/cert/`
2. 检查证书文件权限：`chmod 600 deploy/data/cert/key.pem`
3. 检查 Nginx 配置：`docker-compose exec nginx nginx -t`

**解决方案**：
- 确保证书文件路径正确
- 设置正确的文件权限
- 检查 Nginx 日志：`docker-compose logs nginx`

### 证书续期失败

**问题**：证书续期失败

**排查步骤**：
1. 检查 Certbot 容器是否运行：`docker-compose ps certbot`
2. 查看 Certbot 日志：`docker-compose logs certbot`
3. 手动执行续期：`./scripts/certbot-renew.sh`

**解决方案**：
- 确保 Certbot 容器正常运行
- 检查证书目录权限
- 手动执行续期并查看详细错误信息

## 移动端配置

启用 HTTPS 后，需要更新移动端配置：

### 1. 更新 API 地址

```dart
// lib/config/app_config.dart
static const String defaultServerAddr = 'https://api.example.com';
```

### 2. 更新 Android 配置

确保 `network_security_config.xml` 仅允许 HTTPS（生产环境）。

### 3. 更新 iOS 配置

确保 `Info.plist` 中移除了 `NSAllowsArbitraryLoads`（生产环境）。

详细说明请参考 [HTTPS 架构设计文档](../ARCHITECTURE/18-https-architecture.md)。

## 安全最佳实践

1. **使用强加密套件**：已配置 TLS 1.2/1.3 和现代加密套件
2. **启用 HSTS**：可选，在 Nginx 配置中添加 HSTS 头
3. **定期更新证书**：Certbot 自动处理
4. **监控证书到期**：使用 `certbot-check.sh` 定期检查
5. **备份证书**：定期备份证书文件

## 相关文档

- [HTTPS 架构设计](../ARCHITECTURE/18-https-architecture.md) - 完整的架构设计文档
- [部署文档](./README.md) - 完整的部署指南
- [环境变量列表](./ENV_VARS.md) - 环境变量完整列表

