// lib/services/backup/upload_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/services/backup/backup_query_builder.dart';
import 'package:prismbox/services/backup/task_conflict_resolver.dart';
import 'package:prismbox/services/backup/upload_orchestrator.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';
import 'package:prismbox/services/backup/task_update_service.dart';
import 'package:prismbox/utils/cancellation_token.dart';

/// 上传队列状态
class UploadQueueStatus {
  final int totalCount;
  final int pendingCount;
  final int uploadingCount;
  final int completedCount;
  final int failedCount;
  final int permanentlyFailedCount;
  final int cancelledCount;

  UploadQueueStatus({
    required this.totalCount,
    required this.pendingCount,
    required this.uploadingCount,
    required this.completedCount,
    required this.failedCount,
    required this.permanentlyFailedCount,
    required this.cancelledCount,
  });

  factory UploadQueueStatus.empty() {
    return UploadQueueStatus(
      totalCount: 0,
      pendingCount: 0,
      uploadingCount: 0,
      completedCount: 0,
      failedCount: 0,
      permanentlyFailedCount: 0,
      cancelledCount: 0,
    );
  }
}

/// 上传任务详情
class UploadTaskDetail {
  final String taskId;
  final String assetId;
  final String filename;
  final double progress;  // 0.0 - 1.0
  final int fileSize;
  final String? networkSpeed;  // 如 "1.2 MB/s"
  final UploadTaskStatus status;
  final String? errorMessage;
  
  UploadTaskDetail({
    required this.taskId,
    required this.assetId,
    required this.filename,
    required this.progress,
    required this.fileSize,
    this.networkSpeed,
    required this.status,
    this.errorMessage,
  });
}

/// 上传服务：队列管理层
/// 
/// **职责边界明确**：
/// - ✅ **负责**：上传队列管理（任务 CRUD、状态管理、队列调度）
/// - ✅ **负责**：队列状态查询和统计
/// - ✅ **负责**：任务信息更新（路径、重试计数等）
/// - ❌ **不负责**：候选资源筛选（由 BackupCandidateSelector 负责）
/// - ❌ **不负责**：上传流程编排（由 UploadOrchestrator 负责）
/// - ❌ **不负责**：备份业务编排（由 BackupService 负责）
class UploadService implements TaskUpdateService {
  final AppDatabase _database;
  final UploadOrchestrator _orchestrator;
  final TaskConflictResolver _conflictResolver;
  final UploadTaskStateMachine _stateMachine;
  final Logger _logger = Logger('UploadService');

  UploadService({
    required AppDatabase database,
    required UploadOrchestrator orchestrator,
    required TaskConflictResolver conflictResolver,
    required UploadTaskStateMachine stateMachine,
  })  : _database = database,
        _orchestrator = orchestrator,
        _conflictResolver = conflictResolver,
        _stateMachine = stateMachine;

  /// 添加上传任务（自动进行冲突检测）
  /// 
  /// **参数**：
  /// - [task] - 上传任务
  /// 
  /// **职责**：
  /// 1. 冲突检测
  /// 2. 解决冲突
  /// 3. 创建任务（如果通过冲突检测）
  Future<void> addTask(UploadTaskEntityData task) async {
    _logger.info('Adding upload task: taskId=${task.id}, assetId=${task.assetId}');

    // 1. 冲突检测
    final resolution = await _conflictResolver.checkConflict(
      userId: task.userId,
      newTask: task,
    );

    // 2. 获取已存在的任务（用于替换或更新路径）
    UploadTaskEntityData? existingTask;
    if (resolution == ConflictResolution.replace || 
        resolution == ConflictResolution.skip) {
      final dao = _database.uploadTaskDao;
      final allTasks = await dao.getTasksByAssetIdAndUserId(
        task.userId,
        task.assetId,
      );
      
      // 过滤状态为 pending 或 uploading 的任务
      final existingTasks = allTasks.where((task) =>
          task.status == UploadTaskStatus.pending ||
          task.status == UploadTaskStatus.uploading).toList();
      existingTask = existingTasks.isNotEmpty ? existingTasks.first : null;
    }

    // 3. 解决冲突
    await _conflictResolver.resolveConflict(
      resolution: resolution,
      newTask: task,
      existingTask: existingTask,
    );
  }

  /// 批量添加上传任务
  /// 
  /// **参数**：
  /// - [tasks] - 上传任务列表
  Future<void> addTasks(List<UploadTaskEntityData> tasks) async {
    _logger.info('Adding ${tasks.length} upload tasks');

    for (final task in tasks) {
      await addTask(task);
    }
  }

