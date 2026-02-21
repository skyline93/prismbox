#!/usr/bin/env bash
set -e

# Album Backend 开发环境数据目录初始化
# 在 backend 根目录下执行

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

echo "=========================================="
echo "Album Backend 开发环境初始化 (data-dev)"
echo "=========================================="

echo "创建开发数据目录..."
mkdir -p deploy/data-dev/postgresql
mkdir -p deploy/data-dev/configs
mkdir -p deploy/data-dev/public
mkdir -p deploy/data-dev/cert
mkdir -p deploy/data-dev/certbot-www/.well-known/acme-challenge
mkdir -p deploy/data-dev/logs/nginx

echo "设置目录权限..."
chmod -R 755 deploy/data-dev

echo "设置开发 entrypoint 执行权限..."
chmod +x deploy/docker-entrypoint-dev.sh 2>/dev/null || true

echo ""
echo "开发数据目录已就绪: deploy/data-dev/"
echo "下一步: make dev-up && make terminal"
echo ""
