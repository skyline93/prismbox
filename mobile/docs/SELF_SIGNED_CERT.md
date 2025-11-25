# 自签名证书配置指南

本文档说明如何在移动端应用中处理自签名证书（仅用于开发/测试环境）。

## ⚠️ 重要提示

**自签名证书仅用于开发/测试环境，生产环境应使用 Let's Encrypt 或其他受信任的 CA 颁发的证书。**

## Android 配置

### 方式一：信任特定域名的自签名证书（推荐）

1. **将服务器证书添加到项目中**

```bash
# 从服务器获取证书
openssl s_client -showcerts -connect YOUR_SERVER_IP:443 </dev/null 2>/dev/null | \
  openssl x509 -outform PEM > mobile/android/app/src/main/res/raw/server_cert.pem
```

或者直接复制证书文件：
```bash
cp backend/deploy/data/cert/cert.pem mobile/android/app/src/main/res/raw/server_cert.pem
```

2. **更新 network_security_config.xml**

编辑 `mobile/android/app/src/main/res/xml/network_security_config.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <!-- 信任系统证书 -->
            <certificates src="system" />
            <!-- 信任用户添加的证书（包括自签名证书） -->
            <certificates src="user" />
        </trust-anchors>
    </base-config>
    
    <!-- 开发环境：信任特定域名的自签名证书 -->
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">47.107.63.140</domain>
        <domain includeSubdomains="true">YOUR_DOMAIN.com</domain>
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
            <!-- 信任项目中的证书文件 -->
            <certificates src="@raw/server_cert" />
        </trust-anchors>
    </domain-config>
</network-security-config>
```

### 方式二：仅开发环境允许所有自签名证书（不推荐）

**仅用于开发/测试，不要用于生产环境！**

编辑 `mobile/android/app/src/main/res/xml/network_security_config.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- 开发环境：允许所有自签名证书（仅用于测试） -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </base-config>
    
    <!-- 特定域名配置 -->
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">47.107.63.140</domain>
        <domain includeSubdomains="true">YOUR_DOMAIN.com</domain>
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
        </trust-anchors>
    </domain-config>
</network-security-config>
```

**注意**：用户需要在设备上手动安装证书（设置 → 安全 → 加密与凭据 → 从存储设备安装）

## iOS 配置

### 方式一：为特定域名添加 ATS 例外（推荐）

编辑 `mobile/ios/Runner/Info.plist`：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- 为特定域名添加例外 -->
    <key>NSExceptionDomains</key>
    <dict>
        <!-- 服务器 IP 地址 -->
        <key>47.107.63.140</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
            <!-- 允许自签名证书 -->
            <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
        
        <!-- 如果有域名 -->
        <key>YOUR_DOMAIN.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 方式二：仅开发环境允许所有自签名证书（不推荐）

**仅用于开发/测试，不要用于生产环境！**

编辑 `mobile/ios/Runner/Info.plist`：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- 开发环境：允许所有自签名证书（仅用于测试） -->
    <key>NSAllowsArbitraryLoads</key>
    <true/>
    
    <!-- 或者为特定域名添加例外 -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>47.107.63.140</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**注意**：iOS 需要在设备上手动安装证书（设置 → 通用 → VPN与设备管理 → 安装描述文件）

## Flutter/Dio 配置

### 方式一：仅开发环境忽略 SSL 验证（推荐）

修改 `mobile/lib/data/services/dio_client.dart`：

```dart
import 'dart:io';
import 'package:dio/io.dart';

// 在 DioClient 构造函数中添加
DioClient(this._storage) : dio = Dio(), fileDio = Dio() {
  // ... 现有代码 ...
  
  // 仅开发环境：忽略 SSL 证书验证（自签名证书）
  if (kDebugMode) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 仅允许特定 IP/域名的自签名证书
        return host == '47.107.63.140' || host.contains('YOUR_DOMAIN.com');
      };
      return client;
    };
    
    (fileDio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        return host == '47.107.63.140' || host.contains('YOUR_DOMAIN.com');
      };
      return client;
    };
  }
}
```

### 方式二：使用环境变量控制

创建环境配置文件：

