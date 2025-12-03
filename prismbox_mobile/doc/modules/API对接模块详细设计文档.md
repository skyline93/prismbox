# API 对接模块详细设计文档

## 目录
1. [模块概述](#模块概述)
2. [架构设计](#架构设计)
3. [核心组件详解](#核心组件详解)
4. [数据流设计](#数据流设计)
5. [接口定义](#接口定义)
6. [实现细节](#实现细节)
7. [错误处理](#错误处理)
8. [性能优化](#性能优化)
9. [测试策略](#测试策略)
10. [实施指南](#实施指南)

---

## 模块概述

### 职责范围

API 对接模块是 PrismBox 移动端与后端服务器通信的核心基础设施，负责：

1. **统一 API 客户端管理**
   - 管理所有 API 客户端实例（UsersApi、AssetsApi、AlbumsApi 等）
   - 统一配置和初始化
   - 提供类型安全的 API 调用接口

2. **认证机制**
   - Token 认证和自动注入
   - Token 存储和管理（Keychain/Keystore）
   - 401 错误自动处理和登录跳转
   - 自定义请求头支持

3. **HTTP/HTTPS 支持**
   - 支持 HTTP 和 HTTPS 协议
   - SSL/TLS 证书管理（自签名证书、客户端证书）
   - 平台特定的 SSL 配置（Android/iOS）

4. **端点发现与配置**
   - 智能端点发现（well-known 机制）
   - 端点可用性验证（pingServer）
   - 端点切换和持久化

5. **错误处理与重试**
   - 统一异常处理（ApiException）
   - 自动重试机制（指数退避）
   - 友好的错误提示

### 核心目标

1. **类型安全**：使用 OpenAPI 生成的客户端，提供编译时类型检查
2. **灵活配置**：支持多种部署场景（HTTP/HTTPS、自签名证书、客户端证书）
3. **完善错误处理**：统一错误处理，自动重试，友好提示
4. **安全可靠**：Token 安全存储，SSL 证书严格验证
5. **易于使用**：自动注入认证头，无需手动管理

### 设计原则

1. **统一管理**：所有 API 调用通过统一的 ApiService
2. **自动注入**：认证头自动注入，减少重复代码
3. **安全优先**：默认严格验证，允许用户选择放宽（自签名证书）
4. **平台适配**：Android 和 iOS 平台特定实现
5. **可扩展性**：易于添加新的 API 客户端和功能

### 与其他模块的关系

```
┌─────────────────────────────────────────┐
│          UI 层 / Service 层              │
│  - 调用 API 获取数据                      │
│  - 处理业务逻辑                           │
└─────────────────────────────────────────┘
                    │
                    │ 使用
                    ↓
┌─────────────────────────────────────────┐
│         Repository 层                    │
│  - 封装 API 调用                         │
│  - 数据转换（DTO ↔ Entity）              │
└─────────────────────────────────────────┘
                    │
                    │ 使用
                    ↓
┌─────────────────────────────────────────┐
│         API 对接模块                      │
│  - ApiService（统一 API 服务）            │
│  - 认证、SSL、端点发现                    │
└─────────────────────────────────────────┘
                    │
                    │ 使用
                    ↓
┌─────────────────────────────────────────┐
│         OpenAPI 客户端                    │
│  - 自动生成的 API 客户端                  │
│  - 类型安全的接口定义                     │
└─────────────────────────────────────────┘
                    │
                    │ HTTP/HTTPS
                    ↓
┌─────────────────────────────────────────┐
│         后端服务器                        │
│  - RESTful API                           │
│  - Token 验证                            │
└─────────────────────────────────────────┘
```

**依赖关系**：
- **依赖**：OpenAPI 生成的客户端、安全存储服务（Keychain/Keystore）、本地存储服务（Store）
- **被依赖**：Repository 层、Service 层、UI 层

---

## 架构设计

### 整体架构

API 对接模块采用分层架构，从下到上包括：

1. **网络层**：Dart HTTP 客户端、平台原生网络栈
2. **SSL 配置层**：HttpSSLOptions、HttpSSLCertOverride、平台原生 SSL 配置
3. **OpenAPI 客户端层**：自动生成的 API 客户端（UsersApi、AssetsApi 等）
4. **API 服务层**：ApiService 统一管理
5. **端点发现层**：EndpointDiscovery 服务

```
┌─────────────────────────────────────────────────────────────┐
│                   应用层 (Application Layer)                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  UI Components / Services / Repositories            │   │
│  │  - 调用 API 获取数据                                  │   │
│  │  - 处理业务逻辑                                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ API Calls
                            │
┌─────────────────────────────────────────────────────────────┐
│              API 服务层 (API Service Layer)                    │
│                                                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  ApiService                                           │   │
│  │  - 端点管理                                           │   │
│  │  - 认证头注入                                         │   │
│  │  - OpenAPI 客户端管理                                 │   │
│  │  - 设备信息头设置                                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  OpenAPI Clients  │         │  EndpointDiscovery│         │
│  │  - UsersApi       │         │  - well-known    │          │
│  │  - AssetsApi     │         │  - pingServer    │          │
│  │  - AlbumsApi     │         │  - 端点验证       │          │
│  │  - SearchApi     │         │                  │          │
│  │  - ...            │         │                  │          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/HTTPS
                            │
┌─────────────────────────────────────────────────────────────┐
│            SSL 配置层 (SSL Configuration Layer)               │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  HttpSSLOptions  │         │  HttpSSLCert     │          │
│  │  - SSL 配置管理   │         │  Override        │          │
│  │  - 自签名证书     │         │  - HttpOverrides │          │
│  │  - 客户端证书     │         │  - 证书验证回调   │          │
│  └──────────────────┘         └──────────────────┘          │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  Android Plugin  │         │  iOS System      │          │
│  │  - SSLContext    │         │  - Security      │          │
│  │  - TrustManager  │         │    Framework     │          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTP/HTTPS
                            │
┌─────────────────────────────────────────────────────────────┐
│           网络层 (Network Layer)                             │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  Dart HTTP       │         │  Background      │          │
│  │  - HttpClient    │         │  Downloader      │          │
│  │  - HttpOverrides │         │  - 上传/下载任务 │          │
│  └──────────────────┘         └──────────────────┘          │
│                                                               │
│  ┌──────────────────┐         ┌──────────────────┐          │
│  │  Android Native  │         │  iOS Native      │          │
│  │  - HttpsURL      │         │  - URLSession    │          │
│  │    Connection     │         │  - System Network│          │
│  └──────────────────┘         └──────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Internet
                            │
┌─────────────────────────────────────────────────────────────┐
│                 后端服务器 (Backend Server)                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  PrismBox Server API                                  │   │
│  │  - RESTful API                                        │   │
│  │  - Token 验证                                         │   │
│  │  - 文件上传/下载                                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 核心组件

1. **ApiService**：统一 API 服务管理
   - 管理所有 OpenAPI 客户端实例
   - 端点配置和管理
   - 认证头自动注入
   - 设备信息头设置

2. **HttpSSLOptions**：SSL 配置管理
   - 自签名证书配置
   - 客户端证书管理
   - 平台特定 SSL 配置

3. **HttpSSLCertOverride**：HTTP 覆盖实现
   - 实现 HttpOverrides
   - 证书验证回调
   - 客户端证书注入

4. **EndpointDiscovery**：端点发现服务
   - well-known 端点发现
   - pingServer 验证
   - 端点持久化

5. **DioClient**（可选）：Dio 客户端配置
   - 如果使用 Dio 而非 OpenAPI 客户端
   - 拦截器配置
   - 重试机制

### 技术选型

#### OpenAPI 客户端

**选择理由**：
- **类型安全**：自动生成的客户端提供编译时类型检查
- **代码生成**：从 OpenAPI 规范自动生成，减少手动编写
- **维护性**：API 变更时重新生成即可，减少维护成本
- **标准化**：遵循 OpenAPI 标准，易于集成

**实现方式**：
- 使用 `openapi-generator` 从 OpenAPI 规范生成 Dart 客户端
- 生成的客户端包含所有 API 接口和模型
- ApiService 管理所有客户端实例

#### HTTP 客户端

**选择理由**：
- **标准库**：Dart 标准库，无需额外依赖
- **平台兼容**：支持所有 Flutter 平台
- **可扩展**：通过 HttpOverrides 全局配置

**实现方式**：
- 使用 `dart:io` 的 `HttpClient`
- 通过 `HttpOverrides.global` 全局配置
- 支持自定义证书验证和客户端证书

#### SSL 配置

**选择理由**：
- **安全性**：支持标准 SSL/TLS 验证
- **灵活性**：支持自签名证书和客户端证书
- **平台适配**：Android 和 iOS 平台特定实现

**实现方式**：
- Dart 层：通过 `HttpOverrides` 和 `SecurityContext`
- Android：通过 MethodChannel 配置系统 SSLContext
- iOS：依赖系统网络栈和 Security Framework

---

## 核心组件详解

### ApiService

#### 职责

ApiService 是 API 对接模块的核心，负责：

1. **统一管理所有 OpenAPI 客户端**
   - 初始化和管理所有 API 客户端实例
   - 统一配置和端点设置

2. **认证管理**
   - Token 存储和获取
   - 认证头自动注入
   - 实现 `Authentication` 接口

3. **端点管理**
   - 端点解析和设置
   - 端点发现和验证
   - 端点持久化

4. **设备信息管理**
   - 设备型号和设备类型头设置
   - User-Agent 头设置

#### 接口定义

```dart
class ApiService implements Authentication {
  // OpenAPI 客户端实例
  late UsersApi usersApi;
  late AssetsApi assetsApi;
  late AlbumsApi albumsApi;
  late SearchApi searchApi;
  late ServerApi serverInfoApi;
  // ... 其他 API 客户端

  // 端点管理
  void setEndpoint(String endpoint);
  Future<String> resolveAndSetEndpoint(String serverUrl);
  Future<String> resolveEndpoint(String serverUrl);

  // 认证管理
  Future<void> setAccessToken(String accessToken);
  static Map<String, String> getRequestHeaders();

  // 设备信息
  Future<void> setDeviceInfoHeader();
}
```

#### 实现要点

**1. 客户端初始化**

```dart
class ApiService implements Authentication {
  late ApiClient _apiClient;
  
  ApiService() {
    // 初始化时设置空端点，避免 late 初始化错误
    setEndpoint('');
    
    // 如果已有保存的端点，恢复它
    final endpoint = Store.tryGet(StoreKey.serverEndpoint);
    if (endpoint != null && endpoint.isNotEmpty) {
      setEndpoint(endpoint);
    }
  }

  void setEndpoint(String endpoint) {
    // 创建 ApiClient，设置认证
    _apiClient = ApiClient(
      basePath: endpoint,
      authentication: this, // 实现 Authentication 接口
    );
    
    // 设置 User-Agent
    _setUserAgentHeader();
    
    // 如果已有 Token，设置它
    if (_accessToken != null) {
      setAccessToken(_accessToken!);
    }
    
    // 初始化所有 API 客户端
    usersApi = UsersApi(_apiClient);
    assetsApi = AssetsApi(_apiClient);
    albumsApi = AlbumsApi(_apiClient);
    // ... 其他客户端
  }
}
```

**2. 认证头自动注入**

```dart
class ApiService implements Authentication {
  String? _accessToken;

  // 实现 Authentication 接口
  @override
  void applyToParams(
    List<QueryParam> queryParams,
    Map<String, String> headerParams,
  ) {
    if (_accessToken != null) {
      // 自动注入认证头
      headerParams['x-immich-user-token'] = _accessToken!;
    }
    
    // 注入自定义请求头（如果有）
    final customHeaders = Store.tryGet(StoreKey.customHeaders);
    if (customHeaders != null) {
      try {
        final headers = jsonDecode(customHeaders) as Map<String, dynamic>;
        headers.forEach((key, value) {
          headerParams[key] = value.toString();
        });
      } catch (e) {
        // 忽略解析错误
      }
    }
  }

  // 获取请求头（用于 background_downloader 等）
  static Map<String, String> getRequestHeaders() {
    final headers = <String, String>{};
    
    // 添加认证头
    final token = Store.tryGet(StoreKey.accessToken);
    if (token != null) {
      headers['x-immich-user-token'] = token;
    }
    
    // 添加自定义头
    final customHeaders = Store.tryGet(StoreKey.customHeaders);
    if (customHeaders != null) {
      try {
        final custom = jsonDecode(customHeaders) as Map<String, dynamic>;
        custom.forEach((key, value) {
          headers[key] = value.toString();
        });
      } catch (e) {
        // 忽略解析错误
      }
    }
    
    return headers;
  }
}
```

**3. 端点发现和验证**

```dart
class ApiService {
  /// 解析并设置端点
  Future<String> resolveAndSetEndpoint(String serverUrl) async {
    // 解析端点（包括 well-known 发现）
    final endpoint = await resolveEndpoint(serverUrl);
    
    // 设置端点
    setEndpoint(endpoint);
    
    // 持久化端点
    await Store.put(StoreKey.serverEndpoint, endpoint);
    
    return endpoint;
  }

  /// 解析端点（支持 well-known 发现）
  Future<String> resolveEndpoint(String serverUrl) async {
    // 清理 URL
    String url = sanitizeUrl(serverUrl);

    // 尝试 well-known 发现
    final wellKnownEndpoint = await _getWellKnownEndpoint(url);
    if (wellKnownEndpoint.isNotEmpty) {
      url = sanitizeUrl(wellKnownEndpoint);
    }

    // 验证端点可用性
    if (!await _isEndpointAvailable(url)) {
      throw ApiException(503, "Server is not reachable");
    }

    return url;
  }

  /// 获取 well-known 端点
  Future<String> _getWellKnownEndpoint(String baseUrl) async {
    final client = Client();
    
    try {
      final headers = {
        "Accept": "application/json",
        ...getRequestHeaders(),
      };
      
      final response = await client
          .get(
            Uri.parse("$baseUrl/.well-known/immich"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final endpoint = data['api']['endpoint'].toString();

        // 处理相对路径和绝对路径
        if (endpoint.startsWith('/')) {
          return "$baseUrl$endpoint";
        }
        return endpoint;
      }
    } catch (e) {
      // well-known 发现失败，使用原始 URL
      debugPrint("Could not locate /.well-known/immich at $baseUrl");
    } finally {
      client.close();
    }

    return "";
  }

  /// 验证端点可用性
  Future<bool> _isEndpointAvailable(String serverUrl) async {
    // 确保 URL 以 /api 结尾
    if (!serverUrl.endsWith('/api')) {
      serverUrl += '/api';
    }

    try {
      // 临时设置端点
      setEndpoint(serverUrl);
      
      // 调用 pingServer 验证
      await serverInfoApi
          .pingServer()
          .timeout(const Duration(seconds: 5));
      
      return true;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (error, stackTrace) {
      _log.severe(
        "Error while checking server availability",
        error,
        stackTrace,
      );
      return false;
    }
  }
}
```

### HttpSSLOptions

#### 职责

HttpSSLOptions 负责统一管理 SSL/TLS 配置：

1. **自签名证书配置**
   - 读取用户设置
   - 应用自签名证书配置
   - 平台特定实现

2. **客户端证书管理**
   - 加载客户端证书
   - 配置双向 TLS 认证

3. **配置应用**
   - 设置 Dart 层 HttpOverrides
   - Android 平台原生配置
   - iOS 平台系统配置

#### 接口定义

```dart
class HttpSSLOptions {
  // 从设置应用 SSL 配置
  static void apply({bool applyNative = true});
  
  // 响应设置变更
  static void applyFromSettings(bool newValue);
  
  // 内部配置逻辑
  static void _apply();
}
```

#### 实现要点

```dart
class HttpSSLOptions {
  /// 从设置应用 SSL 配置
  static void apply({bool applyNative = true}) {
    final allowSelfSigned = Store.tryGet(StoreKey.allowSelfSignedSSLCert) ?? false;
    _apply(allowSelfSigned: allowSelfSigned, applyNative: applyNative);
  }

  /// 响应设置变更
  static void applyFromSettings(bool newValue) {
    // 更新设置
    Store.put(StoreKey.allowSelfSignedSSLCert, newValue);
    
    // 立即应用
    _apply(allowSelfSigned: newValue, applyNative: true);
  }

  /// 内部配置逻辑
  static void _apply({
    required bool allowSelfSigned,
    required bool applyNative,
  }) {
    // 获取服务器主机（如果已登录）
    String? serverHost;
    final currentUser = Store.tryGet(StoreKey.currentUser);
    if (currentUser != null) {
      final endpoint = Store.tryGet(StoreKey.serverEndpoint);
      if (endpoint != null) {
        try {
          final uri = Uri.parse(endpoint);
          serverHost = uri.host;
        } catch (e) {
          // 忽略解析错误
        }
      }
    }

    // 加载客户端证书
    final clientCert = SSLClientCertStoreVal.load();

    // 设置 Dart 层 HttpOverrides
    HttpOverrides.global = HttpSSLCertOverride(
      allowSelfSignedSSLCert: allowSelfSigned,
      serverHost: serverHost,
      clientCert: clientCert,
    );

    // Android 平台原生配置
    if (applyNative && Platform.isAndroid) {
      _applyAndroidNative(
        allowSelfSigned: allowSelfSigned,
        serverHost: serverHost,
        clientCert: clientCert,
      );
    }
  }

  /// Android 平台原生配置
  static Future<void> _applyAndroidNative({
    required bool allowSelfSigned,
    String? serverHost,
    SSLClientCertStoreVal? clientCert,
  }) async {
    try {
      const channel = MethodChannel('app.prismbox/http_ssl_options');
      await channel.invokeMethod('apply', {
        'allowSelfSigned': allowSelfSigned,
        'serverHost': serverHost,
        'clientCertData': clientCert?.data,
        'clientCertPassword': clientCert?.password,
      });
    } catch (e) {
      // 记录错误但不影响 Dart 层配置
      debugPrint('Failed to apply Android native SSL config: $e');
    }
  }
}
```

### HttpSSLCertOverride

#### 职责

HttpSSLCertOverride 实现 `HttpOverrides`，自定义 HTTP 客户端创建：

1. **客户端证书支持**
   - 加载客户端证书
   - 创建 SecurityContext
   - 配置证书链

2. **证书验证回调**
   - 处理服务器证书验证
   - 自签名证书处理逻辑
   - 主机名验证

#### 接口定义

```dart
class HttpSSLCertOverride extends HttpOverrides {
  final bool allowSelfSignedSSLCert;
  final String? serverHost;
  final SSLClientCertStoreVal? clientCert;

  HttpSSLCertOverride({
    required this.allowSelfSignedSSLCert,
    this.serverHost,
    this.clientCert,
  });

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // 实现自定义 HTTP 客户端创建
  }
}
```

#### 实现要点

```dart
class HttpSSLCertOverride extends HttpOverrides {
  final bool allowSelfSignedSSLCert;
  final String? serverHost;
  final SSLClientCertStoreVal? clientCert;
  SecurityContext? _securityContext;

  HttpSSLCertOverride({
    required this.allowSelfSignedSSLCert,
    this.serverHost,
    this.clientCert,
  }) {
    // 如果有客户端证书，预创建 SecurityContext
    if (clientCert != null) {
      _securityContext = SecurityContext(withTrustedRoots: true);
      try {
        _securityContext!.usePrivateKeyBytes(
          base64Decode(clientCert!.data),
          password: clientCert!.password,
        );
        _securityContext!.useCertificateChainBytes(
          base64Decode(clientCert!.data),
        );
      } catch (e) {
        debugPrint('Failed to load client certificate: $e');
        _securityContext = null;
      }
    }
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // 使用预创建的 SecurityContext 或传入的 context
    final securityContext = _securityContext ?? context;
    
    final client = securityContext != null
        ? HttpClient(context: securityContext)
        : HttpClient();

    // 设置证书验证回调
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // 如果启用自签名证书
      if (allowSelfSignedSSLCert) {
        // 登录前：允许任意自签名证书
        if (serverHost == null) {
          return true;
        }
        
        // 登录后：仅接受服务器主机的自签名证书
        if (serverHost != null && serverHost.contains(host)) {
          return true;
        }
      }
      
      // 其他情况：拒绝证书
      return false;
    };

    return client;
  }
}
```

### EndpointDiscovery

#### 职责

EndpointDiscovery 负责端点发现和验证：

1. **well-known 端点发现**
   - 访问 `/.well-known/immich`
   - 解析端点信息
   - 处理相对路径和绝对路径

2. **端点验证**
   - 调用 pingServer 验证可用性
   - 超时处理
   - 错误处理

3. **端点持久化**
   - 保存验证成功的端点
   - 应用启动时恢复

#### 接口定义

```dart
class EndpointDiscovery {
  /// 发现并验证端点
  Future<String> discoverAndValidate(String serverUrl);
  
  /// 获取 well-known 端点
  Future<String> getWellKnownEndpoint(String baseUrl);
  
  /// 验证端点可用性
  Future<bool> validateEndpoint(String endpoint);
}
```

#### 实现要点

```dart
class EndpointDiscovery {
  final ApiService _apiService;
  final Logger _log = Logger('EndpointDiscovery');

  EndpointDiscovery(this._apiService);

  /// 发现并验证端点
  Future<String> discoverAndValidate(String serverUrl) async {
    // 清理 URL
    String url = sanitizeUrl(serverUrl);

    // 尝试 well-known 发现
    final wellKnownEndpoint = await getWellKnownEndpoint(url);
    if (wellKnownEndpoint.isNotEmpty) {
      url = sanitizeUrl(wellKnownEndpoint);
    }

    // 验证端点可用性
    if (!await validateEndpoint(url)) {
      throw ApiException(503, "Server is not reachable");
    }

    return url;
  }

  /// 获取 well-known 端点
  Future<String> getWellKnownEndpoint(String baseUrl) async {
    final client = Client();
    
    try {
      final headers = {
        "Accept": "application/json",
        ...ApiService.getRequestHeaders(),
      };
      
      final response = await client
          .get(
            Uri.parse("$baseUrl/.well-known/immich"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final endpoint = data['api']['endpoint'].toString();

        // 处理相对路径和绝对路径
        if (endpoint.startsWith('/')) {
          return "$baseUrl$endpoint";
        }
        return endpoint;
      }
    } catch (e) {
      _log.warning("Could not locate /.well-known/immich at $baseUrl");
    } finally {
      client.close();
    }

    return "";
  }

  /// 验证端点可用性
  Future<bool> validateEndpoint(String endpoint) async {
    // 确保 URL 以 /api 结尾
    if (!endpoint.endsWith('/api')) {
      endpoint += '/api';
    }

    try {
      // 临时设置端点
      _apiService.setEndpoint(endpoint);
      
      // 调用 pingServer 验证
      await _apiService.serverInfoApi
          .pingServer()
          .timeout(const Duration(seconds: 5));
      
      return true;
    } on TimeoutException {
      return false;
    } on SocketException {
      return false;
    } catch (error, stackTrace) {
      _log.severe(
        "Error while checking server availability",
        error,
        stackTrace,
      );
      return false;
    }
  }
}
```

### DioClient（可选）

如果项目使用 Dio 而非 OpenAPI 客户端，需要配置 DioClient。

#### 职责

DioClient 负责配置 Dio 客户端：

1. **基础配置**
   - baseUrl 设置
   - 超时配置
   - 响应类型配置

2. **拦截器配置**
   - 认证拦截器
   - 重试拦截器
   - 日志拦截器
   - 错误拦截器

3. **SSL 配置**
   - 应用 SSL 配置
   - 证书验证

#### 接口定义

```dart
class DioClient {
  final Dio dio;
  final Dio fileDio;
  
  DioClient(this._storage);
  
  // 初始化 baseUrl
  Future<void> _initBaseUrl();
  
  // 创建认证拦截器
  Interceptor _createAuthInterceptor();
}
```

#### 实现要点

```dart
class DioClient {
  final SecureStorageService _storage;
  final Dio dio;
  final Dio fileDio;

  DioClient(this._storage)
      : dio = Dio(),
        fileDio = Dio() {
    // 配置 SSL
    DioSslConfig.configureSsl(dio);
    DioSslConfig.configureSsl(fileDio);

    // 配置基础选项
    dio.options.baseUrl = ApiConfig.baseUrlSync;
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(minutes: 30);
    dio.options.responseType = ResponseType.json;

    // 添加拦截器
    dio.interceptors.addAll([
      _createAuthInterceptor(),
      RetryInterceptor(
        dio: dio,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
          Duration(seconds: 5),
        ],
      ),
      LogInterceptor(),
    ]);

    // 初始化 baseUrl（异步）
    _initBaseUrl();
  }

  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 获取 Token
        final token = await _storage.getAccessToken();
        if (token != null) {
          options.headers['x-immich-user-token'] = token;
        }

        // 添加自定义头
        final customHeaders = await _storage.getCustomHeaders();
        if (customHeaders != null) {
          try {
            final headers = jsonDecode(customHeaders) as Map<String, dynamic>;
            headers.forEach((key, value) {
              options.headers[key] = value.toString();
            });
          } catch (e) {
            // 忽略解析错误
          }
        }

        handler.next(options);
      },
      onError: (error, handler) {
        // 401 错误处理
        if (error.response?.statusCode == 401) {
          // 清除 Token
          _storage.deleteAccessToken();
          // 跳转登录
          // ... 导航到登录页
        }
        handler.next(error);
      },
    );
  }
}
```

---

## 数据流设计

### 应用启动时的 API 初始化流程

```
应用启动 (main.dart)
    ↓
读取保存的端点 (StoreKey.serverEndpoint)
    ↓
ApiService 初始化
    ↓
如果端点存在，设置端点
    ↓
HttpSSLOptions.apply()
    ↓
读取 SSL 设置 (allowSelfSignedSSLCert)
    ↓
获取服务器主机（如果已登录）
    ↓
加载客户端证书（如果存在）
    ↓
设置 HttpOverrides.global
    ↓
Android: 调用原生插件配置 SSL
    ↓
所有 HTTP 请求使用新配置
```

### 登录流程

```
用户输入服务器 URL、邮箱、密码
    ↓
ApiService.resolveAndSetEndpoint(serverUrl)
    ↓
尝试 well-known 发现
    ↓
验证端点可用性 (pingServer)
    ↓
设置端点
    ↓
调用登录 API (authenticationApi.login)
    ↓
获取 Access Token 和用户信息
    ↓
ApiService.setAccessToken(token)
    ↓
保存 Token 到 Store 和安全存储
    ↓
设置设备信息头
    ↓
应用 SSL 配置（使用服务器主机）
    ↓
初始化完成
```

### API 请求流程

```
应用发起 API 请求
    ↓
调用 OpenAPI 客户端方法 (如 usersApi.getMyUser)
    ↓
ApiClient 创建 HTTP 请求
    ↓
Authentication.applyToParams() 自动注入认证头
    ↓
添加自定义请求头（如果有）
    ↓
HttpClient.createHttpClient()
    ↓
HttpSSLCertOverride.createHttpClient()
    ↓
检查客户端证书，创建 SecurityContext
    ↓
设置 badCertificateCallback
    ↓
发起 HTTP/HTTPS 请求
    ↓
服务器返回响应或证书
    ↓
如果证书验证失败，调用 badCertificateCallback
    ↓
检查是否启用自签名，验证主机名
    ↓
接受或拒绝连接
    ↓
返回响应数据
    ↓
OpenAPI 客户端解析响应
    ↓
返回业务对象
```

### 端点发现流程

```
用户输入服务器 URL
    ↓
ApiService.resolveEndpoint(serverUrl)
    ↓
清理 URL (sanitizeUrl)
    ↓
尝试访问 /.well-known/immich
    ↓
解析 JSON 响应，获取 endpoint
    ↓
处理相对路径或绝对路径
    ↓
如果 well-known 失败，使用原始 URL
    ↓
确保 URL 以 /api 结尾
    ↓
临时设置端点
    ↓
调用 pingServer() 验证可用性
    ↓
超时 5 秒
    ↓
如果验证成功，返回端点
    ↓
如果验证失败，抛出 ApiException(503)
```

### SSL 配置应用流程

```
用户切换自签名证书设置
    ↓
HttpSSLOptions.applyFromSettings(newValue)
    ↓
更新 Store 中的设置值
    ↓
获取服务器主机（如果已登录）
    ↓
加载客户端证书（如果存在）
    ↓
创建新的 HttpSSLCertOverride
    ↓
预创建 SecurityContext（如果有客户端证书）
    ↓
设置 HttpOverrides.global
    ↓
Android: 调用原生插件配置 SSL
    ↓
原生层配置 TrustManager 和 HostnameVerifier
    ↓
后续请求使用新配置
```

### 错误处理和重试流程

```
API 请求失败
    ↓
捕获异常
    ↓
判断异常类型
    ↓
┌─────────────────┬─────────────────┬─────────────────┐
│ 网络错误         │ 401 未授权       │ 其他错误         │
│ (SocketException)│                 │                 │
│                 │                 │                 │
│ 转换为 ApiException│ 清除 Token    │ 转换为 ApiException│
│                 │ 跳转登录页      │                 │
│ 检查是否可重试   │                 │ 记录错误日志     │
│                 │                 │ 返回错误信息     │
│ 指数退避重试     │                 │                 │
│ (最多 3 次)      │                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
    ↓
返回结果或错误
```

---

## 接口定义

### ApiService 接口

```dart
/// 统一 API 服务管理
class ApiService implements Authentication {
  // ========== OpenAPI 客户端实例 ==========
  
  /// 用户 API
  late UsersApi usersApi;
  
  /// 资产 API
  late AssetsApi assetsApi;
  
  /// 相册 API
  late AlbumsApi albumsApi;
  
  /// 搜索 API
  late SearchApi searchApi;
  
  /// 服务器信息 API
  late ServerApi serverInfoApi;
  
  // ... 其他 API 客户端

  // ========== 端点管理 ==========
  
  /// 设置 API 端点
  /// 
  /// [endpoint] 完整的 API 端点 URL（如 https://example.com/api）
  void setEndpoint(String endpoint);
  
  /// 解析并设置端点
  /// 
  /// [serverUrl] 服务器 URL（可能不包含 /api 路径）
  /// 
  /// 返回解析后的完整端点 URL
  /// 
  /// 抛出 [ApiException] 如果端点不可用
  Future<String> resolveAndSetEndpoint(String serverUrl);
  
  /// 解析端点（支持 well-known 发现）
  /// 
  /// [serverUrl] 服务器 URL
  /// 
  /// 返回解析后的端点 URL
  /// 
  /// 抛出 [ApiException] 如果端点不可用
  Future<String> resolveEndpoint(String serverUrl);

  // ========== 认证管理 ==========
  
  /// 设置 Access Token
  /// 
  /// [accessToken] 访问令牌
  Future<void> setAccessToken(String accessToken);
  
  /// 获取请求头（用于 background_downloader 等）
  /// 
  /// 返回包含认证头和自定义头的 Map
  static Map<String, String> getRequestHeaders();

  // ========== 设备信息 ==========
  
  /// 设置设备信息头
  /// 
  /// 自动设置 deviceModel 和 deviceType 头
  Future<void> setDeviceInfoHeader();

  // ========== Authentication 接口实现 ==========
  
  /// 自动注入认证头到请求参数
  /// 
  /// [queryParams] 查询参数列表
  /// [headerParams] 请求头 Map
  @override
  void applyToParams(
    List<QueryParam> queryParams,
    Map<String, String> headerParams,
  );
}
```

### HttpSSLOptions 接口

```dart
/// SSL/TLS 配置管理
class HttpSSLOptions {
  /// 从设置应用 SSL 配置
  /// 
  /// [applyNative] 是否应用平台原生配置（Android）
  static void apply({bool applyNative = true});
  
  /// 响应设置变更
  /// 
  /// [newValue] 新的自签名证书设置值
  static void applyFromSettings(bool newValue);
}
```

### EndpointDiscovery 接口

```dart
/// 端点发现服务
class EndpointDiscovery {
  /// 发现并验证端点
  /// 
  /// [serverUrl] 服务器 URL
  /// 
  /// 返回验证后的端点 URL
  /// 
  /// 抛出 [ApiException] 如果端点不可用
  Future<String> discoverAndValidate(String serverUrl);
  
  /// 获取 well-known 端点
  /// 
  /// [baseUrl] 基础 URL
  /// 
  /// 返回发现的端点 URL，如果失败返回空字符串
  Future<String> getWellKnownEndpoint(String baseUrl);
  
  /// 验证端点可用性
  /// 
  /// [endpoint] 端点 URL
  /// 
  /// 返回 true 如果端点可用，否则返回 false
  Future<bool> validateEndpoint(String endpoint);
}
```

### DioClient 接口（可选）

```dart
/// Dio 客户端配置
class DioClient {
  /// 标准 API 请求的 Dio 实例
  final Dio dio;
  
  /// 文件上传/下载的 Dio 实例
  final Dio fileDio;
  
  /// 创建 DioClient
  /// 
  /// [storage] 安全存储服务
  DioClient(SecureStorageService storage);
  
  /// 初始化 baseUrl（异步）
  Future<void> _initBaseUrl();
  
  /// 创建认证拦截器
  Interceptor _createAuthInterceptor();
}
```

---

## 实现细节

### Token 管理实现

#### Token 存储

```dart
class ApiService {
  String? _accessToken;

  Future<void> setAccessToken(String accessToken) async {
    _accessToken = accessToken;
    
    // 存储到本地 Store（用于应用内访问）
    await Store.put(StoreKey.accessToken, accessToken);
    
    // 存储到平台安全存储（用于 Widget 扩展等）
    await SecureStorageService.instance.setAccessToken(accessToken);
  }

  // 从存储获取 Token
  String? getAccessToken() {
    return _accessToken ?? Store.tryGet(StoreKey.accessToken);
  }
}
```

#### Token 自动注入

```dart
class ApiService implements Authentication {
  @override
  void applyToParams(
    List<QueryParam> queryParams,
    Map<String, String> headerParams,
  ) {
    // 注入认证头
    final token = getAccessToken();
    if (token != null) {
      headerParams['x-immich-user-token'] = token;
    }
    
    // 注入自定义头
    final customHeaders = Store.tryGet(StoreKey.customHeaders);
    if (customHeaders != null) {
      try {
        final headers = jsonDecode(customHeaders) as Map<String, dynamic>;
        headers.forEach((key, value) {
          headerParams[key] = value.toString();
        });
      } catch (e) {
        // 忽略解析错误
      }
    }
  }
}
```

### 认证头自动注入实现

#### OpenAPI 客户端自动注入

OpenAPI 客户端通过 `Authentication` 接口自动注入认证头：

```dart
class ApiService implements Authentication {
  void setEndpoint(String endpoint) {
    _apiClient = ApiClient(
      basePath: endpoint,
      authentication: this, // 实现 Authentication 接口
    );
    
    // 所有通过 _apiClient 创建的请求都会自动调用
    // applyToParams() 注入认证头
  }
}
```

#### background_downloader 手动注入

background_downloader 需要手动获取请求头：

```dart
// 创建上传任务时
final headers = ApiService.getRequestHeaders();

final task = UploadTask(
  url: uploadUrl,
  headers: headers, // 手动传入认证头
  httpRequestMethod: 'POST',
  // ... 其他参数
);
```

### SSL/TLS 配置实现

#### 自签名证书处理

```dart
class HttpSSLCertOverride extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = context != null
        ? HttpClient(context: context)
        : HttpClient();

    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // 如果启用自签名证书
      if (allowSelfSignedSSLCert) {
        // 登录前：允许任意自签名证书
        if (serverHost == null) {
          return true;
        }
        
        // 登录后：仅接受服务器主机的自签名证书
        if (serverHost != null && serverHost.contains(host)) {
          return true;
        }
      }
      
      // 其他情况：拒绝证书
      return false;
    };

    return client;
  }
}
```

#### 客户端证书支持

```dart
class HttpSSLCertOverride extends HttpOverrides {
  SecurityContext? _securityContext;

  HttpSSLCertOverride({
    required this.allowSelfSignedSSLCert,
    this.serverHost,
    this.clientCert,
  }) {
    // 如果有客户端证书，预创建 SecurityContext
    if (clientCert != null) {
      _securityContext = SecurityContext(withTrustedRoots: true);
      try {
        final certBytes = base64Decode(clientCert!.data);
        _securityContext!.usePrivateKeyBytes(
          certBytes,
          password: clientCert!.password,
        );
        _securityContext!.useCertificateChainBytes(certBytes);
      } catch (e) {
        debugPrint('Failed to load client certificate: $e');
        _securityContext = null;
      }
    }
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // 使用预创建的 SecurityContext
    final securityContext = _securityContext ?? context;
    
    return securityContext != null
        ? HttpClient(context: securityContext)
        : HttpClient();
  }
}
```

#### Android 平台原生配置

```kotlin
// HttpSSLOptionsPlugin.kt
class HttpSSLOptionsPlugin : MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "apply" -> {
                val allowSelfSigned = call.argument<Boolean>("allowSelfSigned") ?: false
                val serverHost = call.argument<String>("serverHost")
                val clientCertData = call.argument<String>("clientCertData")
                val clientCertPassword = call.argument<String>("clientCertPassword")
                
                try {
                    // 配置 TrustManager
                    val trustManager = if (allowSelfSigned && serverHost != null) {
                        AllowSelfSignedTrustManager(serverHost)
                    } else {
                        null
                    }
                    
                    // 配置 KeyManager（如果有客户端证书）
                    val keyManagers = if (clientCertData != null) {
                        loadClientCertificate(clientCertData, clientCertPassword)
                    } else {
                        null
                    }
                    
                    // 配置 SSLContext
                    val sslContext = SSLContext.getInstance("TLS")
                    sslContext.init(
                        keyManagers,
                        arrayOf(trustManager ?: getDefaultTrustManager()),
                        null
                    )
                    
                    // 设置默认配置
                    HttpsURLConnection.setDefaultSSLSocketFactory(sslContext.socketFactory)
                    HttpsURLConnection.setDefaultHostnameVerifier(
                        if (allowSelfSigned && serverHost != null) {
                            AllowSelfSignedHostnameVerifier(serverHost)
                        } else {
                            HttpsURLConnection.getDefaultHostnameVerifier()
                        }
                    )
                    
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SSL_CONFIG_ERROR", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
```

### 端点发现实现

#### well-known 端点发现

```dart
Future<String> _getWellKnownEndpoint(String baseUrl) async {
  final client = Client();
  
  try {
    final headers = {
      "Accept": "application/json",
      ...ApiService.getRequestHeaders(),
    };
    
    final response = await client
        .get(
          Uri.parse("$baseUrl/.well-known/immich"),
          headers: headers,
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final endpoint = data['api']['endpoint'].toString();

      // 处理相对路径和绝对路径
      if (endpoint.startsWith('/')) {
        // 相对路径：拼接基础 URL
        return "$baseUrl$endpoint";
      }
      // 绝对路径：直接返回
      return endpoint;
    }
  } catch (e) {
    debugPrint("Could not locate /.well-known/immich at $baseUrl");
  } finally {
    client.close();
  }

  return "";
}
```

#### pingServer 验证

```dart
Future<bool> _isEndpointAvailable(String serverUrl) async {
  // 确保 URL 以 /api 结尾
  if (!serverUrl.endsWith('/api')) {
    serverUrl += '/api';
  }

  try {
    // 临时设置端点
    setEndpoint(serverUrl);
    
    // 调用 pingServer 验证（超时 5 秒）
    await serverInfoApi
        .pingServer()
        .timeout(const Duration(seconds: 5));
    
    return true;
  } on TimeoutException {
    return false;
  } on SocketException {
    return false;
  } catch (error, stackTrace) {
    _log.severe(
      "Error while checking server availability",
      error,
      stackTrace,
    );
    return false;
  }
}
```

### 错误处理实现

#### 统一异常处理

```dart
/// 统一 API 异常
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  ApiException(
    this.statusCode,
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}

/// 错误处理工具
class ApiErrorHandler {
  /// 处理 API 错误
  static ApiException handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    if (error is DioException) {
      return _handleDioError(error);
    }
    
    if (error is SocketException) {
      return ApiException(503, 'Network error: ${error.message}');
    }
    
    if (error is TimeoutException) {
      return ApiException(504, 'Request timeout');
    }
    
    return ApiException(500, 'Unknown error: $error');
  }

  static ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(504, 'Request timeout');
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 500;
        final message = error.response?.data?.toString() ?? 'Server error';
        return ApiException(statusCode, message);
      
      case DioExceptionType.cancel:
        return ApiException(0, 'Request cancelled');
      
      default:
        return ApiException(503, 'Network error: ${error.message}');
    }
  }
}
```

#### 401 自动跳转登录

```dart
class ApiErrorHandler {
  /// 处理 401 错误，自动跳转登录
  static Future<void> handle401Error() async {
    // 清除本地认证信息
    await Store.delete(StoreKey.accessToken);
    await SecureStorageService.instance.deleteAccessToken();
    
    // 清除用户信息
    await Store.delete(StoreKey.currentUser);
    
    // 跳转到登录页
    // 注意：这里需要根据实际的路由系统实现
    // 如果使用 AutoRoute：
    // appRouter.pushAndClearStack(LoginRoute());
    // 如果使用 GoRouter：
    // goRouter.go('/login');
  }
}

// 在拦截器中使用
class AuthInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // 处理 401 错误
      ApiErrorHandler.handle401Error();
    }
    handler.next(err);
  }
}
```

### 重试机制实现

#### 指数退避策略

```dart
/// 重试配置
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
  });
}

