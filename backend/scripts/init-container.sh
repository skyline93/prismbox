#!/usr/bin/env bash
set -euo pipefail

# 环境变量（可在容器运行时覆盖）
CLI_BIN=${CLI_BIN:-album}
CONFIG_PATH=${CONFIG_PATH:-/data/configs/config.yaml}
STORAGE_PATH=${STORAGE_PATH:-/data/storage}
MAX_SIZE=${MAX_SIZE:-1TB}
ADMIN_EMAIL=${ADMIN_EMAIL:-}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-}
ADMIN_USERNAME=${ADMIN_USERNAME:-admin}
INIT_FORCE=${INIT_FORCE:-true}

if [[ -z "${ADMIN_EMAIL}" ]]; then
  echo "请通过 ADMIN_EMAIL 指定管理员邮箱" >&2
  exit 1
fi

if [[ -z "${ADMIN_PASSWORD}" ]]; then
  echo "请通过 ADMIN_PASSWORD 指定管理员密码" >&2
  exit 1
fi

echo "[1/4] 生成配置文件..."
FORCE_FLAG=()
if [[ "${INIT_FORCE}" == "true" ]]; then
  FORCE_FLAG=(--force)
fi

"${CLI_BIN}" --config "${CONFIG_PATH}" init config \
  "${FORCE_FLAG[@]}" \
  --storage-path "${STORAGE_PATH}"

echo "[2/4] 执行数据库迁移..."
"${CLI_BIN}" --config "${CONFIG_PATH}" init migrate

echo "[3/4] 初始化存储池..."
"${CLI_BIN}" --config "${CONFIG_PATH}" init storage \
  --local-path "${STORAGE_PATH}" \
  --max-size "${MAX_SIZE}" \
  --force

echo "[4/4] 创建管理员账户..."
"${CLI_BIN}" --config "${CONFIG_PATH}" init admin \
  --email "${ADMIN_EMAIL}" \
  --password "${ADMIN_PASSWORD}" \
  --username "${ADMIN_USERNAME}" \
  --reset-password

echo "初始化完成，可启动 Album Backend 服务。"

