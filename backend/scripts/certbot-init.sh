#!/bin/bash
# Certbot 证书初始化脚本
# 用于首次获取 Let's Encrypt 证书

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

# 读取环境变量
DOMAIN=${ALBUM_CERTBOT_DOMAIN:-}
EMAIL=${ALBUM_CERTBOT_EMAIL:-}
STAGING=${ALBUM_CERTBOT_STAGING:-false}

# 检查必需参数
if [ -z "$DOMAIN" ]; then
    echo "错误: 请设置 ALBUM_CERTBOT_DOMAIN 环境变量"
    echo "示例: export ALBUM_CERTBOT_DOMAIN=api.example.com"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo "错误: 请设置 ALBUM_CERTBOT_EMAIL 环境变量"
    echo "示例: export ALBUM_CERTBOT_EMAIL=admin@example.com"
    exit 1
fi

# 选择 Let's Encrypt 环境
if [ "$STAGING" = "true" ]; then
    SERVER="--staging"
    echo "使用 Let's Encrypt 测试环境（staging）"
else
    SERVER=""
    echo "使用 Let's Encrypt 生产环境"
fi

# 创建必要的目录
mkdir -p deploy/data/cert
mkdir -p deploy/data/certbot-www

# 确保 Nginx 正在运行（用于 HTTP-01 验证）
echo "检查 Nginx 服务状态..."
if ! docker-compose ps nginx | grep -q "Up"; then
    echo "启动 Nginx 服务..."
    docker-compose up -d nginx
    echo "等待 Nginx 启动..."
    sleep 5
fi

# 获取证书
echo "开始获取证书..."
docker-compose run --rm --entrypoint="" certbot certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN" \
    $SERVER

# 复制证书到 Nginx 使用的目录
echo "复制证书文件..."
CERT_DIR="deploy/data/cert/live/$DOMAIN"
if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ]; then
    cp "$CERT_DIR/fullchain.pem" deploy/data/cert/cert.pem
    cp "$CERT_DIR/privkey.pem" deploy/data/cert/key.pem
    chmod 600 deploy/data/cert/key.pem
    echo "证书文件已复制到 deploy/data/cert/"
else
    echo "错误: 证书文件不存在"
    exit 1
fi

# 重新加载 Nginx（如果启用了 HTTPS）
if [ "${ALBUM_ENABLE_HTTPS:-false}" = "true" ]; then
    echo "重新加载 Nginx 配置..."
    docker-compose exec nginx nginx -s reload || true
fi

echo ""
echo "=========================================="
echo "证书获取成功！"
echo "=========================================="
echo "域名: $DOMAIN"
echo "证书路径: deploy/data/cert/cert.pem"
echo "私钥路径: deploy/data/cert/key.pem"
echo ""
echo "下一步:"
echo "1. 设置 ALBUM_ENABLE_HTTPS=true"
echo "2. 重启服务: docker-compose restart nginx"
echo "3. 验证 HTTPS: curl https://$DOMAIN/api/v1/version"
echo "=========================================="

