# 18. HTTPS 架构设计

## 18.1 概述

本文档描述了 Album 项目的 HTTPS 架构设计，包括后端服务和移动端客户端的 HTTPS 支持方案。HTTPS 是生产环境部署的必需功能，确保数据传输的安全性和完整性。

### 设计目标

- **安全性**：使用 TLS 1.2/1.3 加密传输，防止数据泄露和中间人攻击
- **低成本**：采用 Let's Encrypt 免费证书，降低运维成本
- **自动化**：证书自动获取和续期，减少人工维护
- **易部署**：与现有 Docker Compose 架构无缝集成
- **最佳实践**：符合行业安全标准和最佳实践

### 架构概览

```
┌─────────────────────────────────────────────────────────┐
│                    客户端层                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ 移动端 App   │  │  Web 前端    │  │  其他客户端  │  │
│  │ (Flutter)    │  │              │  │              │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                  │                  │          │
│         └──────────────────┼──────────────────┘          │
│                            │ HTTPS (TLS 1.2/1.3)        │
└────────────────────────────┼────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                   反向代理层                             │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Nginx (443/80)                                  │   │
│  │  - SSL/TLS 终止                                  │   │
│  │  - HTTP → HTTPS 重定向                           │   │
│  │  - CORS 处理                                     │   │
│  │  - 大文件上传/下载                               │   │
│  └──────────────┬───────────────────────────────────┘   │
└─────────────────┼───────────────────────────────────────┘
                  │ HTTP (内部)
                  ▼
┌─────────────────────────────────────────────────────────┐
│                   应用服务层                             │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Album Backend (Go + Gin)                        │   │
│  │  - API 服务 (8080)                               │   │
│  │  - 业务逻辑处理                                   │   │
│  └──────────────┬───────────────────────────────────┘   │
└─────────────────┼───────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────┐
│                   证书管理                               │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Certbot 容器                                    │   │
│  │  - Let's Encrypt 证书获取                        │   │
│  │  - 自动续期 (每 12 小时检查)                     │   │
│  │  - 证书存储到共享卷                              │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## 18.2 后端 HTTPS 架构设计

### 18.2.1 架构组件

后端 HTTPS 架构由以下组件组成：

1. **Nginx 反向代理**：处理 SSL/TLS 终止和 HTTP 到 HTTPS 重定向
2. **Certbot 容器**：自动获取和续期 Let's Encrypt 证书
3. **证书存储卷**：共享证书目录，供 Nginx 和 Certbot 使用
4. **Go 后端服务**：处理业务逻辑（内部使用 HTTP）

### 18.2.2 证书管理方案

#### 方案选择：Let's Encrypt + Certbot

**优势**：
- ✅ **免费**：Let's Encrypt 提供免费 SSL 证书
- ✅ **自动化**：Certbot 自动获取和续期证书
- ✅ **标准兼容**：符合行业标准，被所有主流浏览器信任
- ✅ **易于部署**：与 Docker Compose 无缝集成

**证书特性**：
- 有效期：90 天
- 自动续期：Certbot 每 12 小时检查，到期前 30 天自动续期
- 支持域名：单域名、多域名、通配符域名

#### 证书获取流程

```
1. Certbot 容器启动
   ↓
2. 检查证书是否存在
   ↓
3. 如果不存在，使用 Let's Encrypt API 获取证书
   - HTTP-01 验证（通过 Nginx 80 端口）
   - 或 DNS-01 验证（通过 DNS TXT 记录）
   ↓
4. 证书保存到共享卷 /etc/nginx/ssl/
   ↓
5. Nginx 重新加载配置
```

#### 证书续期流程

```
1. Certbot 定时任务（每 12 小时）
   ↓
2. 检查证书到期时间
   ↓
3. 如果剩余时间 < 30 天，执行续期
   ↓
4. 更新证书文件
   ↓
5. 通知 Nginx 重新加载配置
```

### 18.2.3 Nginx SSL/TLS 配置

#### SSL 配置参数

```nginx
# SSL 证书配置
ssl_certificate /etc/nginx/ssl/cert.pem;
ssl_certificate_key /etc/nginx/ssl/key.pem;

