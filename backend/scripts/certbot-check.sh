#!/bin/bash
# Certbot 证书检查脚本
# 检查证书状态和到期时间

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."

DOMAIN=${ALBUM_CERTBOT_DOMAIN:-}

if [ -z "$DOMAIN" ]; then
    echo "错误: 请设置 ALBUM_CERTBOT_DOMAIN 环境变量"
    exit 1
fi

CERT_DIR="data/cert/live/$DOMAIN"
CERT_FILE="$CERT_DIR/fullchain.pem"

if [ ! -f "$CERT_FILE" ]; then
    echo "错误: 证书文件不存在: $CERT_FILE"
    exit 1
fi

echo "=========================================="
echo "证书信息"
echo "=========================================="
echo "域名: $DOMAIN"
echo "证书路径: $CERT_FILE"
echo ""

# 检查证书有效期
if command -v openssl &> /dev/null; then
    echo "证书详情:"
    openssl x509 -in "$CERT_FILE" -noout -text | grep -A 2 "Validity"
    echo ""
    
    # 计算到期天数
    EXPIRY_DATE=$(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY_DATE" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$EXPIRY_DATE" +%s 2>/dev/null)
    CURRENT_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))
    
    echo "到期日期: $EXPIRY_DATE"
    echo "剩余天数: $DAYS_LEFT 天"
    
    if [ $DAYS_LEFT -lt 30 ]; then
        echo ""
        echo "⚠️  警告: 证书将在 30 天内到期，建议立即续期"
    elif [ $DAYS_LEFT -lt 60 ]; then
        echo ""
        echo "⚠️  提示: 证书将在 60 天内到期，建议准备续期"
    else
        echo ""
        echo "✅ 证书有效期正常"
    fi
else
    echo "提示: 未安装 openssl，无法显示证书详情"
fi

echo "=========================================="

