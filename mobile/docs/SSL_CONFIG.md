# SSL 配置说明

本文档说明如何在 `app_config.dart` 中配置 SSL/TLS 证书设置。

## 配置位置

所有 SSL 相关配置都在 `lib/config/app_config.dart` 的 `SslConfig` 类中。

## 配置项说明

### 1. enableHttps

是否启用 HTTPS。

```dart
static const bool enableHttps = true;  // 启用 HTTPS
static const bool enableHttps = false; // 使用 HTTP
```

**注意**：如果启用 HTTPS，确保 `ApiConfig.defaultServerAddr` 使用 `https://` 协议。

### 2. certificateType

证书类型，有两个选项：

- `CertificateType.trusted`: 受信任的证书（Let's Encrypt 等）
- `CertificateType.selfSigned`: 自签名证书（测试环境）

```dart
// 生产环境：使用 Let's Encrypt
static const CertificateType certificateType = CertificateType.trusted;

// 测试环境：使用自签名证书
static const CertificateType certificateType = CertificateType.selfSigned;
```

### 3. allowedSelfSignedHosts

允许使用自签名证书的主机列表（域名或 IP）。

仅当 `certificateType` 为 `CertificateType.selfSigned` 时生效。

```dart
static const List<String> allowedSelfSignedHosts = [
  '47.107.63.140',      // 服务器 IP
  'localhost',          // 本地
  '127.0.0.1',         // 本地 IP
  '10.0.2.2',          // Android 模拟器
  'api.example.com',   // 测试域名
];
```

## 配置示例

### 测试环境（自签名证书）

```dart
class SslConfig {
  static const bool enableHttps = true;
  static const CertificateType certificateType = CertificateType.selfSigned;
  static const List<String> allowedSelfSignedHosts = [
    '47.107.63.140',
    'localhost',
    '127.0.0.1',
    '10.0.2.2',
  ];
}

class ApiConfig {
  static const String defaultServerAddr = 'https://47.107.63.140';
}
```

### 生产环境（Let's Encrypt）

```dart
class SslConfig {
  static const bool enableHttps = true;
  static const CertificateType certificateType = CertificateType.trusted;
  static const List<String> allowedSelfSignedHosts = [];  // 不需要
}

class ApiConfig {
  static const String defaultServerAddr = 'https://api.example.com';
}
```

### 开发环境（HTTP，无 SSL）

```dart
class SslConfig {
  static const bool enableHttps = false;
  static const CertificateType certificateType = CertificateType.trusted;
  static const List<String> allowedSelfSignedHosts = [];
}

class ApiConfig {
  static const String defaultServerAddr = 'http://localhost:8080';
}
```

## 工作原理

### 自签名证书模式

当 `certificateType = CertificateType.selfSigned` 时：

1. Dio 会配置 `badCertificateCallback`
2. 只有 `allowedSelfSignedHosts` 列表中的主机才会被允许
3. 其他主机的自签名证书会被拒绝

### 受信任证书模式

当 `certificateType = CertificateType.trusted` 时：

1. Dio 使用默认的证书验证
2. 系统会自动信任 Let's Encrypt 等受信任 CA 颁发的证书
3. 无需特殊配置

## 切换配置

### 从测试环境切换到生产环境

1. 修改 `SslConfig.certificateType`：
   ```dart
   static const CertificateType certificateType = CertificateType.trusted;
   ```

2. 更新服务器地址：
   ```dart
   static const String defaultServerAddr = 'https://api.example.com';
   ```

3. 清空允许列表（可选）：
   ```dart
   static const List<String> allowedSelfSignedHosts = [];
   ```

### 从生产环境切换到测试环境

1. 修改 `SslConfig.certificateType`：
   ```dart
   static const CertificateType certificateType = CertificateType.selfSigned;
   ```

2. 更新服务器地址：
   ```dart
   static const String defaultServerAddr = 'https://47.107.63.140';
   ```

3. 添加允许的主机：
   ```dart
   static const List<String> allowedSelfSignedHosts = [
     '47.107.63.140',
     // ... 其他测试主机
   ];
   ```

## 调试

查看当前 SSL 配置：

```dart
print(SslConfig.configSummary);
```

输出示例：
```
SSL Config:
  - Enable HTTPS: true
  - Certificate Type: CertificateType.selfSigned
  - Allow Self-Signed: true
  - Allowed Hosts: 47.107.63.140, localhost, 127.0.0.1
```

## 注意事项

1. **生产环境必须使用受信任证书**：不要在生产环境使用自签名证书
2. **限制允许的主机**：自签名证书模式下，只允许列表中的主机
3. **协议匹配**：如果启用 HTTPS，确保服务器地址使用 `https://`
4. **Android/iOS 配置**：除了 Dio 配置，还需要配置 Android 的 `network_security_config.xml` 和 iOS 的 `Info.plist`（参考 `SELF_SIGNED_CERT.md`）

## 相关文档

- [自签名证书配置指南](./SELF_SIGNED_CERT.md) - Android/iOS 系统级配置
- [Dio 客户端示例](./dio_client_self_signed_example.dart) - 代码示例

