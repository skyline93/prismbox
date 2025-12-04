# Dio 方式 API 对接使用指南

## 概述

本模块使用 Dio 作为 HTTP 客户端，提供了完整的 API 对接功能，包括：
- 统一响应格式处理
- 自动重试机制
- 错误处理和转换
- SSL/TLS 配置支持
- 401 自动跳转登录

## 初始化

### 1. 在应用启动时初始化

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 ApiService
  ApiService().initialize();
  
  // 设置 401 错误回调（跳转登录）
  ApiService().setOnUnauthorizedCallback(() {
    // 根据实际路由系统实现跳转
    // 例如使用 GoRouter:
    // goRouter.go('/login');
    // 或使用 AutoRoute:
    // appRouter.pushAndClearStack(LoginRoute());
  });
  
  // 应用 SSL 配置
  HttpSSLOptions.apply();
  
  runApp(MyApp());
}
```

### 2. 设置服务器端点

```dart
// 方式1：直接设置端点
ApiService().setEndpoint('https://api.example.com/api/v1');

// 方式2：自动发现并设置端点（推荐）
final endpoint = await ApiService().resolveAndSetEndpoint('https://example.com');
```

## 基本使用

### 1. 使用标准 Dio 实例

```dart
final apiService = ApiService();
final dio = apiService.dio;

// GET 请求
final response = await dio.get('/media');
final data = response.data; // 已自动提取 ApiResponse 的 data 字段

// POST 请求
final response = await dio.post(
  '/auth/login',
  data: {
    'email': 'user@example.com',
    'password': 'password123',
  },
);

// PUT 请求
final response = await dio.put(
  '/media/123',
  data: {'title': 'New Title'},
);

// DELETE 请求
await dio.delete('/media/123');
```

### 2. 使用文件上传 Dio 实例

```dart
final apiService = ApiService();
final fileDio = apiService.fileDio; // 超时时间更长，适合大文件上传

// 上传文件
final formData = FormData.fromMap({
  'file': await MultipartFile.fromFile('/path/to/file.jpg'),
  'hash': 'sha256_hash_here',
  'item_type': 'image',
});

final response = await fileDio.post('/media/upload-stream', data: formData);
```

## 响应格式处理

后端使用统一的 `ApiResponse` 格式：

```json
{
  "code": 0,      // 0=成功, 1=失败
  "message": "...",
  "data": {...}
}
```

**响应拦截器会自动处理**：
- 如果 `code != 0`，会抛出 `DioException`（状态码 400）
- 如果 `code == 0`，会提取 `data` 字段，直接返回业务数据

因此，你的代码中 `response.data` 已经是业务数据，无需手动解析：

```dart
// ✅ 正确：直接使用 response.data
final response = await dio.get('/media');
final mediaList = response.data as List; // 已经是业务数据

// ❌ 错误：不需要手动解析 ApiResponse
// final apiResponse = ApiResponse.fromJson(response.data);
// final mediaList = apiResponse.data;
```

## 错误处理

### 1. 统一错误类型

所有错误都会被转换为 `ApiException` 或其子类：

```dart
try {
  final response = await dio.get('/media');
} on AuthenticationException catch (e) {
  // 401 错误
  print('登录已过期: ${e.message}');
} on NetworkException catch (e) {
  // 网络错误
  print('网络连接失败: ${e.message}');
} on ApiException catch (e) {
  // 其他 API 错误
  print('API 错误: ${e.statusCode} - ${e.message}');
} catch (e) {
  // 未知错误
  print('未知错误: $e');
}
```

### 2. 获取用户友好的错误消息

```dart
try {
  await dio.get('/media');
} catch (e) {
  final message = ApiErrorHandler.getErrorMessage(e);
  // 显示给用户
  showSnackBar(message);
}
```

### 3. 401 自动处理

当收到 401 错误时：
1. 自动清除 Token
2. 自动调用 `onUnauthorized` 回调（如果已设置）

```dart
ApiService().setOnUnauthorizedCallback(() {
  // 跳转到登录页
  Navigator.pushReplacementNamed(context, '/login');
});
```

## 重试机制

重试拦截器会自动重试以下错误：
- 网络连接错误
- 请求超时
- 5xx 服务器错误

默认配置：
- 最大重试次数：3 次
- 重试延迟：1秒、2秒、3秒（指数退避）

如需手动控制重试，可以使用 `RetryHelper`：

```dart
import 'package:prismbox/infrastructure/api/utils/retry_helper.dart';