  /// 乐观更新：将任务状态从 pending 更新为 queued
  ///
  /// **参数**：
  /// - [tasks] - 任务列表（可能包含未插入的任务）
  ///
  /// **职责**：
  /// - 从数据库获取实际插入的任务
  /// - 使用状态机将状态更新为 queued
  /// - 提供即时反馈，解决状态更新延迟问题
  ///
  /// **注意**：这是队列管理的职责，应该由 UploadService 负责
  Future<void> optimisticallyUpdateTasksToQueued(
    List<UploadTaskEntityData> tasks,
  ) async {
    if (tasks.isEmpty) {
      return;
    }

    final dao = _database.uploadTaskDao;
    final tasksToUpdate = <UploadTaskEntityData>[];

    // 从数据库获取实际插入的任务（过滤掉被冲突检测跳过的任务）
    for (final task in tasks) {
      final dbTask = await dao.getTaskById(task.id);
      if (dbTask != null && dbTask.status == UploadTaskStatus.pending) {
        tasksToUpdate.add(dbTask);
      }
    }

    if (tasksToUpdate.isEmpty) {
      _logger.fine('No tasks to update to queued status');
      return;
    }

    _logger.info(
      'Optimistically updating ${tasksToUpdate.length} tasks to queued status',
    );

    // 批量更新状态为 queued
    try {
      await _stateMachine.transitionBatch(
        tasksToUpdate,
        UploadTaskStatus.queued,
      );
      _logger.info(
        'Successfully updated ${tasksToUpdate.length} tasks to queued status',
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to optimistically update tasks to queued: $e',
        e,
        stackTrace,
      );
      // 不抛出异常，避免影响主流程
    }
  }

  /// 开始上传
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [cancellationToken] - 取消令牌
  /// - [onProgress] - 进度回调（可选）
  /// 
  /// **返回**：UploadResult（上传结果）
  /// 
  /// **执行流程**：
  /// 1. 获取待上传任务（按优先级排序）
  /// 2. 过滤已上传资产（去重）
  /// 3. 调用 UploadOrchestrator 执行上传编排
  Future<UploadResult> startUpload({
    required String userId,
    required CancellationToken cancellationToken,
    void Function(int current, int total)? onProgress,
  }) async {
    _logger.info('Starting upload for userId=$userId');

    // 1. 获取待上传任务（按优先级排序）
    final dao = _database.uploadTaskDao;
    final pendingTasks = await dao.getPendingTasksByUserId(userId);

    if (pendingTasks.isEmpty) {
      _logger.info('No pending tasks for userId=$userId');
      return UploadResult(successCount: 0, failedCount: 0, errors: []);
    }

    _logger.info('Found ${pendingTasks.length} pending tasks');

    // 2. 过滤已上传资产（去重）
    // 注意：这里需要确定任务类型，以便决定是否跳过去重
    // 暂时假设都是自动备份（需要后续从任务中获取）
    final filteredTasks = await _orchestrator.filterUploadedAssets(
      userId: userId,
      candidates: pendingTasks,
      skipDeduplication: false, // 自动备份默认不去重
    );

    if (filteredTasks.isEmpty) {
      _logger.info('All tasks are duplicates, skipping upload');
      return UploadResult(successCount: 0, failedCount: 0, errors: []);
    }

    _logger.info('Filtered to ${filteredTasks.length} tasks after deduplication');

    // 3. 调用 UploadOrchestrator 执行上传编排
    // 注意：需要从任务中获取 taskType，这里暂时使用第一个任务的类型
    final taskType = filteredTasks.isNotEmpty
        ? filteredTasks.first.taskType
        : UploadTaskType.auto;

    return await _orchestrator.orchestrateUpload(
      userId: userId,
      tasks: filteredTasks,
      cancellationToken: cancellationToken,
      taskType: taskType,
      onProgress: onProgress,
    );
  }

  /// 暂停上传
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **职责**：
  /// - 将所有 uploading 状态的任务改为 paused
  Future<void> pauseUpload(String userId) async {
    _logger.info('Pausing upload for userId=$userId');

    final dao = _database.uploadTaskDao;
    final uploadingTasks = await dao.getUploadingTasksByUserId(userId);

    // 通过状态机批量更新状态
    await _stateMachine.transitionBatch(
      uploadingTasks,
      UploadTaskStatus.paused,
    );

    _logger.info('Paused ${uploadingTasks.length} tasks');
  }