/// 重试工具
class RetryHelper {
  /// 执行带重试的操作
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    required RetryConfig config,
    required bool Function(dynamic error) shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = config.initialDelay;

    while (attempt < config.maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        // 检查是否应该重试
        if (!shouldRetry(error) || attempt >= config.maxRetries) {
          rethrow;
        }

        // 指数退避
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * config.backoffMultiplier).toInt(),
        );
        
        // 限制最大延迟
        if (delay > config.maxDelay) {
          delay = config.maxDelay;
        }
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// 判断是否可重试的错误
  static bool isRetryableError(dynamic error) {
    // 网络错误可重试
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    
    // 5xx 服务器错误可重试
    if (error is ApiException) {
      final statusCode = error.statusCode;
      return statusCode >= 500 && statusCode < 600;
    }
    
    // 连接超时可重试
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout;
    }
    
    return false;
  }
}
```

#### 使用示例

```dart
// 在 Repository 中使用重试
class MediaRepository {
  Future<List<AssetDto>> getAssets() async {
    return await RetryHelper.retry(
      operation: () => _apiService.assetsApi.getAllAssets(),
      config: const RetryConfig(
        maxRetries: 3,
        initialDelay: Duration(seconds: 1),
      ),
      shouldRetry: RetryHelper.isRetryableError,
    );
  }
}
```

---

## 错误处理

### 错误类型定义

#### 网络层错误

```dart
/// 网络连接错误
class NetworkException extends ApiException {
  NetworkException(String message, [dynamic originalError])
      : super(503, message, originalError: originalError);
}

