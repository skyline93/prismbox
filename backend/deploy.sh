#!/bin/bash
set -e

# Album Backend 部署脚本（已废弃，请使用 make deploy）
# 此脚本已简化，仅用于兼容性，建议使用 make deploy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Album Backend 部署脚本"
echo "=========================================="
echo ""
echo "注意: 此脚本已简化，建议使用 'make deploy' 命令"
echo ""

# 检查是否需要构建基础镜像
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    PLATFORM="linux-amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    PLATFORM="linux-arm64"
fi

if [ "$1" = "--build-base" ]; then
    echo "构建基础镜像..."
    if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
        make docker-build-base ARCH=amd64
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        make docker-build-base ARCH=arm64
    fi
    echo ""
fi

# 使用 Makefile 的 deploy 命令
echo "使用 make deploy 进行部署..."
make deploy

