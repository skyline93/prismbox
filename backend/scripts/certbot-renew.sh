#!/bin/bash
# Certbot 证书续期脚本
# 手动执行证书续期（通常由容器自动执行）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "开始续期证书..."

# 执行续期
docker-compose exec certbot certbot renew --webroot --webroot-path=/var/www/certbot

# 复制更新的证书
DOMAIN=${ALBUM_CERTBOT_DOMAIN:-}
if [ -n "$DOMAIN" ]; then
    CERT_DIR="data/cert/live/$DOMAIN"
    if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ]; then
        cp "$CERT_DIR/fullchain.pem" data/cert/cert.pem
        cp "$CERT_DIR/privkey.pem" data/cert/key.pem
        chmod 600 data/cert/key.pem
        echo "证书文件已更新"
        
        # 重新加载 Nginx
        if [ "${ALBUM_ENABLE_HTTPS:-false}" = "true" ]; then
            echo "重新加载 Nginx 配置..."
            docker-compose exec nginx nginx -s reload
        fi
    fi
fi

echo "证书续期完成"