# SSL 会话配置
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;

# SSL 协议和加密套件
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;

# OCSP Stapling（可选，提升性能）
ssl_stapling on;
ssl_stapling_verify on;
ssl_trusted_certificate /etc/nginx/ssl/chain.pem;

# HSTS（可选，增强安全）
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

#### HTTP 到 HTTPS 重定向

```nginx
# HTTP 服务器块（80 端口）
server {
    listen 80;
    server_name api.example.com;
    
    # Let's Encrypt 验证路径（Certbot 使用）
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    # 其他请求重定向到 HTTPS
    location / {
        return 301 https://$host$request_uri;
    }
}

# HTTPS 服务器块（443 端口）
server {
    listen 443 ssl;
    server_name api.example.com;
    
    # SSL 配置（见上文）
    # ...
    
    # API 反向代理
    location /api {
        proxy_pass http://album-backend:8080;
        # ... 其他代理配置
    }
}
```

### 18.2.4 Docker Compose 配置

#### 服务定义

```yaml
services:
  # Certbot 证书管理服务
  certbot:
    image: certbot/certbot:latest
    container_name: album-certbot
    volumes:
      - ./data/cert:/etc/letsencrypt
      - ./data/certbot-www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
    networks:
      - album-network

  # Nginx 反向代理
  nginx:
    image: registry.cn-shenzhen.aliyuncs.com/greene/album-nginx:latest-${ALBUM_ARCH:-amd64}
    restart: always
    container_name: album-nginx
    depends_on:
      - album-backend
      - certbot
    ports:
      - "${ALBUM_HTTP_PORT:-80}:80"
      - "${ALBUM_HTTPS_PORT:-443}:443"
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/etc/timezone:/etc/timezone:ro"
      - "./data/cert:/etc/nginx/ssl:ro"
      - "./data/certbot-www:/var/www/certbot:ro"
      - "./data/logs/nginx:/var/log/nginx"
    environment:
      - ENABLE_HTTPS=${ALBUM_ENABLE_HTTPS:-false}
      - SSL_CERT_PATH=${ALBUM_SSL_CERT_PATH:-/etc/nginx/ssl/cert.pem}
      - SSL_KEY_PATH=${ALBUM_SSL_KEY_PATH:-/etc/nginx/ssl/key.pem}
      - NGINX_ACCESS_LOG_LEVEL=${ALBUM_NGINX_ACCESS_LOG_LEVEL:-combined}
      - NGINX_ERROR_LOG_LEVEL=${ALBUM_NGINX_ERROR_LOG_LEVEL:-warn}
      - CLIENT_MAX_BODY_SIZE=${ALBUM_NGINX_CLIENT_MAX_BODY_SIZE:-2G}
    networks:
      - album-network

  # Album Backend 服务（内部使用 HTTP）
  album-backend:
    # ... 现有配置保持不变
    expose:
      - "8080"  # 仅内部访问，不暴露端口
```

#### 环境变量配置

```bash
# HTTPS 启用开关
ALBUM_ENABLE_HTTPS=true

# 证书路径（容器内路径）
ALBUM_SSL_CERT_PATH=/etc/nginx/ssl/cert.pem
ALBUM_SSL_KEY_PATH=/etc/nginx/ssl/key.pem

# Certbot 配置
ALBUM_CERTBOT_EMAIL=admin@example.com
ALBUM_CERTBOT_DOMAIN=api.example.com
ALBUM_CERTBOT_STAGING=false  # 生产环境设为 false

# 服务器地址配置
ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com
```

### 18.2.5 证书初始化脚本

#### 首次获取证书

