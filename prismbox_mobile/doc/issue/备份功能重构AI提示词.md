# 备份功能重构 - AI提示词模板

> **使用说明**：这是一个AI提示词模板，可以直接复制粘贴给AI使用。每个阶段都有独立的提示词，可以分阶段执行。

---

## 通用提示词模板

```
你是一位经验丰富的Flutter/Dart开发工程师，擅长代码重构和架构设计。

**项目背景**：
- 项目路径：`prismbox_mobile/lib/services/backup/`
- 当前问题：代码重复严重（70+行），状态管理混乱，职责边界不清
- 重构方式：渐进式重构，分5个阶段执行
- 参考文档：`备份功能重构评估与方案.md`

**你的任务**：
根据当前阶段的要求，完成代码重构工作。

**约束条件**：
1. 必须遵循单一职责原则（SRP）
2. 所有公共API必须有文档注释
3. 保持现有功能兼容性
4. 每个步骤完成后必须通过测试
5. 使用依赖注入，避免直接依赖

**输出格式**：
1. 先分析当前代码结构
2. 提供重构方案
3. 实现代码（包含完整代码，不要省略）
4. 提供测试用例
5. 验证验收标准

现在开始执行[阶段X]的重构任务。
```

---

## 阶段1提示词：提取公共逻辑

```
你是一位经验丰富的Flutter/Dart开发工程师。

**任务**：提取备份功能中的公共逻辑，消除代码重复。

**当前问题**：
- `backup_service.dart` 中手动备份（150-223行）和自动备份（350-436行）的任务创建逻辑几乎完全重复
- 约70行代码重复，包括文件路径获取、文件存在性检查、文件大小获取、任务实体创建

**你的任务**：

1. **创建 `TaskFactory` 类**
   - 文件路径：`lib/services/backup/task_factory.dart`
   - 职责：统一任务创建逻辑，参数化任务类型、优先级等差异
   - 必须包含方法：
     ```dart
     Future<UploadTaskEntityData?> createTask({
       required LocalAsset asset,
       required String userId,
       required String remotePath,
       required UploadTaskType taskType,
       required int priority,
     });
     
     Future<List<UploadTaskEntityData>> createTasks({
       required List<LocalAsset> assets,
       required String userId,
       required String remotePath,
       required UploadTaskType taskType,
       required int priority,
     });
     ```

2. **创建 `AssetPathResolver` 类**
   - 文件路径：`lib/services/backup/asset_path_resolver.dart`
   - 职责：提取文件路径获取逻辑，统一处理文件不存在的情况
   - 必须包含方法：
     ```dart
     Future<String?> resolveAssetPath(LocalAsset asset);
     Future<bool> validateFileExists(String path);
     ```
   - 实现逻辑：
     - 首先检查 `asset.path` 是否存在
     - 如果不存在，通过 `photo_manager` 的 `AssetEntity.fromId` 重新获取
     - 使用 `originFile` 获取原始文件路径

3. **创建 `FileMetadataExtractor` 类**
   - 文件路径：`lib/services/backup/file_metadata_extractor.dart`
   - 职责：提取文件大小获取逻辑
   - 必须包含方法：
     ```dart
     Future<int> extractFileSize(String filePath);
     ```

4. **重构 `BackupService`**
   - 修改文件：`lib/services/backup/backup_service.dart`
   - 注入 `TaskFactory` 依赖
   - 手动备份方法（`backupAssets`）使用 `TaskFactory.createTasks`
   - 自动备份方法（`_createAutoBackupTasks`）使用 `TaskFactory.createTasks`
   - 删除150-223行和350-436行的重复代码

**验收标准**：
- ✅ 手动备份和自动备份使用相同的创建逻辑
- ✅ 代码重复度降低80%以上
- ✅ 现有功能测试通过

**输出要求**：
1. 先读取并分析 `backup_service.dart` 的150-223行和350-436行
2. 提供完整的三个新类的实现代码
3. 提供修改后的 `BackupService` 代码（只显示修改的部分）
4. 提供单元测试代码

现在开始执行。
```