  /// 恢复上传
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **职责**：
  /// - 将所有 paused 状态的任务改为 pending
  Future<void> resumeUpload(String userId) async {
    _logger.info('Resuming upload for userId=$userId');

    final pausedTasks = await BackupQueryBuilder(_database)
        .withUserId(userId)
        .buildTaskQuery(status: UploadTaskStatus.paused)
        .get();

    // 通过状态机批量更新状态（paused -> queued，因为恢复后应该重新入队）
    // 注意：根据状态转换规则，paused 不能直接转换为 pending，应该转换为 queued
    await _stateMachine.transitionBatch(
      pausedTasks,
      UploadTaskStatus.queued,
    );

    _logger.info('Resumed ${pausedTasks.length} tasks');
  }

  /// 取消上传
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **职责**：
  /// - 将所有 pending 和 uploading 状态的任务改为 cancelled
  Future<void> cancelUpload(String userId) async {
    _logger.info('Cancelling upload for userId=$userId');

    final dao = _database.uploadTaskDao;
    
    // 获取 pending 和 uploading 状态的任务
    final pendingTasks = await dao.getPendingTasksByUserId(userId);
    final uploadingTasks = await dao.getUploadingTasksByUserId(userId);

    final allTasks = [...pendingTasks, ...uploadingTasks];

    // 通过状态机批量更新状态
    await _stateMachine.transitionBatch(
      allTasks,
      UploadTaskStatus.cancelled,
      errorMessage: 'Cancelled by user',
    );

    _logger.info('Cancelled ${allTasks.length} tasks');
  }

  /// 获取上传队列状态
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **返回**：Future<UploadQueueStatus>（队列状态）
  /// 
  /// **注意**：此方法需要异步查询数据库，因此返回 Future
  Future<UploadQueueStatus> getQueueStatus(String userId) async {
    final dao = _database.uploadTaskDao;
    final statusCounts = await dao.getQueueStatusByUserId(userId);

    return UploadQueueStatus(
      totalCount: statusCounts.values.fold(0, (sum, count) => sum + count),
      pendingCount: statusCounts[UploadTaskStatus.pending] ?? 0,
      uploadingCount: statusCounts[UploadTaskStatus.uploading] ?? 0,
      completedCount: statusCounts[UploadTaskStatus.completed] ?? 0,
      failedCount: statusCounts[UploadTaskStatus.failed] ?? 0,
      permanentlyFailedCount:
          statusCounts[UploadTaskStatus.permanentlyFailed] ?? 0,
      cancelledCount: statusCounts[UploadTaskStatus.cancelled] ?? 0,
    );
  }

  /// 获取任务详情
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [taskId] - 任务 ID
  /// 
  /// **返回**：UploadTaskEntityData?（任务详情，如果不存在返回 null）
  Future<UploadTaskEntityData?> getTask({
    required String userId,
    required String taskId,
  }) async {
    final dao = _database.uploadTaskDao;
    final task = await dao.getTaskById(taskId);

    // 验证任务属于该用户
    if (task != null && task.userId != userId) {
      _logger.warning(
        'Task $taskId does not belong to user $userId',
      );
      return null;
    }

    return task;
  }

  /// 删除任务
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [taskId] - 任务 ID
  /// 
  /// **职责**：
  /// - 删除指定任务（仅限该用户的任务）
  Future<void> removeTask({
    required String userId,
    required String taskId,
  }) async {
    final task = await getTask(userId: userId, taskId: taskId);
    if (task == null) {
      _logger.warning('Task $taskId not found or does not belong to user $userId');
      return;
    }

    final dao = _database.uploadTaskDao;
    await dao.deleteTask(taskId);

    _logger.info('Deleted task: taskId=$taskId');
  }

  /// 手动重试失败任务
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [taskId] - 任务 ID
  /// 
  /// **职责**：
  /// - 将失败任务的状态改为 pending，以便重新上传
  Future<void> retryTask({
    required String userId,
    required String taskId,
  }) async {
    final task = await getTask(userId: userId, taskId: taskId);
    if (task == null) {
      _logger.warning('Task $taskId not found or does not belong to user $userId');
      return;
    }

    // 只能重试 failed 或 permanentlyFailed 状态的任务
    if (task.status != UploadTaskStatus.failed &&
        task.status != UploadTaskStatus.permanentlyFailed) {
      _logger.warning(
        'Cannot retry task $taskId with status ${task.status}',
      );
      return;
    }

    // 通过状态机更新状态（failed/permanentlyFailed -> uploading，重试时直接开始上传）
    await _stateMachine.transition(
      task,
      UploadTaskStatus.uploading,
      errorMessage: null, // 清除错误信息
    );

    _logger.info('Retried task: taskId=$taskId');
  }