```bash
#!/bin/bash
# scripts/certbot-init.sh

set -e

DOMAIN=${ALBUM_CERTBOT_DOMAIN:-api.example.com}
EMAIL=${ALBUM_CERTBOT_EMAIL:-admin@example.com}
STAGING=${ALBUM_CERTBOT_STAGING:-false}

# 选择 Let's Encrypt 环境
if [ "$STAGING" = "true" ]; then
    SERVER="--staging"
else
    SERVER=""
fi

# 获取证书
docker-compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN" \
    $SERVER

# 复制证书到 Nginx 使用的目录
cp data/cert/live/$DOMAIN/fullchain.pem data/cert/cert.pem
cp data/cert/live/$DOMAIN/privkey.pem data/cert/key.pem

# 重新加载 Nginx
docker-compose exec nginx nginx -s reload

echo "证书获取成功！"
```

### 18.2.6 安全最佳实践

#### SSL/TLS 配置

1. **协议版本**：仅启用 TLS 1.2 和 TLS 1.3
2. **加密套件**：使用现代加密套件（ECDHE、AES-GCM、ChaCha20-Poly1305）
3. **会话复用**：启用 SSL 会话缓存，提升性能
4. **OCSP Stapling**：启用 OCSP Stapling，减少证书验证延迟
5. **HSTS**：启用 HSTS，强制客户端使用 HTTPS

#### 证书安全

1. **私钥权限**：证书私钥文件权限设置为 600
2. **证书备份**：定期备份证书文件
3. **证书监控**：监控证书到期时间，提前告警
4. **证书轮换**：支持证书无缝轮换，避免服务中断

#### 网络安全

1. **防火墙规则**：仅开放必要的端口（80、443）
2. **DDoS 防护**：配置 Nginx 限流和 DDoS 防护
3. **访问日志**：记录所有 HTTPS 访问日志，便于审计
4. **错误处理**：隐藏敏感错误信息，防止信息泄露

### 18.2.7 监控和告警

#### 证书监控

- **到期时间监控**：证书到期前 30 天告警
- **续期状态监控**：续期失败告警
- **证书有效性监控**：定期验证证书有效性

#### 性能监控

- **SSL 握手时间**：监控 SSL 握手延迟
- **HTTPS 请求成功率**：监控 HTTPS 请求成功率
- **证书验证时间**：监控 OCSP Stapling 验证时间

## 18.3 移动端 HTTPS 架构设计

### 18.3.1 架构组件

移动端 HTTPS 架构由以下组件组成：

1. **Flutter HTTP 客户端（Dio）**：处理 HTTPS 请求
2. **API 配置管理**：管理服务器地址和协议
3. **网络安全配置**：Android 和 iOS 平台特定的网络安全策略
4. **证书验证**：可选的 SSL Pinning 增强安全性

### 18.3.2 API 配置设计

#### 配置结构

```dart
// lib/config/app_config.dart
class AppConfig {
  AppConfig._();
  static const ApiConfig api = ApiConfig();
}

class ApiConfig {
  const ApiConfig();
  
  // 默认服务器地址（生产环境使用 HTTPS）
  static const String defaultServerAddr = 'https://api.example.com';
  
  // 开发环境备用地址
  // static const String defaultServerAddr = 'https://47.107.63.140';
  // static const String defaultServerAddr = 'http://10.0.2.2';  // Android 模拟器
  
  // 支持从本地存储读取自定义服务器地址
  static Future<String> getServerAddr() async {
    // 从 SharedPreferences 或 SecureStorage 读取
    // 如果没有配置，使用默认地址
    final prefs = await SharedPreferences.getInstance();
    final customAddr = prefs.getString('server_address');
    return customAddr ?? defaultServerAddr;
  }
  
  // 动态获取 baseUrl
  static Future<String> get baseUrl async {
    final serverAddr = await getServerAddr();
    return '$serverAddr/api/v1';
  }
}
```

#### 服务器地址配置服务

```dart
// lib/services/server_config_service.dart
@lazySingleton
class ServerConfigService {
  final SharedPreferences _prefs;
  
  ServerConfigService(this._prefs);
  
  // 获取服务器地址
  Future<String> getServerAddress() async {
    return _prefs.getString('server_address') ?? 
           ApiConfig.defaultServerAddr;
  }
  
  // 设置服务器地址
  Future<void> setServerAddress(String address) async {
    // 验证地址格式
    if (!_isValidUrl(address)) {
      throw ArgumentError('Invalid server address format');
    }
    
    // 测试连接
    if (!await _testConnection(address)) {
      throw Exception('Cannot connect to server');
    }
    
    await _prefs.setString('server_address', address);
  }
  
  // 验证 URL 格式
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
  
  // 测试连接
  Future<bool> _testConnection(String address) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 5);
      final response = await dio.get('$address/api/v1/version');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
```