/// SSL/TLS 错误
class SSLException extends ApiException {
  SSLException(String message, [dynamic originalError])
      : super(495, message, originalError: originalError);
}

/// 超时错误
class TimeoutException extends ApiException {
  TimeoutException(String message, [dynamic originalError])
      : super(504, message, originalError: originalError);
}
```

#### API 层错误

```dart
/// 认证错误
class AuthenticationException extends ApiException {
  AuthenticationException(String message)
      : super(401, message);
}

/// 权限错误
class PermissionException extends ApiException {
  PermissionException(String message)
      : super(403, message);
}

/// 资源不存在错误
class NotFoundException extends ApiException {
  NotFoundException(String message)
      : super(404, message);
}

/// 服务器错误
class ServerException extends ApiException {
  ServerException(String message, [dynamic originalError])
      : super(500, message, originalError: originalError);
}
```

### 错误处理策略

#### 统一错误处理

```dart
/// 统一错误处理工具
class ErrorHandler {
  /// 处理错误并返回用户友好的消息
  static String getErrorMessage(dynamic error) {
    if (error is ApiException) {
      return _getApiErrorMessage(error);
    }
    
    if (error is SocketException) {
      return '网络连接失败，请检查网络设置';
    }
    
    if (error is TimeoutException) {
      return '请求超时，请稍后重试';
    }
    
    return '发生未知错误，请稍后重试';
  }

