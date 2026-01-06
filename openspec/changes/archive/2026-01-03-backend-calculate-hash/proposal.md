# Change: 后端统一计算文件 Hash

## Why

在 `decouple-local-remote-assets` 变更中，设计文档要求后端统一计算文件 hash，但目前后端代码仍然要求前端提供 hash。这导致：

1. **设计与实现不一致**：设计文档要求后端统一计算，但实际实现仍然是前端计算
2. **临时方案需要清理**：前端使用了临时方案（计算 hash）来保持功能正常，需要移除
3. **跨平台一致性问题**：如果前端继续计算 hash，仍然存在跨平台不一致的风险
4. **性能优化未实现**：设计目标是通过后端统一计算减少前端计算开销，但目前未实现

通过修改后端代码以支持后端统一计算 hash，可以：
- 实现设计文档中的决策（Decision 2: 后端统一计算 hash）
- 移除前端临时方案，简化前端代码
- 确保 hash 计算的统一性和一致性
- 减少前端计算开销

## What Changes

- **BREAKING**: 修改后端 Handler 层，允许 `hash` 字段为空或可选
- **BREAKING**: 修改后端 Service 层，支持后端计算 hash（当 hash 为空时）
- **BREAKING**: 修改后端秒传检查逻辑，支持在 hash 为空时跳过秒传检查
- 移除前端临时方案，前端不再发送 `hash` 字段
- 更新 API 文档，说明 `hash` 字段为可选

## Impact

- **Affected specs**: 
  - 修改 `asset-upload` 能力规范（资产上传）
- **Affected code**: 
  - `backend/internal/api/v1/media/handler.go` - 修改 Handler，允许 hash 为空
  - `backend/internal/service/media/service.go` - 修改 Service，支持后端计算 hash
  - `mobile/lib/services/backup/upload_orchestrator.dart` - 移除前端 hash 计算
- **API Changes**:
  - `/api/v1/media/upload-stream` - `hash` 字段从必填改为可选
  - 当 `hash` 为空时，后端将计算 hash

