# Design: 后端统一计算文件 Hash

## Context

在 `decouple-local-remote-assets` 变更中，Decision 2 要求后端统一计算文件 hash，但目前后端代码仍然要求前端提供 hash。前端使用了临时方案（计算 hash）来保持功能正常，需要修改后端以支持后端统一计算。

## Current State

### 后端代码现状

1. **Handler 层** (`backend/internal/api/v1/media/handler.go`):
   - 要求 `hash` 字段必须存在且为 32 字符 MD5（第 71-79 行）
   - 在打开文件流之前进行秒传检查（第 126-164 行）
   - 秒传检查需要 hash 参数

2. **Service 层** (`backend/internal/service/media/service.go`):
   - `UploadMedia` 方法要求 hash 必须存在（第 208-210 行）
   - 使用 hash 构建存储 key（第 215 行）
   - 验证 hash 格式（第 208-210 行）

3. **存储层** (`backend/internal/storage/primary/local/storage.go`):
   - **已支持** hash 为空时计算 hash（第 162-201 行）
   - 当 hash 为空时，读取数据到临时文件，计算 hash，然后继续处理

### 前端代码现状

- 使用临时方案计算 hash（`prismbox_mobile/lib/services/backup/upload_orchestrator.dart` 第 645-657 行）
- 带有 TODO 注释说明这是临时方案，等待后端修改

## Design Decisions

### Decision 1: 在 Service 层计算 Hash

**What**: 当 hash 为空时，在 Service 层的 `UploadMedia` 方法中计算 hash。

**Why**:
- 存储层已经支持 hash 为空的情况，但需要在 Service 层协调
- Service 层需要 hash 来构建存储 key
- 计算 hash 后，可以使用 hash 进行秒传检查（如果文件已存在）

**Implementation**:
- 读取文件流的一部分来计算 hash
- 使用计算得到的 hash 构建存储 key
- 存储层会使用 hash 进行存储

**Alternatives considered**:
- 在 Handler 层计算 hash：需要先读取文件，然后才能进行秒传检查，失去了秒传优化的优势
- 在存储层计算 hash：存储层已经支持，但 Service 层需要 hash 来构建存储 key

### Decision 3: 秒传检查策略

**What**: 当 hash 为空时，跳过秒传检查；当 hash 提供时，进行秒传检查。

**Why**:
- 秒传检查需要 hash，如果 hash 为空，无法进行秒传检查
- 计算 hash 需要读取文件，如果先计算 hash 再检查，失去了秒传优化的优势（避免打开文件流）
- 虽然失去了秒传优化，但实现了后端统一计算 hash 的目标

**Trade-offs**:
- **优势**：实现后端统一计算 hash，简化前端代码
- **劣势**：无法进行秒传检查，需要读取文件流
- **接受**：这是实现后端统一计算 hash 的必要权衡

## Implementation Plan

### Phase 1: 修改后端 Handler 层

1. 修改 `handler.go` 的 `UploadMedia` 方法
2. 将 hash 从必填改为可选
3. 移除秒传检查（不再需要）
4. 将空的 hash 传递给 Service 层

### Phase 2: 修改后端 Service 层

1. 修改 `service.go` 的 `UploadMedia` 方法
2. 从文件流计算 hash
3. 使用计算得到的 hash 构建存储 key

### Phase 3: 更新前端代码

1. 移除前端 hash 计算代码
2. 移除 `hash` 字段
3. 移除相关导入和依赖

### Phase 4: 更新文档

1. 更新 API 文档，说明 `hash` 字段不再需要
2. 更新代码注释