### 18.3.3 Dio HTTP 客户端配置

#### 基础 HTTPS 配置

```dart
// lib/data/services/dio_client.dart
@lazySingleton
class DioClient {
  final Dio dio;
  final Dio fileDio;
  final SecureStorageService _storage;
  
  DioClient(this._storage) : dio = Dio(), fileDio = Dio() {
    _initDio();
  }
  
  Future<void> _initDio() async {
    // 获取动态 baseUrl
    final baseUrl = await ApiConfig.baseUrl;
    
    // 配置常规 API 的 Dio 实例
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(minutes: 30);
    dio.options.responseType = ResponseType.json;
    
    // 配置 HTTPS 验证（默认信任系统证书）
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      // 默认信任系统证书，Let's Encrypt 证书会被自动信任
      return client;
    };
    
    // 添加拦截器
    dio.interceptors.addAll([
      _createAuthInterceptor(),
      RetryInterceptor(/* ... */),
      LogInterceptor(/* ... */),
    ]);
    
    // 配置文件传输的 Dio 实例
    fileDio.options.connectTimeout = const Duration(seconds: 60);
    fileDio.options.receiveTimeout = const Duration(minutes: 30);
    // ... 类似配置
  }
}
```

#### SSL Pinning 配置（可选）

```dart
// lib/data/services/dio_client.dart
// 增强安全：SSL Certificate Pinning

Future<void> _initDio() async {
  // ... 基础配置
  
  // 配置 SSL Pinning
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // 验证证书指纹
      return _verifyCertificate(cert, host);
    };
    return client;
  };
}

bool _verifyCertificate(X509Certificate cert, String host) {
  // 获取证书的 SHA-256 指纹
  final fingerprint = _getCertificateFingerprint(cert);
  
  // 预期的证书指纹（从服务器证书获取）
  const expectedFingerprints = [
    'SHA256:XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', // 替换为实际指纹
  ];
  
  return expectedFingerprints.contains(fingerprint);
}

String _getCertificateFingerprint(X509Certificate cert) {
  // 计算证书的 SHA-256 指纹
  // 实现细节...
}
```

### 18.3.4 Android 网络安全配置

#### Network Security Config

```xml
<!-- android/app/src/main/res/xml/network_security_config.xml -->
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- 生产环境：仅允许 HTTPS -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <!-- 信任系统证书（包括 Let's Encrypt） -->
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    
    <!-- 开发环境：如果需要支持 HTTP，可以添加特定域名 -->
    <!-- 
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
        <domain includeSubdomains="true">localhost</domain>
    </domain-config>
    -->
    
    <!-- 生产环境：可以添加特定域名的证书配置 -->
    <!--
    <domain-config>
        <domain includeSubdomains="true">api.example.com</domain>
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />  <!-- 如果使用自定义证书 -->
        </trust-anchors>
    </domain-config>
    -->
</network-security-config>
```

#### AndroidManifest.xml 配置

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<application
    android:label="mobile"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:networkSecurityConfig="@xml/network_security_config"
    android:enableOnBackInvokedCallback="true">
    <!-- ... -->
</application>
```

### 18.3.5 iOS App Transport Security 配置

#### Info.plist 配置

```xml
<!-- ios/Runner/Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <!-- 生产环境：禁用任意加载，仅允许 HTTPS -->
    <!-- 移除 NSAllowsArbitraryLoads -->
    
    <!-- 开发环境：如果需要支持 HTTP，可以添加特定域名例外 -->
    <!--
    <key>NSExceptionDomains</key>
    <dict>
        <key>localhost</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key>127.0.0.1</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
    -->
    
    <!-- 生产环境：可以添加特定域名的配置 -->
    <!--
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.example.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
            <key>NSExceptionMinimumTLSVersion</key>
            <string>TLSv1.2</string>
        </dict>
    </dict>
    -->
