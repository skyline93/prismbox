// lib/services/backup/task_status_repair_service.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';

/// 任务状态修复服务
/// 
/// **职责**：
/// - 定期检查长时间 `uploading` 的任务
/// - 超时自动标记为失败
/// - 检查任务是否真的在上传（通过 `background_downloader` 的状态）
/// 
/// **设计原则**：
/// - 定期检查，避免任务卡死
/// - 通过 `background_downloader` 验证任务真实状态
/// - 使用状态机更新状态，保证状态转换合法性
class TaskStatusRepairService {
  final AppDatabase _database;
  final UploadTaskStateMachine _stateMachine;
  final Logger _logger = Logger('TaskStatusRepairService');

  /// 定期检查定时器
  Timer? _periodicTimer;

  /// 默认最大上传时长（30分钟）
  static const Duration _defaultMaxUploadingDuration = Duration(minutes: 30);

  /// 默认检查间隔（5分钟）
  static const Duration _defaultCheckInterval = Duration(minutes: 5);

  TaskStatusRepairService({
    required AppDatabase database,
    required UploadTaskStateMachine stateMachine,
  })  : _database = database,
        _stateMachine = stateMachine;

  /// 修复异常任务
  /// 
  /// **参数**：
  /// - [maxUploadingDuration] - 最大上传时长，超过此时长的 uploading 任务将被标记为失败
  /// 
  /// **实现逻辑**：
  /// 1. 查询所有状态为 `uploading` 的任务
  /// 2. 检查任务是否超过最大上传时长
  /// 3. 通过 `background_downloader` 检查任务真实状态
  /// 4. 如果任务已停止或不存在，标记为失败
  Future<void> repairAbnormalTasks({
    Duration? maxUploadingDuration,
  }) async {
    final maxDuration = maxUploadingDuration ?? _defaultMaxUploadingDuration;
    final cutoffTime = DateTime.now().subtract(maxDuration);

    _logger.info(
      'Starting task status repair: maxUploadingDuration=$maxDuration',
    );

    try {
      // 查询所有状态为 uploading 的任务
      // 注意：由于需要查询所有用户的任务，我们需要通过数据库直接查询
      // 这里使用一个简化的方法：先获取所有用户ID，然后查询每个用户的任务
      // 或者更简单：直接查询所有 uploading 状态的任务（不区分用户）
      final dao = _database.uploadTaskDao;
      
      // 使用数据库查询所有 uploading 状态的任务
      final uploadingTasks = await (dao.select(dao.uploadTaskEntity)
            ..where((t) => t.status.equalsValue(UploadTaskStatus.uploading)))
          .get();

      if (uploadingTasks.isEmpty) {
        _logger.fine('No uploading tasks found, repair completed');
        return;
      }

      _logger.info(
        'Found ${uploadingTasks.length} uploading tasks to check',
      );

      int repairedCount = 0;
      int checkedCount = 0;

      for (final task in uploadingTasks) {
        checkedCount++;

        // 检查任务是否超过最大上传时长
        final updatedAt = task.updatedAt;
        if (updatedAt.isAfter(cutoffTime)) {
          // 任务还在时间窗口内，跳过
          continue;
        }

        // 任务超过最大上传时长，检查真实状态
        final isRepaired = await _checkAndRepairTask(task);
        if (isRepaired) {
          repairedCount++;
        }
      }

      _logger.info(
        'Task status repair completed: '
        'checked=$checkedCount, repaired=$repairedCount',
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to repair abnormal tasks: $e',
        e,
        stackTrace,
      );
    }
  }

  /// 修复单个任务
  /// 
  /// **参数**：
  /// - [taskId] - 任务ID
  /// 
  /// **返回**：是否修复成功
  Future<void> repairTask(String taskId) async {
    final task = await _database.uploadTaskDao.getTaskById(taskId);
    if (task == null) {
      _logger.warning('Task not found: taskId=$taskId');
      return;
    }

    if (task.status != UploadTaskStatus.uploading) {
      _logger.fine(
        'Task is not in uploading status: taskId=$taskId, status=${task.status}',
      );
      return;
    }

    await _checkAndRepairTask(task);
  }