final result = await RetryHelper.retry(
  operation: () => dio.get('/media'),
  config: const RetryConfig(
    maxRetries: 5,
    initialDelay: Duration(seconds: 2),
  ),
  shouldRetry: RetryHelper.isRetryableError,
);
```

## 认证

### 1. 设置 Token

```dart
await ApiService().setAccessToken('your_access_token');
```

Token 会自动注入到所有请求的 `x-immich-user-token` 头中。

### 2. 获取请求头（用于 background_downloader 等）

```dart
final headers = ApiService.getRequestHeaders();
// 包含认证头和自定义头
```

### 3. 清除 Token

```dart
await ApiService().clearAccessToken();
```

## SSL/TLS 配置

### 1. 允许自签名证书

```dart
// 在设置中启用
HttpSSLOptions.applyFromSettings(true);

// 或在应用启动时应用
HttpSSLOptions.apply();
```

### 2. 配置客户端证书

客户端证书通过 `SecureStorageService` 存储，`HttpSSLOptions` 会自动加载。

## 日志

日志拦截器会自动记录：
- 请求信息（方法、URL、请求体）
- 响应信息（状态码、URL）
- 错误信息（错误类型、URL、堆栈）

日志级别使用 `Logger`，可以通过配置日志级别控制输出。

## 最佳实践

### 1. 统一错误处理

```dart
Future<T> safeApiCall<T>(Future<Response> Function() apiCall) async {
  try {
    final response = await apiCall();
    return response.data as T;
  } on AuthenticationException {
    // 401 错误已自动处理，这里可以做额外操作
    rethrow;
  } on NetworkException catch (e) {
    // 网络错误，显示提示
    showSnackBar('网络连接失败，请检查网络设置');
    rethrow;
  } on ApiException catch (e) {
    // 其他 API 错误
    showSnackBar(ApiErrorHandler.getErrorMessage(e));
    rethrow;
  }
}

// 使用
final mediaList = await safeApiCall<List>(
  () => dio.get('/media'),
);
```

### 2. 使用 Repository 模式

```dart
class MediaRepository {
  final Dio _dio = ApiService().dio;

  Future<List<Media>> getMediaList() async {
    try {
      final response = await _dio.get('/media');
      return (response.data as List)
          .map((json) => Media.fromJson(json))
          .toList();
    } catch (e) {
      throw ApiErrorHandler.handleError(e);
    }
  }
}
```

### 3. 文件上传

```dart
Future<void> uploadMedia(String filePath, String hash) async {
  final fileDio = ApiService().fileDio; // 使用文件上传专用实例
  
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(filePath),
    'hash': hash,
    'item_type': 'image',
  });

  try {
    final response = await fileDio.post('/media/upload-stream', data: formData);
    // 处理响应
  } catch (e) {
    // 处理错误
  }
}
```

## 与 OpenAPI 客户端的区别

| 特性 | Dio 方式 | OpenAPI 客户端 |
|------|---------|---------------|
| 类型安全 | 手动定义模型 | 自动生成类型 |
| 灵活性 | 高 | 中等 |
| 维护成本 | 需要手动维护 | API 变更时重新生成 |
| 响应格式 | 需要手动处理 | 自动处理 |
| 错误处理 | 需要手动转换 | 自动转换 |
| 适用场景 | 灵活需求、特殊场景 | 标准 REST API |

## 注意事项

1. **响应格式**：响应拦截器已自动处理 `ApiResponse` 格式，`response.data` 直接是业务数据
2. **错误处理**：所有错误都会转换为 `ApiException`，建议统一处理
3. **401 错误**：会自动清除 Token 并触发回调，确保已设置回调
4. **重试机制**：自动重试网络错误和 5xx 错误，无需手动处理
5. **SSL 配置**：需要在应用启动时调用 `HttpSSLOptions.apply()`