---

## 阶段2提示词：重构状态管理

```
你是一位经验丰富的Flutter/Dart开发工程师。

**任务**：建立统一的状态管理机制，解决状态流转问题。

**当前问题**：
1. 发起备份后，资源状态没有立即变成上传中（任务创建时状态为 `pending`）
2. 状态流转混乱，`assetUploadStatusProvider` 中 `pending` 被错误地当作 `uploading` 处理（第57行）
3. 上传失败后，状态可能没有更新

**你的任务**：

1. **创建 `UploadTaskStateMachine` 类**
   - 文件路径：`lib/services/backup/upload_task_state_machine.dart`
   - 职责：统一状态流转管理，所有状态变更必须通过状态机
   - 状态定义（需要新增 `queued` 状态）：
     ```dart
     enum UploadTaskStatus {
       pending,        // 待处理（刚创建）
       queued,         // 已入队（等待执行）NEW
       uploading,      // 上传中
       paused,         // 已暂停
       completed,      // 已完成
       failed,         // 失败（可重试）
       permanentlyFailed, // 永久失败
       cancelled,      // 已取消
     }
     ```
   - 状态转换规则：
     ```
     pending → queued → uploading → completed
       ↓         ↓         ↓            ↑
       ↓      failed ──────┘            │
       ↓         ↓                      │
     cancelled   permanentlyFailed ─────┘
     ```
   - 必须包含方法：
     ```dart
     bool canTransition(UploadTaskStatus from, UploadTaskStatus to);
     Future<UploadTaskEntityData> transition(
       UploadTaskEntityData task,
       UploadTaskStatus newStatus, {
       String? errorMessage,
     });
     List<UploadTaskStatus> getAllowedTransitions(UploadTaskStatus current);
     ```
   - 实现要点：
     - 定义状态转换矩阵（Map<UploadTaskStatus, Set<UploadTaskStatus>>）
     - 状态转换时更新数据库
     - 状态转换时触发事件通知（可选）

2. **修复 `assetUploadStatusProvider`**
   - 修改文件：`lib/services/backup/providers/asset_upload_status_provider.dart`
   - 修复第57行的bug：`pending` 不应该被当作 `uploading` 处理
   - 明确区分 `pending`、`queued`、`uploading` 状态
   - 修改后的逻辑：
     ```dart
     case UploadTaskStatus.uploading:
       return AssetUploadStatusInfo(
         status: AssetUploadStatus.uploading,
         progress: progress.clamp(0.0, 1.0),
       );
     case UploadTaskStatus.queued:
     case UploadTaskStatus.pending:
       // pending/queued 状态显示为上传中（但进度为0）
       return const AssetUploadStatusInfo(
         status: AssetUploadStatus.uploading,
         progress: 0.0,
       );
     ```

3. **实现乐观更新机制**
   - 修改文件：`lib/services/backup/backup_service.dart`
   - 任务创建后立即通过状态机更新为 `queued` 状态（而不是保持 `pending`）
   - 使用 `UploadTaskStateMachine.transition` 进行状态转换

**验收标准**：
- ✅ 所有状态转换通过状态机验证
- ✅ UI状态与数据库状态保持一致
- ✅ 发起备份后状态立即更新为 `queued`
- ✅ 状态流转严格，不会出现混乱

**输出要求**：
1. 先读取并分析相关代码文件
2. 提供完整的 `UploadTaskStateMachine` 实现代码
3. 提供修改后的 `assetUploadStatusProvider` 代码
4. 提供修改后的 `BackupService` 代码（只显示修改的部分）
5. 提供状态转换的单元测试代码

现在开始执行。
```

---

## 阶段3提示词：职责重新划分

