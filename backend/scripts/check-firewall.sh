#!/bin/bash
# 防火墙和网络检查脚本

echo "=========================================="
echo "网络和防火墙检查"
echo "=========================================="

# 1. 检查服务器 IP
echo ""
echo "1. 服务器 IP 地址："
if command -v ifconfig >/dev/null 2>&1; then
    ifconfig | grep -A 1 "inet " | grep -v "127.0.0.1"
elif command -v ip >/dev/null 2>&1; then
    ip addr show | grep "inet " | grep -v "127.0.0.1"
else
    echo "无法获取 IP 地址"
fi

# 2. 检查 80 端口监听
echo ""
echo "2. 80 端口监听状态："
if command -v netstat >/dev/null 2>&1; then
    netstat -tuln | grep ":80 " || echo "80 端口未监听"
elif command -v ss >/dev/null 2>&1; then
    ss -tuln | grep ":80 " || echo "80 端口未监听"
elif command -v lsof >/dev/null 2>&1; then
    lsof -i :80 || echo "80 端口未监听"
else
    echo "无法检查端口状态"
fi

# 3. 检查 Docker 容器端口映射
echo ""
echo "3. Docker 容器端口映射："
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -E "nginx|80"

# 4. 检查防火墙状态（Linux）
if [ "$(uname)" != "Darwin" ]; then
    echo ""
    echo "4. 防火墙状态："
    if command -v firewall-cmd >/dev/null 2>&1; then
        echo "firewalld 状态："
        sudo firewall-cmd --list-all 2>/dev/null || echo "需要 sudo 权限查看"
    elif command -v ufw >/dev/null 2>&1; then
        echo "ufw 状态："
        sudo ufw status 2>/dev/null || echo "需要 sudo 权限查看"
    elif command -v iptables >/dev/null 2>&1; then
        echo "iptables 80 端口规则："
        sudo iptables -L -n | grep ":80 " 2>/dev/null || echo "需要 sudo 权限查看"
    fi
fi

# 5. 本地测试
echo ""
echo "5. 本地访问测试："
curl -s -o /dev/null -w "HTTP 状态码: %{http_code}\n" http://localhost/.well-known/acme-challenge/test-file 2>/dev/null || echo "本地访问失败"

# 6. 域名解析
echo ""
echo "6. 域名解析（如果设置了 ALBUM_CERTBOT_DOMAIN）："
DOMAIN=${ALBUM_CERTBOT_DOMAIN:-}
if [ -n "$DOMAIN" ]; then
    echo "域名: $DOMAIN"
    nslookup $DOMAIN 2>/dev/null | grep -A 2 "Name:" || dig +short $DOMAIN 2>/dev/null || echo "无法解析域名"
else
    echo "未设置 ALBUM_CERTBOT_DOMAIN"
fi

echo ""
echo "=========================================="
echo "检查完成"
echo "=========================================="
echo ""
echo "如果外网无法访问，请检查："
echo "1. 云服务商安全组是否开放 80 端口（入站规则）"
echo "2. 服务器防火墙是否允许 80 端口"
echo "3. 如果服务器在内网，检查 NAT/端口映射配置"
echo "4. 确认域名解析的 IP 地址正确指向服务器"