  static String _getApiErrorMessage(ApiException error) {
    switch (error.statusCode) {
      case 401:
        return '登录已过期，请重新登录';
      case 403:
        return '没有权限执行此操作';
      case 404:
        return '请求的资源不存在';
      case 500:
      case 502:
      case 503:
        return '服务器错误，请稍后重试';
      case 504:
        return '请求超时，请稍后重试';
      default:
        return error.message;
    }
  }

  /// 处理错误并执行相应操作
  static Future<void> handleError(dynamic error) async {
    if (error is AuthenticationException) {
      // 401 错误：清除认证信息并跳转登录
      await ApiErrorHandler.handle401Error();
    } else if (error is NetworkException) {
      // 网络错误：显示提示
      // showSnackBar('网络连接失败，请检查网络设置');
    } else if (error is ServerException) {
      // 服务器错误：记录日志
      Logger('ErrorHandler').severe('Server error', error);
    }
  }
}
```

#### 自动恢复机制

```dart
/// 自动恢复管理器
class AutoRecoveryManager {
  /// 检查并恢复失败的请求
  static Future<T?> recoverRequest<T>({
    required Future<T> Function() operation,
    required Duration timeout,
  }) async {
    try {
      return await operation().timeout(timeout);
    } catch (error) {
      // 如果是可恢复的错误，尝试恢复
      if (RetryHelper.isRetryableError(error)) {
        // 等待网络恢复
        await _waitForNetwork();
        
        // 重试一次
        try {
          return await operation().timeout(timeout);
        } catch (retryError) {
          // 重试失败，返回 null
          return null;
        }
      }
      
      // 不可恢复的错误，返回 null
      return null;
    }
  }

