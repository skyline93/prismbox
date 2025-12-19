#!/bin/sh
set -e

# 注意：/var/www/certbot 是只读挂载，目录结构应在主机上创建
# 此脚本不尝试创建或修改该目录

# --- 1. 定义模板和目标文件路径 ---
TEMPLATE_FILE="/etc/nginx/templates/default.conf.template"
CONFIG_FILE="/etc/nginx/conf.d/default.conf"

# --- 2. 读取环境变量，设置默认值 ---
ENABLE_HTTPS=${ENABLE_HTTPS:-false}
SSL_CERT_PATH=${SSL_CERT_PATH:-/etc/nginx/ssl/cert.pem}
SSL_KEY_PATH=${SSL_KEY_PATH:-/etc/nginx/ssl/key.pem}
NGINX_ACCESS_LOG_LEVEL=${NGINX_ACCESS_LOG_LEVEL:-combined}
NGINX_ERROR_LOG_LEVEL=${NGINX_ERROR_LOG_LEVEL:-warn}
CLIENT_MAX_BODY_SIZE=${CLIENT_MAX_BODY_SIZE:-2G}

# 创建必要的目录并设置权限
mkdir -p /var/log/nginx /etc/nginx/conf.d /etc/nginx/snippets
chown -R nginx:nginx /var/log/nginx /etc/nginx/conf.d /etc/nginx/snippets 2>/dev/null || true
chmod -R 755 /var/log/nginx /etc/nginx/conf.d /etc/nginx/snippets

# 注意：/var/www/certbot 是只读挂载（:ro），目录结构应在主机上创建
# 不在此处创建或修改该目录，避免在只读文件系统上操作失败

# 确保 snippets 配置文件存在
# 1. 通用配置片段（注意：client_max_body_size 在模板中设置，这里不重复）
cat > /etc/nginx/snippets/common.conf << 'EOF'
client_body_buffer_size 1M;
client_header_buffer_size 512k;
large_client_header_buffers 4 512k;
client_body_timeout 3600s;
client_header_timeout 3600s;
keepalive_timeout 3600s;
send_timeout 3600s;
EOF

# 2. 代理通用配置片段
cat > /etc/nginx/snippets/proxy.conf << 'EOF'
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
proxy_set_header X-Forwarded-Host $http_host;
proxy_set_header X-Original-URI $request_uri;
proxy_intercept_errors on;
proxy_redirect off;
proxy_buffering off;
proxy_request_buffering off;
proxy_max_temp_file_size 0;
proxy_connect_timeout 3600s;
proxy_send_timeout 3600s;
proxy_read_timeout 3600s;
proxy_http_version 1.1;
EOF

# 3. CORS 通用配置片段
cat > /etc/nginx/snippets/cors.conf << 'EOF'
if ($request_method = 'OPTIONS') {
    add_header Access-Control-Allow-Origin $http_origin always;
    add_header Access-Control-Allow-Headers "Origin,Content-Type,Accept,Authorization,X-Requested-With,X-XSRF-TOKEN";
    add_header Access-Control-Allow-Methods "GET,POST,OPTIONS,PUT,DELETE,PATCH";
    add_header Access-Control-Allow-Credentials true;
    add_header Access-Control-Max-Age 86400;
    add_header Content-Length 0;
    add_header Content-Type text/plain;
    return 204;
}
add_header Access-Control-Allow-Origin $http_origin always;
add_header Access-Control-Allow-Headers "Origin,Content-Type,Accept,Authorization,X-Requested-With,X-XSRF-TOKEN";
add_header Access-Control-Allow-Methods "GET,POST,OPTIONS,PUT,DELETE,PATCH";
add_header Access-Control-Allow-Credentials true always;
add_header Access-Control-Expose-Headers "Content-Disposition";
EOF

# 根据环境变量设置日志格式
if [ "$NGINX_ACCESS_LOG_LEVEL" = "json" ]; then
    export NGINX_ACCESS_LOG_FORMAT="json"