  /// 获取当前正在上传的任务列表
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// 
  /// **返回**：List<UploadTaskDetail>（上传任务详情列表）
  /// 
  /// **注意**：包含 uploading 和 pending 状态的任务
  Future<List<UploadTaskDetail>> getActiveUploadTasks(String userId) async {
    final dao = _database.uploadTaskDao;
    
    // 1. 查询状态为 uploading 和 pending 的任务
    final uploadingTasks = await dao.getTasksByUserIdAndStatus(
      userId,
      UploadTaskStatus.uploading,
    );
    final pendingTasks = await dao.getTasksByUserIdAndStatus(
      userId,
      UploadTaskStatus.pending,
    );
    
    // 合并任务列表，优先显示 uploading 的任务
    final tasks = [...uploadingTasks, ...pendingTasks];
    
    // 2. 转换为 UploadTaskDetail
    final details = <UploadTaskDetail>[];
    for (final task in tasks) {
      // 获取资产信息
      final asset = await _database.localAssetDao.getAssetById(task.assetId);
      if (asset == null) continue;
      
      // 获取文件名
      final filename = asset.path.split('/').last;
      
      // 计算进度（0.0 - 1.0）
      final progress = task.progress / 100.0;
      
      // 获取上传速度（暂时返回 null，后续可以从 background_downloader 获取）
      final networkSpeed = _calculateNetworkSpeed(task);
      
      details.add(UploadTaskDetail(
        taskId: task.id,
        assetId: task.assetId,
        filename: filename,
        progress: progress,
        fileSize: task.fileSize,
        networkSpeed: networkSpeed,
        status: task.status,
        errorMessage: task.errorMessage,
      ));
    }
    
    return details;
  }

  /// 计算网络速度（简化实现）
  /// 基于进度变化和时间差估算上传速度
  /// 后续可以从 background_downloader 获取实际速度
  String? _calculateNetworkSpeed(UploadTaskEntityData task) {
    // 如果任务没有文件大小或进度为0，无法计算速度
    if (task.fileSize <= 0 || task.progress <= 0) {
      return null;
    }

    // 如果任务刚创建，还没有足够的时间差来计算速度
    final now = DateTime.now();
    final timeDiff = now.difference(task.updatedAt).inSeconds;
    if (timeDiff <= 0) {
      return null;
    }

    // 计算已上传的字节数
    final uploadedBytes = (task.fileSize * task.progress / 100).round();
    
    // 计算速度（字节/秒）
    final speedBytesPerSecond = uploadedBytes / timeDiff;

    // 格式化速度显示
    if (speedBytesPerSecond < 1024) {
      return '${speedBytesPerSecond.toStringAsFixed(0)} B/s';
    } else if (speedBytesPerSecond < 1024 * 1024) {
      return '${(speedBytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(speedBytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  /// 更新任务本地路径（实现 TaskUpdateService 接口）
  ///
  /// **参数**：
  /// - [taskId] - 任务 ID
  /// - [localPath] - 新的本地路径
  ///
  /// **职责**：
  /// - 更新任务中的文件路径（当文件路径改变时）
  ///
  /// **注意**：这是队列管理的职责，应该由 UploadService 负责
  @override
  Future<void> updateTaskLocalPath({
    required String taskId,
    required String localPath,
  }) async {
    _logger.info('Updating task local path: taskId=$taskId, localPath=$localPath');

    final dao = _database.uploadTaskDao;
    await dao.updateTaskLocalPath(taskId, localPath);

    _logger.info('Task local path updated: taskId=$taskId');
  }

  /// 增加任务重试计数（实现 TaskUpdateService 接口）
  ///
  /// **参数**：
  /// - [taskId] - 任务 ID
  ///
  /// **职责**：
  /// - 增加任务的重试计数（当上传失败需要重试时）
  ///
  /// **注意**：这是队列管理的职责，应该由 UploadService 负责
  @override
  Future<void> incrementRetryCount(String taskId) async {
    _logger.fine('Incrementing retry count: taskId=$taskId');

    final dao = _database.uploadTaskDao;
    await dao.incrementRetryCount(taskId);

    _logger.fine('Retry count incremented: taskId=$taskId');
  }
}

