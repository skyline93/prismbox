#!/usr/bin/env bash
set -euo pipefail

# 环境变量（可在容器运行时覆盖）
CLI_BIN=${CLI_BIN:-/app/album-cli}
CONFIG_PATH=${CONFIG_PATH:-/app/configs/config.yaml}
STORAGE_PATH=${STORAGE_PATH:-/app/data}
MAX_SIZE=${MAX_SIZE:-1TB}
ADMIN_EMAIL=${ADMIN_EMAIL:-}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-}
ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
INIT_FORCE=${INIT_FORCE:-true}

# 如果未提供管理员信息，跳过管理员创建步骤
SKIP_ADMIN=false
if [[ -z "${ADMIN_EMAIL}" ]] || [[ -z "${ADMIN_PASSWORD}" ]]; then
  echo "警告: 未提供管理员邮箱或密码，将跳过管理员账户创建步骤" >&2
  SKIP_ADMIN=true
fi

echo "[1/4] 生成配置文件..."
FORCE_FLAG=()
if [[ "${INIT_FORCE}" == "true" ]]; then
  FORCE_FLAG=(--force)
fi

# 确保配置文件目录存在
mkdir -p "$(dirname "${CONFIG_PATH}")"

"${CLI_BIN}" --config "${CONFIG_PATH}" init config \
  "${FORCE_FLAG[@]}" \
  --storage-path "${STORAGE_PATH}" || {
    echo "警告: 配置文件生成失败或已存在，继续执行后续步骤..."
  }

echo "[2/4] 执行数据库迁移..."
"${CLI_BIN}" --config "${CONFIG_PATH}" init migrate || {
    echo "错误: 数据库迁移失败" >&2
    exit 1
}

echo "[3/4] 初始化存储池..."
"${CLI_BIN}" --config "${CONFIG_PATH}" init storage \
  --local-path "${STORAGE_PATH}" \
  --max-size "${MAX_SIZE}" \
  --force || {
    echo "警告: 存储池初始化失败或已存在，继续执行后续步骤..."
  }

if [[ "${SKIP_ADMIN}" == "false" ]]; then
  echo "[4/4] 创建管理员账户..."
  "${CLI_BIN}" --config "${CONFIG_PATH}" init admin \
    --email "${ADMIN_EMAIL}" \
    --password "${ADMIN_PASSWORD}" \
    --username "${ADMIN_USERNAME}" \
    --reset-password || {
      echo "警告: 管理员账户创建失败或已存在" >&2
    }
else
  echo "[4/4] 跳过管理员账户创建（未提供管理员信息）"
fi

echo "初始化完成，可启动 Album Backend 服务。"

