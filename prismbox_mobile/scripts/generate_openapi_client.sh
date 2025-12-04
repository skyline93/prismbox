#!/bin/bash

# OpenAPI客户端生成脚本
# 从swagger.yaml生成Dart客户端代码

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BACKEND_DIR="$PROJECT_ROOT/../backend"
SWAGGER_FILE="$BACKEND_DIR/docs/swagger/swagger.yaml"
OUTPUT_DIR="$PROJECT_ROOT/lib/infrastructure/api/generated"

echo "生成OpenAPI客户端..."
echo "Swagger文件: $SWAGGER_FILE"
echo "输出目录: $OUTPUT_DIR"

# 检查swagger文件是否存在
if [ ! -f "$SWAGGER_FILE" ]; then
    echo "错误: Swagger文件不存在: $SWAGGER_FILE"
    exit 1
fi

# 创建输出目录
mkdir -p "$OUTPUT_DIR"

# 检查是否安装了openapi-generator-cli
if ! command -v openapi-generator-cli &> /dev/null; then
    echo "错误: openapi-generator-cli未安装"
    echo "请先安装: npm install -g @openapitools/openapi-generator-cli"
    exit 1
fi

# 生成Dart客户端
openapi-generator-cli generate \
    -i "$SWAGGER_FILE" \
    -g dart \
    -o "$OUTPUT_DIR" \
    --additional-properties=pubName=prismbox_api,pubVersion=1.0.0,enumUnknownDefaultCase=true

# 修复导入路径：将 package:prismbox_api 替换为正确的路径
echo "修复导入路径..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    find "$OUTPUT_DIR" -name "*.dart" -type f -exec sed -i '' 's|package:prismbox_api/api\.dart|package:prismbox/infrastructure/api/generated/lib/api.dart|g' {} +
    find "$OUTPUT_DIR" -name "*.dart" -type f -exec sed -i '' 's|package:prismbox_api/|package:prismbox/infrastructure/api/generated/|g' {} +
else
    # Linux
    find "$OUTPUT_DIR" -name "*.dart" -type f -exec sed -i 's|package:prismbox_api/api\.dart|package:prismbox/infrastructure/api/generated/lib/api.dart|g' {} +
    find "$OUTPUT_DIR" -name "*.dart" -type f -exec sed -i 's|package:prismbox_api/|package:prismbox/infrastructure/api/generated/|g' {} +
fi

echo "OpenAPI客户端生成完成！"
echo "输出目录: $OUTPUT_DIR"