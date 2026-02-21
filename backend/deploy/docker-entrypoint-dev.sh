#!/usr/bin/env bash
set -e

# 开发环境 entrypoint：根据 DEV_UID/DEV_GID 修正挂载目录权限后以对应用户执行命令
# 供 docker-compose.dev.yaml 中 album-backend 使用；需以 root 启动容器以便 chown

run_as_user() {
    local uid="${1:-1000}"
    local gid="${2:-1000}"
    shift 2 || true
    if command -v gosu >/dev/null 2>&1; then
        exec gosu "${uid}:${gid}" "$@"
    fi
    # 若未安装 gosu 则尝试安装（需 root）
    if [ "$(id -u)" = "0" ]; then
        apt-get update -qq && apt-get install -y --no-install-recommends gosu >/dev/null 2>&1 && exec gosu "${uid}:${gid}" "$@"
    fi
    # 无 gosu 且非 root：直接执行（可能权限受限）
    exec "$@"
}

if [ -n "${DEV_UID:-}" ] && [ -n "${DEV_GID:-}" ]; then
    uid="${DEV_UID}"
    gid="${DEV_GID}"
    if [ "$(id -u)" = "0" ]; then
        if ! getent group "$gid" >/dev/null 2>&1; then
            groupadd -g "$gid" devgroup
        fi
        if ! getent passwd "$uid" >/dev/null 2>&1; then
            useradd -u "$uid" -g "$gid" -m -s /bin/zsh devuser
            devhome="$(getent passwd "$uid" | cut -d: -f6)"
            if [ -n "$devhome" ] && [ -d /home/app ]; then
                [ -f /home/app/.zshrc ] && cp /home/app/.zshrc "$devhome/.zshrc" 2>/dev/null || true
                [ -d /home/app/.oh-my-zsh ] && cp -R /home/app/.oh-my-zsh "$devhome/" 2>/dev/null || true
                chown -R "${uid}:${gid}" "$devhome"
            fi
        fi
        chown -R "${uid}:${gid}" /app 2>/dev/null || true
        [ -d /app/deploy/data-dev ] && chown -R "${uid}:${gid}" /app/deploy/data-dev 2>/dev/null || true
        # 使 Go 模块缓存卷（/home/app/go/pkg/mod）对 DEV_UID 可写，容器销毁重建后无需重新下载
        [ -d /home/app ] && chown -R "${uid}:${gid}" /home/app 2>/dev/null || true
        run_as_user "$uid" "$gid" "$@"
    fi
fi

# 未设置 DEV_UID/DEV_GID 或非 root：直接执行
exec "$@"