else
    export NGINX_ACCESS_LOG_FORMAT="combined"
fi

# 设置错误日志级别
echo "error_log /var/log/nginx/error.log $NGINX_ERROR_LOG_LEVEL;" > /etc/nginx/conf.d/error_log.conf

# --- 3. 根据 ENABLE_HTTPS 的值，定义配置片段 ---
if [ "$ENABLE_HTTPS" = "true" ]; then
    echo "HTTPS is enabled. Generating SSL configuration."

    # 检查证书
    if [ ! -f "$SSL_CERT_PATH" ] || [ ! -f "$SSL_KEY_PATH" ]; then
        echo "Error: ENABLE_HTTPS is true, but SSL certificates are not found."
        exit 1
    fi

    # 定义HTTPS模式下的变量
    export USER_LISTEN_DIRECTIVE="listen 443 ssl;"
    
    # 使用 heredoc 定义多行变量
    # HTTP 重定向块（包含 Let's Encrypt 验证路径和 HTTPS 重定向）
    export HTTP_REDIRECT_BLOCK=$(cat <<EOF
server {
    listen 80;
    server_name _ "";
    
    # Let's Encrypt 验证路径
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # 其他请求重定向到 HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF
)
    export SSL_CONFIG_BLOCK=$(cat <<EOF
    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_KEY_PATH};
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
EOF
)
else
    echo "HTTPS is disabled. Generating HTTP-only configuration."

    # 定义HTTP模式下的变量
    # 注意：acme-challenge 路径在 default.conf.template 的 server 块中已配置，无需在此设置
    export USER_LISTEN_DIRECTIVE="listen 80;"
    export HTTP_REDIRECT_BLOCK=""
    export SSL_CONFIG_BLOCK=""
fi

# --- 4. 使用 envsubst 生成最终配置 ---
# 指定所有需要替换的变量
VARS_TO_SUBSTITUTE='$USER_LISTEN_DIRECTIVE $HTTP_REDIRECT_BLOCK $SSL_CONFIG_BLOCK $NGINX_ACCESS_LOG_FORMAT $SSL_CERT_PATH $SSL_KEY_PATH $CLIENT_MAX_BODY_SIZE'
envsubst "$VARS_TO_SUBSTITUTE" < "$TEMPLATE_FILE" > "$CONFIG_FILE"

# --- 4.5. 确保 acme-challenge 路径存在（用于证书初始化，无论是否启用 HTTPS） ---
# 如果配置文件中没有 acme-challenge 路径，则添加它
if ! grep -q "acme-challenge" "$CONFIG_FILE"; then
    echo "Adding acme-challenge location block to Nginx config..."
    # 在 include proxy.conf 之后、location /api 之前插入
    # 使用 sed 的插入功能
    if grep -q "location /api" "$CONFIG_FILE"; then
        # 在 location /api 之前插入
        sed -i '/^[[:space:]]*location \/api {/i\
    # Let'\''s Encrypt 验证路径（用于证书初始化，无论是否启用 HTTPS）\
    location /.well-known/acme-challenge/ {\
        root /var/www/certbot;\
        try_files $uri =404;\
    }\
' "$CONFIG_FILE"
    elif grep -q "include /etc/nginx/snippets/proxy.conf;" "$CONFIG_FILE"; then
        # 如果找不到 location /api，在 include proxy.conf 之后添加
        sed -i '/include \/etc\/nginx\/snippets\/proxy.conf;/a\
\
    # Let'\''s Encrypt 验证路径（用于证书初始化，无论是否启用 HTTPS）\
    location /.well-known/acme-challenge/ {\
        root /var/www/certbot;\
        try_files $uri =404;\
    }\
' "$CONFIG_FILE"
    fi
fi

echo "--- Generated Nginx Config (${CONFIG_FILE}) ---"
cat ${CONFIG_FILE}
echo "-------------------------------------------"

# --- 5. 启动 Nginx ---
exec "$@"