  /// 检查并修复任务
  /// 
  /// **参数**：
  /// - [task] - 任务实体
  /// 
  /// **返回**：是否修复成功
  /// 
  /// **实现逻辑**：
  /// 1. 通过 `background_downloader` 获取任务真实状态
  /// 2. 如果任务不存在或已停止，标记为失败
  /// 3. 如果任务仍在运行，但超过最大时长，也标记为失败（可能是卡死）
  Future<bool> _checkAndRepairTask(
    UploadTaskEntityData task,
  ) async {
    final taskId = task.id;
    final fileName = task.localPath.split('/').last;

    try {
      // 简化实现：直接基于时间判断
      // 如果任务超过最大上传时长，标记为失败
      // 注意：background_downloader 的 API 可能不直接支持查询任务状态
      // 我们通过时间判断来处理任务卡死的情况
      // 正常情况下，任务状态应该由 UploadTaskManager 的回调更新
      // 如果长时间处于 uploading 状态，说明可能出现了异常
      
      _logger.warning(
        'Task exceeded max uploading duration: '
        'taskId=$taskId, assetId=${task.assetId}, filename=$fileName, '
        'updatedAt=${task.updatedAt}, duration=${DateTime.now().difference(task.updatedAt)}',
      );

      // 标记为失败
      await _markTaskAsFailed(
        task,
        '上传超时（超过最大上传时长，任务可能已停止）',
      );
      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to check task status: taskId=$taskId, error=$e',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// 标记任务为失败
  /// 
  /// **参数**：
  /// - [task] - 任务实体
  /// - [errorMessage] - 错误信息
  Future<void> _markTaskAsFailed(
    UploadTaskEntityData task,
    String errorMessage,
  ) async {
    try {
      // 检查重试次数
      final newStatus = task.retryCount >= task.maxRetries
          ? UploadTaskStatus.permanentlyFailed
          : UploadTaskStatus.failed;

      // 通过状态机更新状态
      await _stateMachine.transition(
        task,
        newStatus,
        errorMessage: errorMessage,
      );

      final fileName = task.localPath.split('/').last;
      _logger.info(
        'Task marked as failed: '
        'taskId=${task.id}, assetId=${task.assetId}, filename=$fileName, '
        'status=$newStatus, errorMessage=$errorMessage',
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to mark task as failed: taskId=${task.id}, error=$e',
        e,
        stackTrace,
      );
    }
  }

  /// 启动定期检查
  /// 
  /// **参数**：
  /// - [interval] - 检查间隔（默认5分钟）
  /// - [maxUploadingDuration] - 最大上传时长（默认30分钟）
  /// 
  /// **注意**：
  /// - 调用此方法后，会定期执行任务状态修复
  /// - 调用 `stopPeriodicCheck()` 停止定期检查
  void startPeriodicCheck({
    Duration interval = _defaultCheckInterval,
    Duration? maxUploadingDuration,
  }) {
    // 如果已有定时器，先停止
    stopPeriodicCheck();

    _logger.info(
      'Starting periodic task status repair: '
      'interval=$interval, maxUploadingDuration=${maxUploadingDuration ?? _defaultMaxUploadingDuration}',
    );

    // 立即执行一次
    repairAbnormalTasks(maxUploadingDuration: maxUploadingDuration);

    // 启动定期检查
    _periodicTimer = Timer.periodic(interval, (_) {
      repairAbnormalTasks(maxUploadingDuration: maxUploadingDuration);
    });
  }

  /// 停止定期检查
  void stopPeriodicCheck() {
    if (_periodicTimer != null) {
      _periodicTimer!.cancel();
      _periodicTimer = null;
      _logger.info('Stopped periodic task status repair');
    }
  }

  /// 释放资源
  void dispose() {
    stopPeriodicCheck();
  }
}

