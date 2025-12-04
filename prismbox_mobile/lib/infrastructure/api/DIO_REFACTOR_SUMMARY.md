# Dio 方式整改总结

## 整改完成时间
2024年

## 整改目标
将 API 对接模块从 OpenAPI 客户端方式改为 Dio 方式，提高灵活度和可控性。

## 已完成的整改项

### ✅ 高优先级（必须完成）

#### 1. 统一响应格式处理（响应拦截器）
- **文件**: `api_service.dart`
- **实现**: `_ResponseInterceptor` 类
- **功能**: 
  - 自动解析后端 `ApiResponse{code, message, data}` 格式
  - 如果 `code != 0`，转换为 `DioException`（状态码 400）
  - 如果 `code == 0`，提取 `data` 字段，直接返回业务数据
- **效果**: 调用方无需手动解析 `ApiResponse`，直接使用 `response.data`

#### 2. 错误消息提取优化
- **文件**: `api_error_handler.dart`
- **改进**: 优先使用后端 `ApiResponse` 格式的 `message` 字段
- **效果**: 错误消息更准确，符合后端响应格式

#### 3. 401 自动跳转登录实现
- **文件**: `api_service.dart`
- **实现**: 
  - 添加 `OnUnauthorizedCallback` 回调类型
  - `_ErrorInterceptor` 在 401 错误时自动清除 Token 并触发回调
  - 提供 `setOnUnauthorizedCallback()` 方法设置回调
- **效果**: 401 错误自动处理，支持自定义跳转逻辑

#### 4. Dio 与 HttpOverrides 集成
- **文件**: `api_service.dart`
- **实现**: 在 `_configureDio()` 中配置 `IOHttpClientAdapter`，使用系统 `HttpClient`
- **效果**: Dio 请求自动应用 `HttpOverrides.global` 的 SSL 配置

### ✅ 中优先级（建议完成）

#### 5. 重试拦截器
- **文件**: `api_service.dart`
- **实现**: `_RetryInterceptor` 类
- **功能**:
  - 自动重试网络错误、超时、5xx 错误
  - 最大重试 3 次
  - 指数退避策略（1秒、2秒、3秒）
- **效果**: 提高网络请求的可靠性

#### 6. 日志拦截器
- **文件**: `api_service.dart`
- **实现**: `_LoggingInterceptor` 类
- **功能**:
  - 记录请求信息（方法、URL、请求体）
  - 记录响应信息（状态码、URL）
  - 记录错误信息（错误类型、URL、堆栈）
- **效果**: 便于调试和问题排查

#### 7. User-Agent 头设置和连接池配置
- **文件**: `api_service.dart`
- **实现**:
  - 设置 `User-Agent: PrismBox-Mobile/1.0`
  - 配置连接池：`maxConnectionsPerHost = 16`
  - 启用自动解压缩：`autoUncompress = true`
- **效果**: 提升性能和可识别性

### ✅ 低优先级（可选完成）

#### 8. 文件上传专用 Dio 实例
- **文件**: `api_service.dart`
- **实现**: `_fileDio` 实例，超时时间更长（1小时）
- **功能**: 提供 `fileDio` getter 用于大文件上传
- **效果**: 大文件上传不会因超时失败

#### 9. 统一响应模型类
- **文件**: `models/api_response.dart`
- **实现**: `ApiResponse<T>` 泛型类
- **功能**: 提供类型安全的响应模型（可选使用）
- **效果**: 如果需要手动解析响应，可以使用此模型

## 代码结构

### 拦截器执行顺序
1. `_LoggingInterceptor` - 记录请求
2. `_AuthInterceptor` - 注入认证头
3. `_ResponseInterceptor` - 处理响应格式
4. `_RetryInterceptor` - 重试失败请求
5. `_LoggingInterceptor` - 记录响应/错误
6. `_ErrorInterceptor` - 转换错误类型

### 新增文件
- `models/api_response.dart` - 统一响应模型类
- `DIO_USAGE.md` - 使用指南
- `DIO_REFACTOR_SUMMARY.md` - 整改总结（本文件）

### 修改文件
- `api_service.dart` - 核心实现，添加了所有拦截器和配置
- `api_error_handler.dart` - 优化错误消息提取

## 使用方式

### 初始化
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 ApiService
  ApiService().initialize();
  
  // 设置 401 回调
  ApiService().setOnUnauthorizedCallback(() {
    // 跳转登录
  });
  
  // 应用 SSL 配置
  HttpSSLOptions.apply();
  
  runApp(MyApp());
}
```

### 基本使用
```dart
final dio = ApiService().dio;

// GET 请求
final response = await dio.get('/media');
final data = response.data; // 已经是业务数据，无需解析 ApiResponse

// POST 请求
final response = await dio.post('/auth/login', data: {...});

// 文件上传
final fileDio = ApiService().fileDio;
final response = await fileDio.post('/media/upload-stream', data: formData);
```

### 错误处理
```dart
try {
  await dio.get('/media');
} on AuthenticationException catch (e) {
  // 401 错误（已自动清除 Token 并触发回调）
} on NetworkException catch (e) {
  // 网络错误
} on ApiException catch (e) {
  // 其他 API 错误
}
```

## 与文档的差异

### 文档描述（OpenAPI 方式）
- 使用 OpenAPI 生成的客户端（`UsersApi`、`AssetsApi` 等）
- 实现 `Authentication` 接口
- 通过 `applyToParams()` 注入认证头

### 实际实现（Dio 方式）
- 使用 Dio 客户端
- 通过拦截器注入认证头
- 更灵活，支持自定义处理

## 后续建议

1. **更新架构文档**: 将 `API对接模块详细设计文档.md` 更新为 Dio 方式
2. **添加单元测试**: 为拦截器和错误处理添加测试
3. **性能监控**: 添加请求性能监控（可选）
4. **缓存支持**: 如果需要，可以添加响应缓存拦截器

## 注意事项

1. **响应格式**: 响应拦截器已自动处理，`response.data` 直接是业务数据
2. **401 错误**: 必须设置 `onUnauthorized` 回调，否则不会自动跳转登录
3. **SSL 配置**: 必须在应用启动时调用 `HttpSSLOptions.apply()`
4. **重试机制**: 自动重试，无需手动处理，但可以通过 `RetryHelper` 手动控制

## 测试建议

1. **响应格式测试**: 验证 `ApiResponse` 格式是否正确解析
2. **错误处理测试**: 验证各种错误类型是否正确转换
3. **401 处理测试**: 验证 401 错误是否自动清除 Token 并触发回调
4. **重试机制测试**: 验证网络错误是否自动重试
5. **SSL 配置测试**: 验证自签名证书是否正常工作