```
你是一位经验丰富的Flutter/Dart开发工程师。

**任务**：明确各Service的职责边界，建立清晰的分层架构。

**当前问题**：
- 20+个类，职责划分不清晰
- `BackupService`、`UploadService`、`UploadOrchestrator` 职责边界模糊

**你的任务**：

1. **审查并重构各Service的职责**
   - `BackupService`：只负责业务编排，触发备份流程
     - ❌ 不应该直接创建任务实体（应该使用 `TaskFactory`）
     - ❌ 不应该直接更新任务状态（应该使用 `UploadTaskStateMachine`）
     - ❌ 不应该直接操作数据库
   
   - `UploadService`：只负责队列管理，任务的CRUD和调度
     - ❌ 不应该直接执行上传逻辑（应该由 `UploadOrchestrator` 执行）
     - ❌ 不应该直接更新任务状态（应该使用 `UploadTaskStateMachine`）
   
   - `UploadOrchestrator`：只负责流程编排，执行上传流程
     - ❌ 不应该直接操作数据库（应该通过DAO）
     - ❌ 不应该直接管理任务队列（应该使用 `UploadService`）
   
   - `UploadTaskManager`：只负责任务执行，与 `background_downloader` 交互
     - ❌ 不应该管理任务状态（状态更新通过 `UploadTaskStateMachine`）

2. **检查并修复职责重叠**
   - 审查每个Service的当前实现
   - 识别职责重叠的部分
   - 重构代码，确保职责单一

3. **建立清晰的依赖关系**
   - 使用依赖注入
   - 明确模块间的依赖方向：
     ```
     BackupService → UploadService → UploadOrchestrator
                                         ↓
                               UploadTaskStateMachine
                                         ↓
                               UploadTaskManager
     ```
   - 避免循环依赖

**验收标准**：
- ✅ 每个类的职责单一且明确
- ✅ 依赖关系清晰，无循环依赖
- ✅ 所有测试通过

**输出要求**：
1. 先分析当前各Service的实现，识别职责重叠
2. 提供重构方案
3. 提供修改后的代码（只显示修改的部分）
4. 说明每个类的职责边界

现在开始执行。
```

---

## 阶段4提示词：优化错误处理

```
你是一位经验丰富的Flutter/Dart开发工程师。

**任务**：统一错误处理策略，提高系统可靠性。

**当前问题**：
- 上传失败后，状态可能没有更新
- 某些异常路径可能未被正确捕获
- 缺少超时机制

**你的任务**：

1. **扩展 `ErrorHandler` 类**
   - 文件路径：`lib/services/backup/error_handler.dart`（可能已存在）
   - 定义统一的错误类型：
     ```dart
     enum UploadErrorType {
       networkError,        // 网络错误（可重试）
       fileNotFound,        // 文件不存在（永久失败）
       permissionDenied,    // 权限拒绝（永久失败）
       serverError,         // 服务器错误（可重试）
       timeout,            // 超时（可重试）
       unknown,            // 未知错误（可重试）
     }
     ```
   - 必须包含方法：
     ```dart
     Future<bool> handleUploadError(UploadError error, UploadTaskEntityData task);
     bool isRetryable(UploadError error);
     bool isPermanentFailure(UploadError error);
     static UploadError parseError(Object error);
     ```

2. **创建 `TaskStatusRepairService` 类**
   - 文件路径：`lib/services/backup/task_status_repair_service.dart`
   - 职责：定期检查长时间 `uploading` 的任务，超时自动标记为失败
   - 必须包含方法：
     ```dart
     Future<void> repairAbnormalTasks({Duration? maxUploadingDuration});
     Future<void> repairTask(String taskId);
     void startPeriodicCheck({Duration interval = const Duration(minutes: 5)});
     ```
   - 实现要点：
     - 查询所有状态为 `uploading` 且超过最大时长（默认30分钟）的任务
     - 检查任务是否真的在上传（通过 `background_downloader` 的状态）
     - 如果任务已停止，通过 `UploadTaskStateMachine` 标记为失败

3. **完善异常捕获**
   - 修改文件：
     - `lib/services/backup/upload_orchestrator.dart`
     - `lib/services/backup/upload_task_manager.dart`
   - 确保所有异常路径都被正确处理
   - 使用统一的 `ErrorHandler` 处理错误
   - 确保状态更新不会因为异常而失败
   - 修改模式：
     ```dart
     try {
       await uploadTask();
     } catch (e) {
       final error = ErrorHandler.parseError(e);
       await _errorHandler.handleUploadError(error, task);
       await _stateMachine.transition(
         task,
         error.isRetryable ? UploadTaskStatus.failed : UploadTaskStatus.permanentlyFailed,
         errorMessage: error.message,
       );
     }
     ```

**验收标准**：
- ✅ 所有异常路径都有处理逻辑
- ✅ 状态修复机制验证通过
- ✅ 上传失败后状态正确更新
- ✅ 超时任务能够自动修复

**输出要求**：
1. 先分析当前错误处理逻辑
2. 提供完整的 `ErrorHandler` 和 `TaskStatusRepairService` 实现代码
3. 提供修改后的异常捕获代码（只显示修改的部分）
4. 提供测试用例

现在开始执行。
```

