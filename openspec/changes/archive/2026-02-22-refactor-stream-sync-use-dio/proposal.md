# Change: 流式同步与 Checkpoint 统一使用 Dio

## Why

远程流式同步（`/api/v1/sync/assets/stream`）和服务端 checkpoint 上报（`POST /api/v1/sync/checkpoint`）当前使用原生 `http` 包和 `ApiService.getRequestHeaders()` 获取认证头。认证 token 来自 Store，与其它 API 使用的 Dio 内存 token 可能不同步，导致「认证未过期却返回 401」；且这两类请求不经过 Dio 的 401 自动刷新与重试，体验不一致。统一改为 Dio 可修复认证一致性并享受统一的重试与错误处理。

## What Changes

- 流式同步请求改为使用 `ApiService.dio` 发起，设置 `ResponseType.stream`，从 `response.data.stream` 读取 JSON Lines 流；取消逻辑使用 Dio 的 `CancelToken`。
- 服务端 checkpoint 上报改为使用 `ApiService.dio.post`，不再使用 `http` 或 `getRequestHeaders()`。
- ApiService 中 `_ResponseInterceptor` 对 `ResponseType.stream` 的响应跳过 ApiResponse 解析；`_LoggingInterceptor` 对流式响应体不做格式化日志。
- `NetworkConfig` 增加流式同步接收超时常量（可选，用于长同步）；`RemoteSyncService` 移除对 `package:http` 和 `getRequestHeaders()` 的依赖。
- 不做向后兼容：不保留基于 `http` 的旧路径。

## Impact

- Affected specs: `remote-asset-sync`
- Affected code:
  - `mobile/lib/features/remote_sync/services/remote_sync_service.dart`（流式同步与 checkpoint 实现）
  - `mobile/lib/infrastructure/api/api_service.dart`（拦截器对流式响应的兼容）
  - `mobile/lib/core/config/network_config.dart`（可选：流式同步超时常量）
