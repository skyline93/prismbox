# WiFi等待任务自动恢复功能缺失

**状态**: 待修复  
**优先级**: 高  
**创建时间**: 2025

## 问题描述

当前实现中，当自动备份任务因网络不是WiFi环境而被暂存时，虽然任务状态被设置为 `waitingForWifi` 并创建了数据库记录，但**缺少自动恢复机制**。任务会一直停留在等待状态，直到用户手动操作或应用重启。

## 当前实现分析

### 现有流程

1. **任务创建阶段** (`UploadService._enqueueUploadJob` / `BackupgroundUploadService._enqueueUploadJob`)
   - 检查网络状态和用户设置
   - 如果 `source == UploadSource.autoBackup` 且 `isBackupOnWifiOnly == true` 且当前不是WiFi
   - 设置 `canUpload = false`，`initialStatus = UploadJobStatus.waitingForWifi`
   - 创建数据库记录（包含 `jobId`, `filePath`, `fileHash`, `totalSize` 等）
   - **但不创建实际上传任务**（`if (!canUpload) return;`）

2. **问题点**
   - ❌ 没有监听网络连接变化
   - ❌ 没有查询 `waitingForWifi` 状态任务的方法
   - ❌ 没有恢复等待中任务的逻辑
   - ❌ 任务会永久停留在等待状态

## 需要实现的功能

### 1. 数据库查询方法

在 `UploadJobDao` 中添加查询等待WiFi任务的方法：

```dart
// mobile/lib/data/datasources/local_db/daos/upload_job_dao.dart

Future<List<UploadJob>> getWaitingForWifiJobs() {
  return (select(uploadJobs)
    ..where((tbl) => tbl.status.equalsValue(UploadJobStatus.waitingForWifi)))
    .get();
}
```

### 2. 网络监听和自动恢复

在 `UploadService` 和 `BackupgroundUploadService` 中实现：

#### 2.1 网络连接监听

- 使用 `Connectivity().onConnectivityChanged` 监听网络变化
- 当检测到WiFi连接时，触发恢复流程

#### 2.2 任务恢复逻辑

需要实现 `_resumeWaitingForWifiJobs()` 方法：

1. 查询所有 `waitingForWifi` 状态的任务
2. 再次验证网络状态和用户设置
3. 对每个任务：
   - 验证文件是否存在
   - 从数据库获取关联的 `MediaAsset` 信息（通过 `fileHash` 或 `cloudUuid`）
   - 重新创建上传任务（复用现有的任务创建逻辑）
   - 更新任务状态为 `uploading`
   - 将任务加入上传队列

### 3. 服务初始化

在服务初始化时：
- 启动网络监听
- 执行一次检查，恢复已等待的任务（应用重启后）

## 实施步骤

### 阶段一：数据库层

1. ✅ 在 `UploadJobDao` 中添加 `getWaitingForWifiJobs()` 方法
2. 确认 `UploadJobs` 表结构是否包含足够信息来恢复任务
   - 当前包含：`jobId`, `filePath`, `fileHash`, `totalSize`, `status`
   - 可能需要通过关联查询获取：`assetId`, `mediaType`, `mediaTakenAt`

### 阶段二：服务层 - UploadService

1. 添加网络连接监听
   ```dart
   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
   ```

2. 实现 `initialize()` 方法
   - 启动网络监听
   - 执行初始检查

3. 实现 `_resumeWaitingForWifiJobs()` 方法
   - 查询等待中的任务
   - 验证网络和设置
   - 批量恢复任务

4. 实现 `_resumeWaitingJob(UploadJob job)` 方法
   - 验证文件存在性
   - 获取关联的 MediaAsset
   - 创建上传任务
   - 更新状态并入队

5. 实现 `dispose()` 方法
   - 取消网络监听

### 阶段三：服务层 - BackupgroundUploadService

1. 实现与 `UploadService` 类似的网络监听和恢复逻辑
2. 注意：创建帖子上传不受WiFi限制，但如果有其他场景需要，也应支持

### 阶段四：初始化集成

1. 在 `TransferManager.initialize()` 或应用启动时调用服务的 `initialize()` 方法
2. 确保服务生命周期管理正确

### 阶段五：测试

1. **测试场景1**：自动备份 + WiFi限制
   - 关闭WiFi
   - 触发自动备份
   - 验证任务状态为 `waitingForWifi`
   - 连接WiFi
   - 验证任务自动恢复并开始上传

2. **测试场景2**：应用重启
   - 在非WiFi环境下创建等待任务
   - 关闭应用
   - 连接WiFi
   - 重启应用
   - 验证任务自动恢复

3. **测试场景3**：多个等待任务
   - 创建多个等待任务
   - 连接WiFi
   - 验证所有任务都能正确恢复

## 技术细节

### 数据关联问题

当前 `UploadJobs` 表不直接包含 `assetId`，需要通过以下方式关联：

1. **通过 `fileHash` 关联**
   - `UploadJob.fileHash` → `MediaAsset.contentHash`
   - 可能需要处理哈希冲突

2. **通过 `cloudUuid` 关联**
   - 在创建任务时，`MediaAsset.cloudUuid` 已设置
   - 但 `UploadJobs` 表不包含 `cloudUuid`
   - 需要从 `MediaAsset` 表查询

3. **建议方案**
   - 在 `_enqueueUploadJob` 中，将 `assetId` 或 `cloudUuid` 存储在任务的 `metaData` 中
   - 或者添加一个关联表字段（需要数据库迁移）

### 任务恢复时的信息获取

恢复任务时需要的信息：
- ✅ `filePath` - 从 `UploadJob` 获取
- ✅ `fileHash` - 从 `UploadJob` 获取
- ✅ `cloudUuid` - 需要从 `MediaAsset` 获取
- ✅ `mediaType` - 需要从 `MediaAsset` 获取
- ✅ `mediaTakenAt` - 需要从 `MediaAsset` 获取
- ✅ `assetId` - 需要从 `MediaAsset` 获取（用于更新状态）

### 错误处理

恢复任务时可能遇到的错误：
1. 文件不存在 - 标记任务为失败
2. MediaAsset 不存在 - 标记任务为失败
3. 无法获取访问令牌 - 跳过，等待下次重试
4. 网络再次断开 - 任务会再次进入等待状态

## 相关文件

- `mobile/lib/services/transfer/upload_service.dart` - 主要实现位置
- `mobile/lib/services/transfer/backupground_upload_service.dart` - 需要类似实现
- `mobile/lib/data/datasources/local_db/daos/upload_job_dao.dart` - 需要添加查询方法
- `mobile/lib/data/datasources/local_db/tables/upload_jobs.dart` - 表结构定义
- `mobile/lib/core/enums.dart` - `UploadJobStatus.waitingForWifi` 枚举定义

## 优先级

**高优先级** - 这是核心功能缺失，影响用户体验。用户设置了WiFi限制后，如果不在WiFi环境下，任务会永久等待，无法自动恢复。

## 参考

- `connectivity_plus` 包文档：https://pub.dev/packages/connectivity_plus
- 当前实现参考：`mobile/lib/services/transfer/upload_service.dart:166-260`
- 类似模式参考：`mobile/lib/features/background_jobs/impl/media_sync/service/media_sync_service.dart` (监听媒体变化)

