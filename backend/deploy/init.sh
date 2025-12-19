#!/bin/bash
set -e

# Album Backend 首次部署初始化脚本
# 在 backend 根目录下执行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."  # 回到 backend 根目录

echo "=========================================="
echo "Album Backend 首次部署初始化"
echo "=========================================="

# 创建必要的目录
echo "创建必要的目录..."
mkdir -p deploy/data/postgresql
mkdir -p deploy/data/logs/nginx
mkdir -p deploy/data/cert
mkdir -p deploy/data/certbot-www/.well-known/acme-challenge
mkdir -p deploy/data/configs
mkdir -p deploy/public

# 设置目录权限
echo "设置目录权限..."
chmod -R 755 deploy/data
chmod -R 755 deploy/public

# 设置脚本执行权限
echo "设置脚本执行权限..."
chmod +x deploy/docker-entrypoint.sh 2>/dev/null || true
chmod +x deploy/docker-entrypoint-backend.sh 2>/dev/null || true

# 检查配置文件
if [ ! -f "deploy/data/configs/config.yaml" ]; then
    echo "提示: deploy/data/configs/config.yaml 不存在，容器启动时会自动生成（使用环境变量配置）"
fi

# 检查环境变量文件
if [ ! -f ".env" ]; then
    echo "创建 .env 文件模板..."
    cat > .env << 'EOF'
# Album Backend 环境变量配置
# 所有环境变量使用 ALBUM_ 前缀

# 数据库配置
ALBUM_POSTGRES_USER=album
ALBUM_POSTGRES_PASSWORD=album
ALBUM_POSTGRES_DB=album

# 服务器配置
ALBUM_SERVER_PUBLIC_BASE_URL=http://localhost

# 认证配置（生产环境请务必修改）
ALBUM_AUTH_JWT_SECRET=change-me-in-production
ALBUM_AUTH_URL_SIGNER_SECRET=change-me-in-production

# 初始化配置（首次部署时需要）
# 注意：首次部署后可以删除这些配置，或设置为空以跳过初始化
ALBUM_INIT_ADMIN_EMAIL=admin@example.com
ALBUM_INIT_ADMIN_PASSWORD=admin123
ALBUM_INIT_ADMIN_USERNAME=admin
ALBUM_INIT_STORAGE_MAX_SIZE=1TB

# 媒体配置
ALBUM_MEDIA_MAX_FILE_SIZE=2GB

# 日志配置
ALBUM_LOGGER_LEVEL=info
ALBUM_LOGGER_FORMAT=json

# Nginx 配置
ALBUM_HTTP_PORT=80
ALBUM_HTTPS_PORT=443
ALBUM_ENABLE_HTTPS=false
ALBUM_NGINX_CLIENT_MAX_BODY_SIZE=2G
ALBUM_NGINX_ACCESS_LOG_LEVEL=combined
ALBUM_NGINX_ERROR_LOG_LEVEL=warn

# Certbot 配置（HTTPS 证书管理）
# ALBUM_CERTBOT_EMAIL=admin@example.com
# ALBUM_CERTBOT_DOMAIN=api.example.com
# ALBUM_CERTBOT_STAGING=false  # 生产环境设为 false
EOF
    echo ".env 文件已创建，请根据实际情况修改配置"
    echo "注意：首次部署需要设置 ALBUM_INIT_ADMIN_EMAIL 和 ALBUM_INIT_ADMIN_PASSWORD"
else
    echo ".env 文件已存在，跳过创建"
fi

# 检查 SSL 证书（如果启用 HTTPS）
if [ "${ALBUM_ENABLE_HTTPS:-false}" = "true" ]; then
    if [ ! -f "deploy/data/cert/cert.pem" ] || [ ! -f "deploy/data/cert/key.pem" ]; then
        echo "警告: 已启用 HTTPS，但未找到 SSL 证书"
        echo ""
        echo "选项 1: 使用 Let's Encrypt 自动获取证书（推荐）"
        echo "  1. 设置环境变量："
        echo "     export ALBUM_CERTBOT_EMAIL=admin@example.com"
        echo "     export ALBUM_CERTBOT_DOMAIN=api.example.com"
        echo "  2. 运行证书初始化脚本："
        echo "     ./scripts/certbot-init.sh"
        echo ""
        echo "选项 2: 手动放置证书文件"
        echo "  请将证书文件放置到 deploy/data/cert/ 目录下："
        echo "    - deploy/data/cert/cert.pem"
        echo "    - deploy/data/cert/key.pem"
    fi
fi

echo ""
echo "=========================================="
echo "初始化完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. （可选）检查并修改 .env 文件中的配置（所有配置都有默认值）"
echo "2. （可选）如果启用 HTTPS，请将 SSL 证书放置到 deploy/data/cert/ 目录"
echo "3. 运行 ./deploy.sh 一键部署启动服务"
echo ""