```dart
// lib/config/env_config.dart
class EnvConfig {
  static const bool isDevelopment = bool.fromEnvironment('DEVELOPMENT', defaultValue: false);
  static const bool allowSelfSignedCert = bool.fromEnvironment('ALLOW_SELF_SIGNED_CERT', defaultValue: false);
}
```

在 DioClient 中使用：

```dart
if (EnvConfig.allowSelfSignedCert) {
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) => true; // 仅开发环境
    return client;
  };
}
```

## 完整配置示例

### Android 完整配置

`mobile/android/app/src/main/res/xml/network_security_config.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <!-- 生产环境：仅允许 HTTPS 和系统信任的证书 -->
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    
    <!-- 开发环境：允许特定域名的自签名证书 -->
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">47.107.63.140</domain>
        <domain includeSubdomains="true">api.example.com</domain>
        <trust-anchors>
            <certificates src="system" />
            <certificates src="user" />
            <!-- 如果添加了证书文件 -->
            <certificates src="@raw/server_cert" />
        </trust-anchors>
    </domain-config>
</network-security-config>
```

### iOS 完整配置

`mobile/ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <!-- 生产环境：不允许任意加载 -->
    <!-- 开发环境：为特定域名添加例外 -->
    <key>NSExceptionDomains</key>
    <dict>
        <key>47.107.63.140</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
        <key>api.example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### Flutter/Dio 完整配置

`mobile/lib/data/services/dio_client.dart`:

```dart
import 'dart:io';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

// 在 DioClient 构造函数中
DioClient(this._storage) : dio = Dio(), fileDio = Dio() {
  // ... 现有初始化代码 ...
  
  // 仅开发环境：配置自签名证书处理
  if (kDebugMode) {
    _configureSelfSignedCert(dio);
    _configureSelfSignedCert(fileDio);
  }
}

void _configureSelfSignedCert(Dio dioInstance) {
  (dioInstance.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // 仅允许特定 IP/域名的自签名证书
      final allowedHosts = ['47.107.63.140', 'api.example.com'];
      return allowedHosts.contains(host);
    };
    return client;
  };
}
```

## 测试步骤

1. **更新配置**：根据上述说明更新 Android/iOS/Flutter 配置
2. **重新构建应用**：
   ```bash
   cd mobile
   flutter clean
   flutter pub get
   flutter build apk  # Android
   flutter build ios   # iOS
   ```
3. **安装证书（如需要）**：
   - Android: 设置 → 安全 → 加密与凭据 → 从存储设备安装
   - iOS: 设置 → 通用 → VPN与设备管理 → 安装描述文件
4. **测试连接**：运行应用，测试 API 连接是否正常

## 安全建议

1. **仅开发/测试环境使用**：自签名证书不应用于生产环境
2. **限制允许的域名**：不要使用 `NSAllowsArbitraryLoads` 或允许所有证书
3. **使用环境变量**：通过构建配置区分开发和生产环境
4. **定期更新证书**：如果证书过期，需要更新配置
5. **生产环境使用 Let's Encrypt**：参考 [HTTPS 部署指南](../../backend/doc/DEPLOYMENT/README.md)

## 常见问题

### Q: Android 仍然报证书错误

A: 确保：
1. 证书已正确添加到 `res/raw/` 目录
2. `network_security_config.xml` 中引用了证书文件
3. 用户已在设备上安装证书（如果使用 `user` 证书源）

### Q: iOS 仍然拒绝连接

A: 确保：
1. `Info.plist` 配置正确
2. 用户已在设备上安装证书
3. 重新构建应用（Xcode → Product → Clean Build Folder）

### Q: 如何区分开发和生产环境

A: 使用 Flutter 的构建配置：
```bash
# 开发环境
flutter run --dart-define=ENV=development

# 生产环境
flutter build apk --release --dart-define=ENV=production
```

## 相关文档

- [Android Network Security Config](https://developer.android.com/training/articles/security-config)
- [iOS App Transport Security](https://developer.apple.com/documentation/security/preventing_insecure_network_connections)
- [Flutter HTTPS 配置](https://docs.flutter.dev/cookbook/networking/authenticated-requests)

