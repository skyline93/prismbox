# API对接模块实现说明

## 概述

本模块实现了PrismBox移动端的API对接功能，包括：
- 统一API服务管理（ApiService）
- SSL/TLS配置（HttpSSLOptions、HttpSSLCertOverride）
- 端点发现服务（EndpointDiscovery）
- 错误处理和重试机制
- 认证管理

## 安装依赖

在实现完成后，需要运行以下命令安装依赖：

```bash
cd prismbox_mobile
flutter pub get
```

## 文件结构

```
lib/
├── core/
│   └── storage/
│       ├── store_key.dart              # Store键定义
│       ├── store_service.dart          # Store服务（键值存储）
│       ├── store_repository.dart        # Store仓库接口和实现
│       └── secure_storage_service.dart  # 安全存储服务
│
└── infrastructure/
    └── api/
        ├── api_service.dart             # 统一API服务
        ├── exceptions/
        │   ├── api_exception.dart       # API异常定义
        │   └── api_error_handler.dart  # 错误处理工具
        ├── ssl/
        │   ├── http_ssl_options.dart    # SSL配置管理
        │   └── http_ssl_cert_override.dart # SSL证书覆盖
        ├── network/
        │   └── endpoint_discovery.dart  # 端点发现服务
        └── utils/
            ├── retry_helper.dart        # 重试机制工具
            └── url_helper.dart          # URL工具类
```

## 使用说明

### 1. 初始化

在应用启动时初始化Store服务和ApiService：

```dart
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/store_repository.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化Store服务
  final storeRepository = SharedPreferencesStoreRepository(); // 或DriftStoreRepository
  await StoreService().init(storeRepository);
  
  // 初始化ApiService
  ApiService().initialize();
  
  // 应用SSL配置
  HttpSSLOptions.apply();
  
  runApp(MyApp());
}
```

### 2. 设置服务器端点

```dart
final apiService = ApiService();

// 解析并设置端点（支持well-known发现）
final endpoint = await apiService.resolveAndSetEndpoint('https://example.com');
```

### 3. 登录和设置Token

```dart
// 登录后设置Token
await apiService.setAccessToken('your_access_token');

// 设置设备信息头
await apiService.setDeviceInfoHeader();
```

### 4. 调用API

```dart
final apiService = ApiService();
final dio = apiService.dio;

// 使用Dio调用API
final response = await dio.get('/api/v1/users/me');
```

### 5. 错误处理

```dart
import 'package:prismbox/infrastructure/api/exceptions/api_error_handler.dart';

try {
  await apiService.dio.get('/api/v1/users/me');
} catch (e) {
  final error = ApiErrorHandler.handleError(e);
  final message = ApiErrorHandler.getErrorMessage(error);
  print('Error: $message');
}
```

### 6. 重试机制

```dart
import 'package:prismbox/infrastructure/api/utils/retry_helper.dart';

final result = await RetryHelper.retry(
  operation: () => apiService.dio.get('/api/v1/users/me'),
  config: const RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(seconds: 1),
  ),
  shouldRetry: RetryHelper.isRetryableError,
);
```

## 注意事项

1. **Store服务初始化**：在使用Store服务之前，必须先调用`StoreService().init(repository)`
2. **SSL配置**：在应用启动时调用`HttpSSLOptions.apply()`应用SSL配置
3. **端点设置**：在调用API之前，必须先设置端点（通过`setEndpoint`或`resolveAndSetEndpoint`）
4. **Token管理**：Token会自动注入到所有API请求中，无需手动设置请求头

## 待完善功能

1. **OpenAPI客户端集成**：当前使用Dio直接调用API，后续可以集成OpenAPI生成的客户端
2. **DriftStoreRepository实现**：当前Store仓库使用SharedPreferences临时实现，需要实现基于Drift的版本
3. **Android原生SSL配置**：需要实现MethodChannel调用Android原生代码配置SSL
4. **401自动跳转登录**：需要在错误拦截器中实现自动跳转登录的逻辑

## 参考文档

- [API对接模块详细设计文档](../../doc/modules/API对接模块详细设计文档.md)
- [PrismBox移动端架构设计文档](../../doc/PrismBox%20移动端架构设计文档.md)