  /// 等待网络恢复
  static Future<void> _waitForNetwork() async {
    // 检查网络连接
    final connectivity = Connectivity();
    var hasConnection = false;
    
    while (!hasConnection) {
      final result = await connectivity.checkConnectivity();
      hasConnection = result != ConnectivityResult.none;
      
      if (!hasConnection) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }
}
```

### 用户友好的错误提示

```dart
/// 错误提示工具
class ErrorMessageHelper {
  /// 显示错误提示
  static void showError(BuildContext context, dynamic error) {
    final message = ErrorHandler.getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: '重试',
          onPressed: () {
            // 触发重试逻辑
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// 显示错误对话框
  static Future<void> showErrorDialog(
    BuildContext context,
    dynamic error,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(ErrorHandler.getErrorMessage(error)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
          if (RetryHelper.isRetryableError(error))
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // 触发重试逻辑
              },
              child: const Text('重试'),
            ),
        ],
      ),
    );
  }
}
```

---

## 性能优化

### 连接复用优化

#### HTTP 客户端复用

```dart
class ApiService {
  // 复用 ApiClient 实例
  late ApiClient _apiClient;
  
  // 所有 API 客户端共享同一个 ApiClient
  void setEndpoint(String endpoint) {
    _apiClient = ApiClient(basePath: endpoint, authentication: this);
    // ... 初始化所有客户端
  }
}
```

#### 连接池配置

```dart
class HttpClientConfig {
  /// 配置 HTTP 客户端连接池
  static HttpClient createHttpClient() {
    final client = HttpClient();
    
    // 设置最大连接数
    client.maxConnectionsPerHost = 16;
    
    // 启用连接复用
    client.autoUncompress = true;
    
    return client;
  }
}
```

### 请求合并优化

#### 批量请求

```dart
/// 批量请求工具
class BatchRequestHelper {
  /// 批量获取资产
  static Future<List<AssetDto>> batchGetAssets(
    List<String> assetIds,
    ApiService apiService,
  ) async {
    // 如果资产数量少，直接请求
    if (assetIds.length <= 10) {
      return await Future.wait(
        assetIds.map((id) => apiService.assetsApi.getAssetById(id)),
      );
    }
    
    // 如果资产数量多，分批请求
    final results = <AssetDto>[];
    const batchSize = 10;
    
    for (int i = 0; i < assetIds.length; i += batchSize) {
      final batch = assetIds.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((id) => apiService.assetsApi.getAssetById(id)),
      );
      results.addAll(batchResults);
    }
    
