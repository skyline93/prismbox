# Design: 流式同步统一使用 Dio

## Context

- 移动端标准 API 请求通过 Dio 发出，由 `_AuthInterceptor` 注入内存中的 access token，由 `_ErrorInterceptor` 在 401 时刷新 token 并重试。
- 流式同步与 checkpoint 此前用 `http.Client` 和 `ApiService.getRequestHeaders()`，token 仅来自 Store，与 Dio 内存 token 可能不一致；且无 401 刷新与重试。
- 后端流式接口返回 JSON Lines（非 ApiResponse 包装），Dio 默认 `ResponseType.json` 且 `_ResponseInterceptor` 假定 `response.data is Map`，直接复用会破坏流式解析。

## Goals / Non-Goals

- **Goals**：流式同步与 checkpoint 使用同一套 Dio 实例与拦截器，认证与 401 行为与其它接口一致；保持现有流式解析语义与取消语义。
- **Non-Goals**：不兼容旧 `http` 路径；不改变后端 API 契约；不要求为 Flutter Web 实现 stream fallback（可后续单独处理）。

## Decisions

- **使用主 Dio 实例 + 单次请求 Options**：流式请求使用 `_apiService.dio`，通过 `Options(responseType: ResponseType.stream, receiveTimeout: ...)` 指定流式与超时；不新增单独 `_streamDio`，避免重复拦截器与 baseUrl 维护。
- **响应拦截器按 responseType 跳过**：在 `_ResponseInterceptor.onResponse` 中，若 `response.requestOptions.responseType == ResponseType.stream`，直接 `handler.next(response)`，不解析 code/message/data。
- **日志拦截器跳过流式 body**：当 `response.data` 为 Dio 的 `ResponseBody` 时，仅打简短说明（如 `[Stream body]`），不调用 `formatResponseBody(response.data)`。
- **取消使用 Dio CancelToken**：`RemoteSyncService` 在每次 `syncRemoteStream` 创建 `CancelToken`，请求传入；`cancel()` 调用 `cancelToken.cancel()`。收到 `DioException(type: cancel)` 时视为用户取消，返回已有统计、不记入 errors。
- **Checkpoint 直接 dio.post**：`_saveServerCheckpoint` 使用 `_apiService.dio.post('/api/v1/sync/checkpoint', data: body)`，依赖现有拦截器注入认证与设备头；不再使用 `getRequestHeaders()` 或 `http`。

### Alternatives considered

- **单独 streamDio**：仅挂 Auth/Device 拦截器，不挂 ResponseInterceptor。可行但需维护两套 baseUrl/拦截器顺序，且 401 重试逻辑需确保用同一实例，复杂度更高，故不采用。
- **保留 http + 仅统一 token 来源**：让 `getRequestHeaders()` 优先读内存 token 再回退 Store。可缓解不一致，但 401 仍无法自动刷新与重试，故不采用。

## Risks / Trade-offs

- **Dio ResponseType.stream 在 Flutter Web 上的限制**：已知存在；本次不实现 Web fallback，若后续支持 Web 再单独处理。
- **长同步与 receiveTimeout**：默认 Dio 的 receiveTimeout 为 30 分钟；可为流式请求单独设更长（如 1 小时）或按需不设，在 `NetworkConfig` 中增加常量并在请求 Options 中使用。

## Migration Plan

- 实现顺序：先改 ApiService 拦截器（流式跳过解析/日志），再改 `_saveServerCheckpoint`（无流式），再改 `syncRemoteStream`（Dio + stream + CancelToken），最后移除 `http` 与 `getRequestHeaders()` 在本模块的用法。
- 无需数据迁移或后端变更；归档后更新 `specs/remote-asset-sync/spec.md` 即可。

## Open Questions

- 无。