</dict>
```

### 18.3.6 错误处理

#### HTTPS 连接错误处理

```dart
// lib/data/services/dio_client.dart
Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
  // 处理 HTTPS 相关错误
  if (e.type == DioExceptionType.connectionError) {
    // 网络连接错误
    if (e.message?.contains('SSL') == true || 
        e.message?.contains('certificate') == true) {
      // SSL 证书错误
      log('SSL certificate error: ${e.message}');
      // 可以提示用户检查服务器证书
    }
  }
  
  // ... 其他错误处理
}
```

#### 用户友好的错误提示

```dart
// lib/utils/error_handler.dart
class ErrorHandler {
  static String getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return '连接超时，请检查网络连接';
      case DioExceptionType.sendTimeout:
        return '发送请求超时';
      case DioExceptionType.receiveTimeout:
        return '接收响应超时';
      case DioExceptionType.connectionError:
        if (error.message?.contains('SSL') == true) {
          return 'SSL 证书验证失败，请检查服务器配置';
        }
        return '网络连接失败，请检查网络设置';
      case DioExceptionType.badResponse:
        return '服务器响应错误：${error.response?.statusCode}';
      default:
        return '网络请求失败：${error.message}';
    }
  }
}
```

### 18.3.7 迁移方案

#### 从 HTTP 迁移到 HTTPS

1. **阶段一：配置更新**
   - 更新 `ApiConfig.defaultServerAddr` 为 HTTPS 地址
   - 更新 Android `network_security_config.xml`
   - 更新 iOS `Info.plist`

2. **阶段二：测试验证**
   - 测试 HTTPS 连接
   - 测试 API 请求
   - 测试文件上传/下载
   - 测试 Token 刷新

3. **阶段三：发布更新**
   - 发布新版本 App
   - 监控错误日志
   - 收集用户反馈

#### 向后兼容

- 支持用户自定义服务器地址（开发环境）
- 提供 HTTP/HTTPS 切换选项（仅开发环境）
- 平滑迁移，不影响现有用户

## 18.4 部署流程

### 18.4.1 后端 HTTPS 部署

#### 首次部署步骤

```bash
# 1. 设置环境变量
export ALBUM_ENABLE_HTTPS=true
export ALBUM_CERTBOT_EMAIL=admin@example.com
export ALBUM_CERTBOT_DOMAIN=api.example.com
export ALBUM_SERVER_PUBLIC_BASE_URL=https://api.example.com

# 2. 创建证书目录
mkdir -p data/cert data/certbot-www

# 3. 首次获取证书（测试环境）
export ALBUM_CERTBOT_STAGING=true
./scripts/certbot-init.sh

# 4. 验证证书后，切换到生产环境
export ALBUM_CERTBOT_STAGING=false
./scripts/certbot-init.sh

# 5. 启动服务
docker-compose up -d