    return results;
  }
}
```

### 缓存策略优化

#### API 响应缓存

```dart
/// API 响应缓存
class ApiResponseCache {
  static final Map<String, CachedResponse> _cache = {};
  static const Duration defaultTTL = Duration(minutes: 5);

  /// 获取缓存的响应
  static T? get<T>(String key) {
    final cached = _cache[key];
    if (cached == null) return null;
    
    if (cached.isExpired) {
      _cache.remove(key);
      return null;
    }
    
    return cached.data as T;
  }

  /// 缓存响应
  static void put<T>(String key, T data, {Duration? ttl}) {
    _cache[key] = CachedResponse(
      data: data,
      expiresAt: DateTime.now().add(ttl ?? defaultTTL),
    );
  }

  /// 清除缓存
  static void clear() {
    _cache.clear();
  }
}

class CachedResponse {
  final dynamic data;
  final DateTime expiresAt;

  CachedResponse({required this.data, required this.expiresAt});

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
```

#### 使用示例

```dart
class MediaRepository {
  Future<List<AssetDto>> getAssets({bool useCache = true}) async {
    const cacheKey = 'assets_list';
    
    // 尝试从缓存获取
    if (useCache) {
      final cached = ApiResponseCache.get<List<AssetDto>>(cacheKey);
      if (cached != null) {
        return cached;
      }
    }
    
    // 从 API 获取
    final assets = await _apiService.assetsApi.getAllAssets();
    
    // 缓存结果
    if (useCache) {
      ApiResponseCache.put(cacheKey, assets, ttl: const Duration(minutes: 5));
    }
    
    return assets;
  }
}
```

### 请求优化

#### 请求去重

```dart
/// 请求去重管理器
class RequestDeduplicator {
  static final Map<String, Future<dynamic>> _pendingRequests = {};

