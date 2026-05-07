#!/bin/sh
set -e

# 兼容入口：历史路径 deploy/init.sh
# 新入口已迁移到 scripts/init-runtime.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec sh "$SCRIPT_DIR/../scripts/init-runtime.sh" "$@"

