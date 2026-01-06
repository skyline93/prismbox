# API对接模块集成指南

## 概述

本文档说明如何集成和使用API对接模块的各个组件。

## 1. DriftStoreRepository集成

### 1.1 创建Store表

Store表已添加到数据库schema中，运行代码生成：

```bash
cd mobile
flutter pub run build_runner build --delete-conflicting-outputs
```

### 1.2 初始化Store服务

在应用启动时初始化：

```dart
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/store_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库
  await DatabaseConnection.initializeDatabaseIsolate();
  final database = await DatabaseConnection.getInstance();
  
  // 初始化Store服务
  final storeRepository = DriftStoreRepository(database);
  await StoreService().init(storeRepository);
  
  runApp(MyApp());
}
```

### 1.3 使用Store服务

```dart
final store = StoreService();

// 存储值
await store.put(StoreKey.accessToken, 'your_token');

// 获取值
final token = store.tryGet<String>(StoreKey.accessToken);

// 监听值变化
store.watch(StoreKey.accessToken).listen((value) {
  print('Token changed: $value');
});
```

**注意**：服务器端点配置已迁移到 `app_config.dart`，不再使用 Store 存储。

## 2. ApiService 集成（Dio 方式）

### 2.1 初始化 ApiService

在应用启动时初始化：

```dart
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 ApiService
  ApiService().initialize();
  
  // 设置 401 错误回调（跳转登录）
  ApiService().setOnUnauthorizedCallback(() {
    // 根据实际路由系统实现跳转
    // 例如使用 GoRouter:
    // goRouter.go('/login');
  });
  
  // 应用 SSL 配置
  HttpSSLOptions.apply();
  
  runApp(MyApp());
}
```

### 2.2 配置服务器地址

服务器地址在 `lib/config/app_config.dart` 中配置：

```dart
// lib/config/app_config.dart
class ApiConfig {
  static const String serverBaseUrl = 'https://your-server.com';
}
```

修改后需要重新编译应用。`ApiService.initialize()` 会自动从 `AppConfig` 读取端点。

**注意**：
- 服务器地址是编译时配置，修改后需要重新编译
- `resolveAndSetEndpoint()` 方法仍可用于端点发现，但结果不会持久化
- 如需临时设置端点，可以使用 `apiService.setEndpoint('https://api.example.com/api/v1')`

### 2.3 使用 Dio 调用 API

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

### 2.4 错误处理

```dart
import 'package:prismbox/infrastructure/api/exceptions/api_error_handler.dart';

try {
  await dio.get('/media');
} on AuthenticationException catch (e) {
  // 401 错误（已自动清除 Token 并触发回调）
  print('登录已过期: ${e.message}');
} on NetworkException catch (e) {
  // 网络错误
  print('网络连接失败: ${e.message}');
} on ApiException catch (e) {
  // 其他 API 错误
  print('API 错误: ${e.statusCode} - ${e.message}');
}

// 或使用统一错误处理
try {
  await dio.get('/media');
} catch (e) {
  final message = ApiErrorHandler.getErrorMessage(e);
  showSnackBar(message);
}
```

## 3. Android原生SSL配置

### 3.1 插件注册

插件已在`MainActivity`中注册，无需额外配置。

### 3.2 使用

SSL配置会在`HttpSSLOptions.apply()`时自动调用Android原生代码：

```dart
// 在应用启动时
HttpSSLOptions.apply();

// 或在设置变更时
HttpSSLOptions.applyFromSettings(true);
```

### 3.3 测试

在Android设备上测试自签名证书：

1. 设置服务器使用自签名证书
2. 在应用中启用"允许自签名证书"
3. 尝试连接服务器，应该能正常连接

## 4. 响应格式说明

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

## 5. 完整集成示例

```dart
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/store_repository.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. 初始化数据库
  await DatabaseConnection.initializeDatabaseIsolate();
  final database = await DatabaseConnection.getInstance();
  
  // 2. 初始化Store服务
  final storeRepository = DriftStoreRepository(database);
  await StoreService().init(storeRepository);
  
  // 3. 初始化ApiService
  ApiService().initialize();
  
  // 4. 设置 401 回调
  ApiService().setOnUnauthorizedCallback(() {
    // 跳转登录
  });
  
  // 5. 应用SSL配置
  HttpSSLOptions.apply();
  
  // 注意：服务器端点已从 AppConfig 自动读取，无需手动设置
  
  runApp(MyApp());
}
```

## 6. 注意事项

1. **数据库迁移**：添加Store表后，数据库版本已更新到2。首次运行时会自动迁移。

2. **响应格式**：响应拦截器已自动处理 `ApiResponse` 格式，`response.data` 直接是业务数据。

3. **401 错误**：必须设置 `onUnauthorized` 回调，否则不会自动跳转登录。

4. **SSL 配置**：必须在应用启动时调用 `HttpSSLOptions.apply()`。

5. **服务器地址配置**：服务器地址在 `lib/config/app_config.dart` 中配置，修改后需要重新编译应用。

6. **重试机制**：自动重试网络错误和 5xx 错误，无需手动处理。如需手动控制，可以使用 `RetryHelper`。

7. **Android插件**：确保`MainActivity`正确注册了`HttpSSLOptionsPlugin`。

## 7. 故障排查

### Store服务未初始化

错误：`StoreService not initialized`

解决：确保在`main()`函数中调用了`StoreService().init(repository)`

### 响应格式解析错误

错误：`response.data` 不是预期的格式

解决：检查后端是否返回了正确的 `ApiResponse` 格式。响应拦截器会自动处理。

### Android SSL配置不生效

检查：
1. `MainActivity`是否正确注册了插件
2. 插件代码是否编译通过
3. 查看logcat日志是否有错误信息

## 8. 后续优化

1. **iOS SSL配置**：实现iOS平台的SSL配置（如果需要）
2. **客户端证书UI**：添加客户端证书上传和管理界面
3. **端点切换**：实现多个端点之间的自动切换
4. **请求缓存**：实现API响应缓存机制
5. **性能监控**：添加请求性能监控（可选）

## 9. 参考文档

- [Dio 使用指南](./DIO_USAGE.md) - 详细的使用说明和示例
- [整改总结](./DIO_REFACTOR_SUMMARY.md) - 整改完成情况
- [API对接模块详细设计文档](../../doc/modules/API对接模块详细设计文档.md)