  /// 执行去重请求
  static Future<T> deduplicate<T>(
    String key,
    Future<T> Function() operation,
  ) async {
    // 如果已有相同请求在进行，等待它完成
    final existing = _pendingRequests[key];
    if (existing != null) {
      return await existing as T;
    }

    // 创建新请求
    final future = operation();
    _pendingRequests[key] = future;

    try {
      final result = await future;
      return result as T;
    } finally {
      _pendingRequests.remove(key);
    }
  }
}
```

#### 使用示例

```dart
class MediaRepository {
  Future<AssetDto> getAssetById(String id) async {
    return await RequestDeduplicator.deduplicate(
      'asset_$id',
      () => _apiService.assetsApi.getAssetById(id),
    );
  }
}
```

---

## 测试策略

### 单元测试

#### ApiService 测试

```dart
void main() {
  group('ApiService', () {
    late ApiService apiService;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      apiService = ApiService();
    });

    test('setEndpoint should initialize all API clients', () {
      apiService.setEndpoint('https://example.com/api');
      
      expect(apiService.usersApi, isNotNull);
      expect(apiService.assetsApi, isNotNull);
      expect(apiService.albumsApi, isNotNull);
    });

    test('setAccessToken should store token', () async {
      const token = 'test_token';
      await apiService.setAccessToken(token);
      
      final storedToken = Store.tryGet(StoreKey.accessToken);
      expect(storedToken, equals(token));
    });

    test('getRequestHeaders should include token', () {
      Store.put(StoreKey.accessToken, 'test_token');
      
      final headers = ApiService.getRequestHeaders();
      
      expect(headers['x-immich-user-token'], equals('test_token'));
    });
  });
}
```

#### 端点发现测试

```dart
void main() {
  group('EndpointDiscovery', () {
    late EndpointDiscovery discovery;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      discovery = EndpointDiscovery(mockApiService);
    });

    test('getWellKnownEndpoint should parse relative path', () async {
      // Mock HTTP 响应
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => MockResponse(
                statusCode: 200,
                body: jsonEncode({'api': {'endpoint': '/api/v1'}}),
              ));

      final endpoint = await discovery.getWellKnownEndpoint('https://example.com');
      
      expect(endpoint, equals('https://example.com/api/v1'));
    });

    test('getWellKnownEndpoint should parse absolute path', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => MockResponse(
                statusCode: 200,
                body: jsonEncode({'api': {'endpoint': 'https://api.example.com'}}),
              ));

      final endpoint = await discovery.getWellKnownEndpoint('https://example.com');
      
      expect(endpoint, equals('https://api.example.com'));
    });

    test('validateEndpoint should return true for available endpoint', () async {
      when(() => mockApiService.serverInfoApi.pingServer())
          .thenAnswer((_) async => {});

      final isValid = await discovery.validateEndpoint('https://example.com/api');
      
      expect(isValid, isTrue);
    });

    test('validateEndpoint should return false for unavailable endpoint', () async {
      when(() => mockApiService.serverInfoApi.pingServer())
          .thenThrow(TimeoutException('Connection timeout'));

      final isValid = await discovery.validateEndpoint('https://example.com/api');
      
      expect(isValid, isFalse);
    });
  });
}
```

#### SSL 配置测试

```dart
void main() {
  group('HttpSSLOptions', () {
    test('apply should set HttpOverrides.global', () {
      HttpSSLOptions.apply();
      
      expect(HttpOverrides.global, isA<HttpSSLCertOverride>());
    });

    test('applyFromSettings should update and apply config', () {
      HttpSSLOptions.applyFromSettings(true);
      
      final allowSelfSigned = Store.tryGet(StoreKey.allowSelfSignedSSLCert);
      expect(allowSelfSigned, isTrue);
      
      expect(HttpOverrides.global, isA<HttpSSLCertOverride>());
    });
  });

  group('HttpSSLCertOverride', () {
    test('createHttpClient should set badCertificateCallback', () {
      final override = HttpSSLCertOverride(
        allowSelfSignedSSLCert: true,
        serverHost: 'example.com',
      );

      final client = override.createHttpClient(null);
      
      expect(client.badCertificateCallback, isNotNull);
    });

    test('badCertificateCallback should accept self-signed cert for matching host', () {
      final override = HttpSSLCertOverride(
        allowSelfSignedSSLCert: true,
        serverHost: 'example.com',
      );

      final client = override.createHttpClient(null);
      final result = client.badCertificateCallback!(
        MockX509Certificate(),
        'example.com',
        443,
      );
      
      expect(result, isTrue);
    });

    test('badCertificateCallback should reject self-signed cert for non-matching host', () {
      final override = HttpSSLCertOverride(
        allowSelfSignedSSLCert: true,
        serverHost: 'example.com',
      );

      final client = override.createHttpClient(null);
      final result = client.badCertificateCallback!(
        MockX509Certificate(),
        'evil.com',
        443,
      );
      
      expect(result, isFalse);
    });
  });
}
```

### 集成测试

#### API 调用集成测试

```dart
void main() {
  group('API Integration Tests', () {
    late ApiService apiService;
    late String testServerUrl;

    setUpAll(() async {
      testServerUrl = 'https://test-server.example.com';
      apiService = ApiService();
      await apiService.resolveAndSetEndpoint(testServerUrl);
    });

    test('login should return token', () async {
      final response = await apiService.authenticationApi.login(
        LoginCredentialDto(
          email: 'test@example.com',
          password: 'test_password',
        ),
      );

      expect(response.accessToken, isNotEmpty);
      expect(response.user, isNotNull);
    });

    test('getMyUser should return current user', () async {
      final user = await apiService.usersApi.getMyUser();
      
      expect(user.id, isNotEmpty);
      expect(user.email, isNotEmpty);
    });

    test('getAllAssets should return asset list', () async {
      final assets = await apiService.assetsApi.getAllAssets();
      
      expect(assets, isA<List<AssetDto>>());
    });
  });
}
```

#### 错误处理集成测试

```dart
void main() {
  group('Error Handling Integration Tests', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    test('401 error should trigger logout', () async {
      // Mock 401 响应
      when(() => mockApiClient.call(any(), any(), any()))
          .thenThrow(ApiException(401, 'Unauthorized'));

      try {
        await apiService.usersApi.getMyUser();
        fail('Should throw ApiException');
      } on ApiException catch (e) {
        expect(e.statusCode, equals(401));
        
        // 验证 Token 已清除
        final token = Store.tryGet(StoreKey.accessToken);
        expect(token, isNull);
      }
    });

    test('network error should be retried', () async {
      var attemptCount = 0;
      
      when(() => mockApiClient.call(any(), any(), any()))
          .thenAnswer((_) {
            attemptCount++;
            if (attemptCount < 3) {
              throw SocketException('Connection failed');
            }
            return MockResponse();
          });

      final result = await RetryHelper.retry(
        operation: () => apiService.usersApi.getMyUser(),
        config: const RetryConfig(maxRetries: 3),
        shouldRetry: RetryHelper.isRetryableError,
      );

      expect(result, isNotNull);
      expect(attemptCount, equals(3));
    });
  });
}
```

### 平台特定测试

#### Android SSL 配置测试

```kotlin
// Android 测试
class HttpSSLOptionsPluginTest {
    @Test
    fun testApplySelfSignedCert() {
        val plugin = HttpSSLOptionsPlugin()
        val result = MethodCallResult()
        
        plugin.onMethodCall(
            MethodCall("apply", mapOf(
                "allowSelfSigned" to true,
                "serverHost" to "example.com"
            )),
            result
        )
        
        assertTrue(result.isSuccess)
        
        // 验证 SSLContext 已配置
        val sslContext = SSLContext.getDefault()
        assertNotNull(sslContext)
    }
}
```

### 性能测试

#### 请求性能测试

```dart
void main() {
  group('Performance Tests', () {
    test('batch request should be faster than sequential', () async {
      final apiService = ApiService();
      final assetIds = List.generate(100, (i) => 'asset_$i');

      // 顺序请求
      final stopwatch1 = Stopwatch()..start();
      for (final id in assetIds) {
        await apiService.assetsApi.getAssetById(id);
      }
      stopwatch1.stop();

      // 批量请求
      final stopwatch2 = Stopwatch()..start();
      await BatchRequestHelper.batchGetAssets(assetIds, apiService);
      stopwatch2.stop();

      // 批量请求应该更快
      expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds));
    });

    test('cache should improve response time', () async {
      final repository = MediaRepository(apiService);
      
      // 第一次请求（无缓存）
      final stopwatch1 = Stopwatch()..start();
      await repository.getAssets(useCache: false);
      stopwatch1.stop();

      // 第二次请求（有缓存）
      final stopwatch2 = Stopwatch()..start();
      await repository.getAssets(useCache: true);
      stopwatch2.stop();

      // 缓存请求应该更快
      expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds));
    });
  });
}
```

---

## 实施指南

### 分阶段实施计划

#### 第一阶段：基础 API 服务（1-2 周）

**目标**：建立基础的 API 服务框架

**任务清单**：
1. **创建 ApiService 基础结构**
   - 实现 ApiService 类
   - 配置 OpenAPI 客户端
   - 实现端点管理

2. **实现认证机制**
   - Token 存储和管理
   - 认证头自动注入
   - 401 错误处理

3. **基础错误处理**
   - 统一异常类型
   - 错误转换和处理

**交付物**：
- ApiService 基础实现
- 认证机制实现
- 基础错误处理

#### 第二阶段：SSL 配置和端点发现（1-2 周）

**目标**：实现 SSL 配置和端点发现功能

**任务清单**：
1. **实现 SSL 配置**
   - HttpSSLOptions 实现
   - HttpSSLCertOverride 实现
   - Android 原生插件实现

2. **实现端点发现**
   - well-known 端点发现
   - pingServer 验证
   - 端点持久化

3. **测试和验证**
   - 单元测试
   - 集成测试
   - 平台特定测试

**交付物**：
- SSL 配置完整实现
- 端点发现功能
- 测试用例

#### 第三阶段：错误处理和重试（1 周）

**目标**：完善错误处理和重试机制

**任务清单**：
1. **完善错误处理**
   - 统一错误类型
   - 错误处理策略
   - 用户友好提示

2. **实现重试机制**
   - 指数退避策略
   - 自动重试逻辑
   - 重试配置

3. **错误恢复机制**
   - 自动恢复逻辑
   - 网络状态检测

**交付物**：
- 完整的错误处理机制
- 重试机制实现
- 错误恢复功能

#### 第四阶段：性能优化（1 周）

**目标**：优化 API 调用性能

**任务清单**：
1. **连接优化**
   - 连接复用
   - 连接池配置

2. **请求优化**
   - 请求合并
   - 请求去重
   - 缓存策略

3. **性能测试**
   - 性能基准测试
   - 性能优化验证

**交付物**：
- 性能优化实现
- 性能测试报告

### 关键文件位置

#### Dart 层文件

```
lib/
├── infrastructure/
│   └── api/
│       ├── api_service.dart              # ApiService 主文件
│       ├── dio_client.dart               # Dio 客户端配置（可选）
│       ├── ssl/
│       │   ├── http_ssl_options.dart     # SSL 配置管理
│       │   └── http_ssl_cert_override.dart # SSL 证书覆盖
│       └── interceptors/
│           ├── auth_interceptor.dart     # 认证拦截器
│           └── error_interceptor.dart    # 错误拦截器
├── core/
│   └── network/
│       └── endpoint_discovery.dart       # 端点发现服务
└── utils/
    ├── api_error_handler.dart            # 错误处理工具
    └── retry_helper.dart                 # 重试工具
