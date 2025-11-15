#!/bin/bash
set -e

# Album Backend 容器启动脚本
# 在启动服务前执行初始化（如果需要）

echo "=========================================="
echo "Album Backend 容器启动"
echo "=========================================="

# 检查是否需要初始化
CONFIG_PATH="${ALBUM_CONFIG_PATH:-/app/configs/config.yaml}"
INIT_REQUIRED=false

# 检查配置文件是否存在
if [ ! -f "$CONFIG_PATH" ]; then
    INIT_REQUIRED=true
    echo "检测到配置文件不存在，需要执行初始化"
fi

# 如果提供了初始化参数，尝试执行初始化
if [ -n "${ALBUM_INIT_ADMIN_EMAIL:-}" ] && [ -n "${ALBUM_INIT_ADMIN_PASSWORD:-}" ]; then
    echo "检测到初始化参数，开始执行初始化..."
    
    # 等待数据库就绪（最多等待 60 秒）
    # 通过尝试执行 CLI 命令来检测数据库是否就绪
    echo "等待数据库就绪..."
    MAX_WAIT=60
    WAITED=0
    while [ $WAITED -lt $MAX_WAIT ]; do
        # 尝试执行一个简单的 CLI 命令来检测数据库连接
        if /app/album-cli --config "$CONFIG_PATH" version >/dev/null 2>&1; then
            echo "数据库连接成功"
            break
        fi
        if [ $WAITED -eq 0 ]; then
            echo "等待数据库就绪... (最多等待 ${MAX_WAIT} 秒)"
        fi
        sleep 2
        WAITED=$((WAITED + 2))
    done
    
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo "警告: 数据库连接超时，但继续尝试初始化（初始化脚本会处理连接错误）"
    fi
    
    # 设置初始化脚本的环境变量
    export CLI_BIN=/app/album-cli
    export CONFIG_PATH="$CONFIG_PATH"
    export STORAGE_PATH="${ALBUM_STORAGE_PRIMARY_LOCAL_BASE_PATH:-/app/data}"
    export MAX_SIZE="${ALBUM_INIT_STORAGE_MAX_SIZE:-1TB}"
    export ADMIN_EMAIL="${ALBUM_INIT_ADMIN_EMAIL}"
    export ADMIN_PASSWORD="${ALBUM_INIT_ADMIN_PASSWORD}"
    export ADMIN_USERNAME="${ALBUM_INIT_ADMIN_USERNAME:-admin}"
    export INIT_FORCE="${ALBUM_INIT_FORCE:-true}"
    
    # 执行初始化脚本
    /app/init-container.sh
    
    echo "初始化完成"
elif [ "$INIT_REQUIRED" = "true" ]; then
    echo "警告: 检测到需要初始化，但未提供初始化参数"
    echo "首次部署请设置以下环境变量："
    echo "  - ALBUM_INIT_ADMIN_EMAIL: 管理员邮箱"
    echo "  - ALBUM_INIT_ADMIN_PASSWORD: 管理员密码"
    echo "可选参数："
    echo "  - ALBUM_INIT_ADMIN_USERNAME: 管理员用户名（默认: admin）"
    echo "  - ALBUM_INIT_STORAGE_MAX_SIZE: 存储池最大大小（默认: 1TB）"
    echo "  - ALBUM_INIT_FORCE: 强制初始化（默认: true）"
    echo ""
    echo "如果数据库已初始化，可以忽略此警告并继续启动服务"
fi

echo ""
echo "启动 Album Backend 服务..."
echo ""

# 执行传入的命令（通常是 ./album-server）
exec "$@"

