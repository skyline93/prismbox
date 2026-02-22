## 1. 配置与 ApiService 拦截器

- [x] 1.1 在 `NetworkConfig` 中增加 `syncStreamReceiveTimeout`（例如 `Duration(hours: 1)`），供流式同步请求使用。
- [x] 1.2 在 `_ResponseInterceptor.onResponse` 中，若 `response.requestOptions.responseType == ResponseType.stream`，直接调用 `handler.next(response)`，不解析 ApiResponse。
- [x] 1.3 在 `_LoggingInterceptor.onResponse` 中，若 `response.data` 类型为 Dio 的 `ResponseBody`，仅记录简短说明（如 `[Stream body]`），不调用 `formatResponseBody(response.data)`。

## 2. RemoteSyncService 使用 Dio

- [x] 2.1 将 `_saveServerCheckpoint` 改为使用 `_apiService.dio.post('/api/v1/sync/checkpoint', data: requestBody)`，移除对 `http` 和 `getRequestHeaders()` 的调用；保留 204 成功与失败日志逻辑。
- [x] 2.2 在 `syncRemoteStream` 中：使用 `_apiService.dio.post` 请求 `/api/v1/sync/assets/stream`，设置 `Options(responseType: ResponseType.stream, receiveTimeout: NetworkConfig.syncStreamReceiveTimeout)` 及 `Content-Type`/`Accept` 头；使用 Dio 的 `CancelToken`，在 `cancel()` 中调用 `cancelToken.cancel()`。
- [x] 2.3 从 `response.data` 取得 `ResponseBody`，使用 `response.data.stream.transform(utf8.decoder)` 进行 `await for` 循环，保持现有 `SyncStreamHandler` 与 `_handleSyncEvent`、批量写入、shouldResync 递归逻辑不变。
- [x] 2.4 在 catch 中识别 `DioException` 且 `type == DioExceptionType.cancel` 时，视为用户取消，返回当前统计与已有 errors，不追加取消为错误。
- [x] 2.5 移除 `remote_sync_service.dart` 中对 `package:http` 的 import 及所有 `http.Request`、`http.Client`、`client.send`、`client.close()`、`getRequestHeaders()` 的用法。

## 3. 质量与文档

- [x] 3.1 运行 Dart 分析/ linter，修复 `remote_sync_service.dart` 与 `api_service.dart` 中新引入的告警。
- [x] 3.2 更新 `remote_sync_service.dart` 中与流式同步、checkpoint、取消相关的注释，使其反映 Dio 实现。
