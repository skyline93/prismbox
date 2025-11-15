#!/bin/bash
set -e

# Album Backend 一键部署脚本
# 在 backend 根目录下执行: ./deploy.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "Album Backend 一键部署"
echo "=========================================="
echo ""

# 检测架构
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    PLATFORM="linux-amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    PLATFORM="linux-arm64"
else
    echo "错误: 不支持的架构: $ARCH"
    exit 1
fi

echo "检测到架构: $ARCH ($PLATFORM)"
export ALBUM_PLATFORM=$PLATFORM
echo ""

# 根据架构更新 docker-compose.yaml 中的 Dockerfile 路径
if [ "$PLATFORM" != "linux-amd64" ]; then
    echo "更新 docker-compose.yaml 以使用 $PLATFORM 平台..."
    # 使用 sed 替换 dockerfile 路径（macOS 和 Linux 兼容）
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|deploy/linux-amd64/Dockerfile|deploy/$PLATFORM/Dockerfile|g" docker-compose.yaml
    else
        sed -i "s|deploy/linux-amd64/Dockerfile|deploy/$PLATFORM/Dockerfile|g" docker-compose.yaml
    fi
    echo "已更新为使用 $PLATFORM 平台"
    echo ""
fi

# 初始化（如果需要）
if [ ! -d "deploy/data/postgresql" ]; then
    echo "首次部署，执行初始化..."
    bash deploy/init.sh
    echo ""
fi

# 确保脚本有执行权限
echo "确保脚本有执行权限..."
chmod +x deploy/docker-entrypoint.sh 2>/dev/null || true
chmod +x deploy/docker-entrypoint-backend.sh 2>/dev/null || true
echo ""

# 检查 Docker 和 Docker Compose
if ! command -v docker &> /dev/null; then
    echo "错误: 未找到 Docker，请先安装 Docker"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "错误: 未找到 Docker Compose，请先安装 Docker Compose"
    exit 1
fi

# 使用 docker compose 或 docker-compose
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo "使用: $DOCKER_COMPOSE"
echo ""

# 检查是否需要构建基础镜像
if [ "$1" = "--build-base" ]; then
    echo "构建基础镜像..."
    docker build -f deploy/$PLATFORM/Dockerfile.base \
        -t registry.cn-shenzhen.aliyuncs.com/greene/album-base:$PLATFORM-latest \
        .
    echo "基础镜像构建完成"
    echo ""
fi

# 设置版本信息（总是设置，即使没有 .git 目录）
export ALBUM_BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -d ".git" ]; then
    export ALBUM_VERSION=$(git describe --tags --always --dirty 2>/dev/null || echo "dev")
    export ALBUM_GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    export ALBUM_GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
else
    export ALBUM_VERSION=${ALBUM_VERSION:-dev}
    export ALBUM_GIT_COMMIT=${ALBUM_GIT_COMMIT:-unknown}
    export ALBUM_GIT_BRANCH=${ALBUM_GIT_BRANCH:-unknown}
fi

echo "构建版本信息:"
echo "  Version: $ALBUM_VERSION"
echo "  BuildTime: $ALBUM_BUILD_TIME"
echo "  GitCommit: $ALBUM_GIT_COMMIT"
echo "  GitBranch: $ALBUM_GIT_BRANCH"
echo ""

# 启动服务
echo "启动服务..."
$DOCKER_COMPOSE up -d --build

# 如果修改了 docker-compose.yaml，恢复为默认值（可选，保留修改以便后续使用）
# if [ "$PLATFORM" != "linux-amd64" ]; then
#     echo "恢复 docker-compose.yaml 为默认配置..."
#     if [[ "$OSTYPE" == "darwin"* ]]; then
#         sed -i '' "s|deploy/$PLATFORM/Dockerfile|deploy/linux-amd64/Dockerfile|g" docker-compose.yaml
#     else
#         sed -i "s|deploy/$PLATFORM/Dockerfile|deploy/linux-amd64/Dockerfile|g" docker-compose.yaml
#     fi
# fi

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "服务状态:"
$DOCKER_COMPOSE ps
echo ""
echo "查看日志:"
echo "  $DOCKER_COMPOSE logs -f"
echo ""
echo "停止服务:"
echo "  $DOCKER_COMPOSE down"
echo ""
echo "API 地址:"
echo "  http://localhost/api/v1"
echo ""

