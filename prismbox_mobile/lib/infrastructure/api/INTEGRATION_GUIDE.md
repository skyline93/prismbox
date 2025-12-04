# API对接模块集成指南

## 概述

本文档说明如何集成和使用API对接模块的各个组件。

## 1. DriftStoreRepository集成

### 1.1 创建Store表

Store表已添加到数据库schema中，运行代码生成：

```bash
cd prismbox_mobile
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
await store.put(StoreKey.serverEndpoint, 'https://example.com/api');

// 获取值
final endpoint = store.tryGet<String>(StoreKey.serverEndpoint);

// 监听值变化
store.watch(StoreKey.serverEndpoint).listen((value) {
  print('Endpoint changed: $value');
});
```

## 2. OpenAPI客户端集成

### 2.1 生成OpenAPI客户端

首先安装openapi-generator：

```bash
npm install -g @openapitools/openapi-generator-cli
```

然后运行生成脚本：

```bash
cd prismbox_mobile
./scripts/generate_openapi_client.sh
```

### 2.2 更新ApiService使用生成的客户端

生成客户端后，更新`ApiService`以使用生成的客户端：

```dart
import 'package:prismbox/infrastructure/api/generated/api.dart';
import 'package:prismbox/infrastructure/api/generated/openapi_client_wrapper.dart';

class ApiService {
  late OpenApiClientWrapper _openApiClient;
  
  void setEndpoint(String endpoint) {
    _openApiClient = OpenApiClientWrapper(endpoint);
    // 设置认证
    final token = getAccessToken();
    if (token != null) {
      _openApiClient.setAuthentication(token);
    }
  }
  
  // 使用生成的客户端
  Future<LoginResponse> login(LoginInput input) async {
    return await _openApiClient.authApi.login(input);
  }
}
```

### 2.3 配置认证

生成的客户端需要手动配置认证头。在`OpenApiClientWrapper`中实现：

```dart
void setAuthentication(String token) {
  final apiClient = ApiClient(basePath: basePath);
  apiClient.setApiKey('x-immich-user-token', token);
  // 更新所有API实例
  authApi = AuthApi(apiClient);
  // ... 其他API
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

## 4. 完整集成示例

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
  
  // 4. 应用SSL配置
  HttpSSLOptions.apply();
  
  // 5. 如果已有保存的端点，恢复它
  final store = StoreService();
  final endpoint = store.tryGet<String>(StoreKey.serverEndpoint);
  if (endpoint != null) {
    ApiService().setEndpoint(endpoint);
  }
  
  runApp(MyApp());
}
```

## 5. 注意事项

1. **数据库迁移**：添加Store表后，数据库版本已更新到2。首次运行时会自动迁移。

2. **OpenAPI客户端**：生成客户端后需要运行`flutter pub get`安装依赖。

3. **Android插件**：确保`MainActivity`正确注册了`HttpSSLOptionsPlugin`。

4. **错误处理**：所有API调用都应该使用`ApiErrorHandler`处理错误。

5. **重试机制**：对于网络请求，建议使用`RetryHelper`实现自动重试。

## 6. 故障排查

### Store服务未初始化

错误：`StoreService not initialized`

解决：确保在`main()`函数中调用了`StoreService().init(repository)`

### OpenAPI客户端生成失败

错误：`openapi-generator not found`

解决：安装openapi-generator：`npm install -g @openapitools/openapi-generator-cli`

### Android SSL配置不生效

检查：
1. `MainActivity`是否正确注册了插件
2. 插件代码是否编译通过
3. 查看logcat日志是否有错误信息

## 7. 后续优化

1. **iOS SSL配置**：实现iOS平台的SSL配置（如果需要）
2. **客户端证书UI**：添加客户端证书上传和管理界面
3. **端点切换**：实现多个端点之间的自动切换
4. **请求缓存**：实现API响应缓存机制