---

## 阶段5提示词：UI优化

```
你是一位经验丰富的Flutter/Dart开发工程师。

**任务**：修复UI显示问题，优化上传中图标显示。

**当前问题**：
- 上传中时，整个云图标都在转动
- 用户期望的是围绕云图标外面有转圈的效果，而不是图标本身旋转

**你的任务**：

1. **修改上传中图标显示**
   - 修改文件：`lib/presentation/widgets/media/selectable_media_item.dart`
   - 修改 `_buildUploadingIcon` 方法（第248-249行）
   - 使用 `Stack` 组合静态云图标和外围 `CircularProgressIndicator`
   - 修改示例：
     ```dart
     // 修改前（第314行）
     _RotatingCloudIcon(
       child: Icon(Icons.cloud, size: 16),
     )
     
     // 修改后
     Stack(
       alignment: Alignment.center,
       children: [
         // 静态云图标
         Icon(Icons.cloud, size: 16),
         // 外围旋转圆环
         SizedBox(
           width: 20,
           height: 20,
           child: CircularProgressIndicator(
             strokeWidth: 2,
             valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
           ),
         ),
       ],
     )
     ```

2. **优化状态图标显示逻辑**
   - 明确各状态对应的图标：
     - `notUploaded`：无图标或灰色云图标
     - `uploading`：云图标 + 外围旋转圆环（进度指示）
     - `uploaded`：蓝色云图标（带勾）
     - `failed`：红色云图标（带感叹号）
   - 添加状态过渡动画（可选）

**验收标准**：
- ✅ 上传中图标显示正确（图标不旋转，外围有转圈效果）
- ✅ UI显示符合设计规范
- ✅ 状态过渡动画流畅（如果有）

**输出要求**：
1. 先读取并分析 `selectable_media_item.dart` 的相关代码
2. 提供修改后的完整代码（只显示修改的部分）
3. 说明修改的逻辑

现在开始执行。
```

---

## 快速检查清单

在执行每个阶段前，请确认：

- [ ] 已阅读并理解当前阶段的任务
- [ ] 已查看相关代码文件，理解现有实现
- [ ] 已确认依赖关系
- [ ] 已准备好测试环境

执行完成后，请验证：

- [ ] 所有验收标准通过
- [ ] 所有测试通过
- [ ] 代码审查通过
- [ ] 现有功能正常

---

## 参考资源

### 相关文档
- `备份功能重构评估与方案.md` - 完整的重构方案和背景信息
- `docs/自动备份.md` - 自动备份功能实施计划
- `docs/后台上传方案.md` - 后台上传架构方案

### 相关代码
- `lib/services/backup/` - 备份服务代码目录
- `lib/presentation/widgets/media/selectable_media_item.dart` - UI组件
- `lib/services/backup/providers/` - 状态管理Provider

### 关键文件位置
- `backup_service.dart:150-223` - 手动备份任务创建逻辑（需要重构）
- `backup_service.dart:350-436` - 自动备份任务创建逻辑（需要重构）
- `asset_upload_status_provider.dart:57` - 状态判断bug（需要修复）
- `selectable_media_item.dart:248-249` - 上传图标显示（需要优化）

---

**文档结束**