# 6. 验证 HTTPS
curl https://api.example.com/api/v1/version
```

#### 证书续期

证书续期由 Certbot 容器自动处理，无需手动干预。续期流程：

1. Certbot 每 12 小时检查证书到期时间
2. 如果剩余时间 < 30 天，自动续期
3. 更新证书文件后，通知 Nginx 重新加载配置

### 18.4.2 移动端 HTTPS 部署

#### 配置更新步骤

1. **更新 API 配置**
   ```dart
   // lib/config/app_config.dart
   static const String defaultServerAddr = 'https://api.example.com';
   ```

2. **更新 Android 配置**
   ```xml
   <!-- 移除 cleartextTrafficPermitted="true" -->
   ```

3. **更新 iOS 配置**
   ```xml
   <!-- 移除 NSAllowsArbitraryLoads -->
   ```

4. **测试验证**
   - 运行 App，测试 HTTPS 连接
   - 验证所有 API 请求正常
   - 验证文件上传/下载正常

5. **发布更新**
   - 构建发布版本
   - 提交到应用商店

## 18.5 故障排查

### 18.5.1 后端 HTTPS 问题

#### 证书获取失败

**问题**：Certbot 无法获取证书

**排查步骤**：
1. 检查域名 DNS 解析是否正确
2. 检查 80 端口是否可访问（HTTP-01 验证需要）
3. 检查防火墙规则
4. 查看 Certbot 日志：`docker-compose logs certbot`

**解决方案**：
- 使用 DNS-01 验证（需要 DNS API 访问权限）
- 检查 Let's Encrypt 速率限制

#### 证书续期失败

**问题**：证书续期失败

**排查步骤**：
1. 检查 Certbot 容器是否运行
2. 检查证书目录权限
3. 查看 Certbot 日志

**解决方案**：
- 手动执行续期：`docker-compose exec certbot certbot renew`
- 检查证书目录权限：`chmod 755 data/cert`

#### Nginx SSL 错误

**问题**：Nginx 无法加载 SSL 证书

**排查步骤**：
1. 检查证书文件是否存在
2. 检查证书文件权限
3. 检查 Nginx 配置语法：`docker-compose exec nginx nginx -t`

**解决方案**：
- 确保证书文件路径正确
- 设置正确的文件权限：`chmod 600 data/cert/key.pem`

### 18.5.2 移动端 HTTPS 问题

#### Android SSL 错误

**问题**：Android App 无法连接 HTTPS 服务器

**排查步骤**：
1. 检查 `network_security_config.xml` 配置
2. 检查系统时间是否正确
3. 查看 Logcat 日志

**解决方案**：
- 确保 `cleartextTrafficPermitted="false"`
- 检查系统证书是否包含 Let's Encrypt 根证书
- 更新 Android 系统（旧版本可能不支持 Let's Encrypt）

#### iOS SSL 错误

**问题**：iOS App 无法连接 HTTPS 服务器

**排查步骤**：
1. 检查 `Info.plist` 配置
2. 检查系统时间是否正确
3. 查看 Xcode 控制台日志

**解决方案**：
- 确保移除 `NSAllowsArbitraryLoads`
- 检查 iOS 版本（iOS 9+ 支持 Let's Encrypt）
- 验证服务器证书链完整性

#### 证书验证失败

**问题**：SSL Pinning 验证失败

**排查步骤**：
1. 检查证书指纹是否正确
2. 检查服务器证书是否更新
3. 查看错误日志

**解决方案**：
- 更新证书指纹
- 临时禁用 SSL Pinning（仅用于调试）
- 使用证书链验证而非单个证书验证

## 18.6 性能优化

### 18.6.1 后端性能优化

1. **SSL 会话复用**：启用 SSL 会话缓存，减少握手次数
2. **OCSP Stapling**：启用 OCSP Stapling，减少证书验证延迟
3. **HTTP/2**：启用 HTTP/2，提升传输效率
4. **证书缓存**：缓存证书验证结果，减少验证时间

### 18.6.2 移动端性能优化

1. **连接复用**：Dio 自动复用 HTTP 连接
2. **请求合并**：合并多个小请求，减少握手次数
3. **缓存策略**：合理使用 HTTP 缓存，减少请求次数

## 18.7 安全最佳实践总结

### 后端安全

- ✅ 使用 TLS 1.2/1.3
- ✅ 使用现代加密套件
- ✅ 启用 HSTS
- ✅ 启用 OCSP Stapling
- ✅ 定期更新证书
- ✅ 监控证书到期时间

### 移动端安全

- ✅ 仅允许 HTTPS 连接（生产环境）
- ✅ 验证服务器证书
- ✅ 可选 SSL Pinning（增强安全）
- ✅ 错误信息不泄露敏感信息
- ✅ 定期更新 App

## 18.8 相关文档

- [7.8 API 模块架构设计](./07-core-modules/07-api-architecture.md) - API 模块的架构设计
- [14. 安全考虑](./14-security.md) - 安全相关设计
- [16. 部署流程](./16-deployment.md) - 部署相关文档
- [部署文档](../DEPLOYMENT/README.md) - 完整的部署指南