```

#### Android 原生文件

```
android/app/src/main/kotlin/app/prismbox/
└── HttpSSLOptionsPlugin.kt               # Android SSL 配置插件
```

#### 配置文件

```
lib/config/
└── api_config.dart                       # API 配置
```

### 配置说明

#### API 配置

```dart
// lib/config/api_config.dart
class ApiConfig {
  // 默认服务器地址
  static const String defaultServerUrl = 'https://api.example.com';
  
  // 超时配置
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(minutes: 30);
  
  // 重试配置
  static const int maxRetries = 3;
  static const Duration retryInitialDelay = Duration(seconds: 1);
}
```

#### SSL 配置

```dart
// lib/config/ssl_config.dart
class SslConfig {
  // 是否允许自签名证书（默认 false）
  static const bool allowSelfSignedDefault = false;
  
  // 客户端证书存储键
  static const String clientCertDataKey = 'ssl_client_cert_data';
  static const String clientCertPasswordKey = 'ssl_client_cert_password';
}
```

### 常见问题和解决方案

#### 问题 1：SSL 证书验证失败

**症状**：HTTPS 请求失败，提示证书验证错误

**解决方案**：
1. 检查服务器是否使用自签名证书
2. 如果是，在设置中启用"允许自签名证书"
3. 确保服务器主机名匹配
4. 检查客户端证书配置（如果使用双向 TLS）

#### 问题 2：端点发现失败

**症状**：无法自动发现 API 端点

**解决方案**：
1. 检查服务器是否支持 `/.well-known/immich`
2. 如果不支持，手动输入完整的 API 端点 URL
3. 确保端点 URL 格式正确（包含协议和路径）
4. 检查网络连接和防火墙设置

#### 问题 3：401 错误频繁出现

**症状**：经常出现 401 未授权错误

**解决方案**：
1. 检查 Token 是否正确存储
2. 验证 Token 是否过期
3. 检查认证头是否正确注入
4. 确认服务器端 Token 验证逻辑

#### 问题 4：请求超时

**症状**：API 请求经常超时

**解决方案**：
1. 增加超时时间配置
2. 检查网络连接质量
3. 优化请求大小和频率
4. 使用重试机制

#### 问题 5：Android 平台 SSL 配置不生效

**症状**：Android 上自签名证书配置不生效

**解决方案**：
1. 检查 MethodChannel 是否正确注册
2. 验证原生插件实现
3. 确保在应用启动时调用 `HttpSSLOptions.apply()`
4. 检查后台任务中的 SSL 配置

### 最佳实践

#### 1. API 调用规范

```dart
// ✅ 正确：使用 ApiService 统一管理
final user = await apiService.usersApi.getMyUser();

// ❌ 错误：直接创建 ApiClient
final client = ApiClient();
final api = UsersApi(client);
```

#### 2. 错误处理规范

```dart
// ✅ 正确：统一错误处理
try {
  final assets = await apiService.assetsApi.getAllAssets();
  return assets;
} on ApiException catch (e) {
  ErrorHandler.handleError(e);
  return [];
} catch (e) {
  Logger('Repository').severe('Unexpected error', e);
  return [];
}

// ❌ 错误：忽略错误
final assets = await apiService.assetsApi.getAllAssets(); // 可能抛出异常
```

#### 3. 重试机制使用

```dart
// ✅ 正确：使用重试机制处理网络错误
final assets = await RetryHelper.retry(
  operation: () => apiService.assetsApi.getAllAssets(),
  config: const RetryConfig(maxRetries: 3),
  shouldRetry: RetryHelper.isRetryableError,
);

// ❌ 错误：手动重试逻辑
var attempts = 0;
while (attempts < 3) {
  try {
    return await apiService.assetsApi.getAllAssets();
  } catch (e) {
    attempts++;
    await Future.delayed(Duration(seconds: attempts));
  }
}
```

#### 4. 缓存使用

```dart
// ✅ 正确：合理使用缓存
final assets = await repository.getAssets(useCache: true);

// ❌ 错误：过度缓存或从不缓存
final assets = await repository.getAssets(useCache: true); // 所有请求都缓存
// 或
final assets = await repository.getAssets(useCache: false); // 从不使用缓存
```

#### 5. SSL 配置

```dart
// ✅ 正确：应用启动时配置 SSL
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 应用 SSL 配置
  HttpSSLOptions.apply();
  
  runApp(MyApp());
}

// ❌ 错误：在请求时配置 SSL
Future<void> makeRequest() async {
  HttpSSLOptions.apply(); // 不应该在请求时配置
  await apiService.assetsApi.getAllAssets();
}
```

---

## 参考文档

### 内部参考文档

- [PrismBox 移动端架构设计文档](../PrismBox%20移动端架构设计文档.md) - 第 3.3 节 API 对接模块
- [备份上传下载模块详细设计文档](./备份上传下载模块详细设计文档.md) - 上传下载任务中的 API 使用
- [媒体资源展示模块详细设计文档](./媒体资源展示模块详细设计文档.md) - 远程资源加载中的 API 使用

### 外部参考文档

- [Immich API 架构文档](../../../docs/immich参考/API_ARCHITECTURE.md) - Immich 移动端 API 对接架构参考
- [Immich HTTPS 模块详解](../../../docs/immich参考/架构详解/mobile-https-module.md) - SSL/TLS 配置详细实现
- [OpenAPI 规范](https://swagger.io/specification/) - OpenAPI 标准规范
- [Dart HTTP 文档](https://api.dart.dev/stable/dart-io/HttpClient-class.html) - Dart HTTP 客户端文档

### 技术文档

- [Dio 文档](https://pub.dev/packages/dio) - Dio HTTP 客户端库文档
- [flutter_secure_storage 文档](https://pub.dev/packages/flutter_secure_storage) - 安全存储库文档
- [Android SSL/TLS 文档](https://developer.android.com/training/articles/security-ssl) - Android SSL/TLS 配置文档
- [iOS Security Framework 文档](https://developer.apple.com/documentation/security) - iOS 安全框架文档

---

**文档版本**：v1.0  
**最后更新**：2024年  
**维护者**：PrismBox 开发团队