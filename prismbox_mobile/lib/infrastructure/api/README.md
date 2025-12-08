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
        ├── api_service.dart             # 统一API服务（Dio实现）
        ├── models/
        │   └── api_response.dart        # 统一响应模型类
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

**服务器地址配置**：

服务器地址在 `lib/config/app_config.dart` 中配置：

```dart
// lib/config/app_config.dart
class ApiConfig {
  static const String serverBaseUrl = 'https://your-server.com';
}
```

修改后需要重新编译应用。`ApiService.initialize()` 会自动从 `AppConfig` 读取端点。

**端点发现**（可选）：

如果需要临时使用端点发现功能：

```dart
final apiService = ApiService();

// 解析并设置端点（支持well-known发现，但不持久化）
final endpoint = await apiService.resolveAndSetEndpoint('https://example.com');
```

### 3. 登录和设置Token

```dart
// 登录后设置Token
await apiService.setAccessToken('your_access_token');

// 设置设备信息头
await apiService.setDeviceInfoHeader();
```

### 4. 设置 401 回调

```dart
// 设置 401 错误回调（跳转登录）
ApiService().setOnUnauthorizedCallback(() {
  // 根据实际路由系统实现跳转
  // 例如使用 GoRouter:
  // goRouter.go('/login');
  // 或使用 AutoRoute:
  // appRouter.pushAndClearStack(LoginRoute());
});
```

### 5. 调用API

```dart
final apiService = ApiService();
final dio = apiService.dio;

// GET 请求
final response = await dio.get('/media');
final data = response.data; // 已经是业务数据，无需解析 ApiResponse

// POST 请求
final response = await dio.post('/auth/login', data: {
  'email': 'user@example.com',
  'password': 'password123',
});

// 文件上传（使用专用 Dio 实例）
final fileDio = apiService.fileDio;
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile('/path/to/file.jpg'),
  'hash': 'sha256_hash_here',
});
final response = await fileDio.post('/media/upload-stream', data: formData);
```

### 6. 错误处理

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

### 7. 重试机制

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
3. **服务器地址配置**：服务器地址在 `lib/config/app_config.dart` 中配置，`ApiService.initialize()` 会自动读取
4. **Token管理**：Token会自动注入到所有API请求中，无需手动设置请求头

## 核心特性

1. **统一响应格式处理**：自动解析后端 `ApiResponse{code, message, data}` 格式
2. **自动重试机制**：网络错误和 5xx 错误自动重试 3 次
3. **自动错误转换**：所有错误统一转换为 `ApiException` 及其子类
4. **401 自动处理**：自动清除 Token 并触发回调
5. **SSL/TLS 支持**：支持自签名证书和客户端证书
6. **文件上传支持**：提供专用 Dio 实例，超时时间更长

## 详细文档

- [Dio 使用指南](./DIO_USAGE.md) - 详细的使用说明和示例
- [整改总结](./DIO_REFACTOR_SUMMARY.md) - 整改完成情况
- [API对接模块详细设计文档](../../doc/modules/API对接模块详细设计文档.md)

## 参考文档

- [API对接模块详细设计文档](../../doc/modules/API对接模块详细设计文档.md)
- [PrismBox移动端架构设计文档](../../doc/PrismBox%20移动端架构设计文档.md)

