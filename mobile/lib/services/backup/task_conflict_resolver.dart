// lib/services/backup/task_conflict_resolver.dart

import 'dart:io';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';

/// 冲突解决策略
enum ConflictResolution {
  /// 跳过新任务（不创建）
  skip,

  /// 替换旧任务（取消旧任务，创建新任务）
  replace,
}

/// 任务冲突解决器
/// 
/// **设计目的**：检测和解决手动备份与自动备份的冲突。
/// 
/// **冲突规则**：
/// - 手动备份任务优先于自动备份任务
/// - 高优先级任务优先于低优先级任务
/// - 相同任务类型和优先级时，跳过新任务
class TaskConflictResolver {
  final AppDatabase _database;
  final UploadTaskStateMachine _stateMachine;
  final Logger _logger = Logger('TaskConflictResolver');

  TaskConflictResolver({
    required AppDatabase database,
    required UploadTaskStateMachine stateMachine,
  })  : _database = database,
        _stateMachine = stateMachine;

  /// 检查冲突
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [newTask] - 新任务
  /// 
  /// **返回**：ConflictResolution（解决策略）
  /// 
  /// **冲突检测逻辑**：
  /// 1. 查询已存在的任务（按 userId 和 assetId 过滤）
  /// 2. 检查任务状态（pending 或 uploading）
  /// 3. 根据优先级决定解决策略
  Future<ConflictResolution> checkConflict({
    required String userId,
    required UploadTaskEntityData newTask,
  }) async {
    // 查询已存在的任务（按 userId 和 assetId 过滤）
    // 使用 DAO 直接查询，避免 Selectable 类型问题
    final dao = _database.uploadTaskDao;
    final allTasks = await dao.getTasksByAssetIdAndUserId(
      userId,
      newTask.assetId,
    );
    
    // 过滤状态为 pending 或 uploading 的任务
    final existingTasks = allTasks.where((task) =>
        task.status == UploadTaskStatus.pending ||
        task.status == UploadTaskStatus.uploading).toList();

    if (existingTasks.isEmpty) {
      // 修复：没有冲突时应该返回 replace，这样会创建新任务
      return ConflictResolution.replace; // 无冲突，创建新任务
    }

    // 根据优先级决定解决策略
    final existingTask = existingTasks.first;

    // 手动任务替换自动任务
    if (newTask.taskType == UploadTaskType.manual &&
        existingTask.taskType == UploadTaskType.auto) {
      _logger.info(
        'Manual task conflicts with auto task, replacing: '
        'assetId=${newTask.assetId}, existingTaskId=${existingTask.id}',
      );
      return ConflictResolution.replace;
    }

    // 高优先级替换低优先级
    if (newTask.priority < existingTask.priority) {
      _logger.info(
        'High priority task conflicts with low priority task, replacing: '
        'assetId=${newTask.assetId}, existingTaskId=${existingTask.id}',
      );
      return ConflictResolution.replace;
    }

    // 跳过新任务
    _logger.info(
      'Task conflict, skipping new task: '
      'assetId=${newTask.assetId}, existingTaskId=${existingTask.id}',
    );
    return ConflictResolution.skip;
  }

  /// 解决冲突
  /// 
  /// **参数**：
  /// - [resolution] - 解决策略
  /// - [newTask] - 新任务
  /// - [existingTask] - 已存在的任务（可选）
  /// 
  /// **职责**：
  /// - 根据解决策略执行相应操作
  /// - 如果策略为 replace，取消旧任务并创建新任务
  /// - 如果策略为 skip，不创建新任务，但检查并更新旧任务的路径（如果新任务路径有效）
  Future<void> resolveConflict({
    required ConflictResolution resolution,
    required UploadTaskEntityData newTask,
    UploadTaskEntityData? existingTask,
  }) async {
    switch (resolution) {
      case ConflictResolution.skip:
        // 不创建新任务，但检查是否需要更新旧任务的路径
        _logger.info(
          'Skipping new task due to conflict: assetId=${newTask.assetId}',
        );
        
        // 如果旧任务存在且路径可能失效，尝试使用新任务的路径更新
        if (existingTask != null) {
          final oldFile = File(existingTask.localPath);
          final newFile = File(newTask.localPath);
          
          // 如果旧路径不存在但新路径存在，更新旧任务的路径
          final oldExists = await oldFile.exists().catchError((_) => false);
          final newExists = await newFile.exists().catchError((_) => false);
          
          if (!oldExists && newExists) {
            _logger.info(
              'Updating existing task path: taskId=${existingTask.id}, '
              'oldPath=${existingTask.localPath}, newPath=${newTask.localPath}',
            );
            final dao = _database.uploadTaskDao;
            await dao.updateTaskLocalPath(existingTask.id, newTask.localPath);
          }
        }
        return;

      case ConflictResolution.replace:
        if (existingTask != null) {
          // 取消旧任务（通过状态机）
          await _stateMachine.transition(
            existingTask,
            UploadTaskStatus.cancelled,
            errorMessage: 'Replaced by higher priority task',
          );
          _logger.info(
            'Cancelled existing task: taskId=${existingTask.id}',
          );
        }
        // 创建新任务
        final dao = _database.uploadTaskDao;
        await dao.insertTask(newTask);
        _logger.info(
          'Created new task after conflict resolution: taskId=${newTask.id}',
        );
        break;
    }
  }

  /// 检查并解决冲突（便捷方法）
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [newTask] - 新任务
  /// 
  /// **返回**：bool（是否创建了新任务）
  /// 
  /// **职责**：
  /// - 自动检测冲突
  /// - 自动解决冲突
  /// - 返回是否创建了新任务
  Future<bool> checkAndResolveConflict({
    required String userId,
    required UploadTaskEntityData newTask,
  }) async {
    // 1. 检查冲突
    final resolution = await checkConflict(
      userId: userId,
      newTask: newTask,
    );

    // 2. 获取已存在的任务（用于替换或更新路径）
    UploadTaskEntityData? existingTask;
    if (resolution == ConflictResolution.replace || 
        resolution == ConflictResolution.skip) {
      final dao = _database.uploadTaskDao;
      final allTasks = await dao.getTasksByAssetIdAndUserId(
        userId,
        newTask.assetId,
      );
      
      // 过滤状态为 pending 或 uploading 的任务
      final existingTasks = allTasks.where((task) =>
          task.status == UploadTaskStatus.pending ||
          task.status == UploadTaskStatus.uploading).toList();
      existingTask = existingTasks.isNotEmpty ? existingTasks.first : null;
    }

    // 3. 解决冲突
    await resolveConflict(
      resolution: resolution,
      newTask: newTask,
      existingTask: existingTask,
    );

    // 4. 返回是否创建了新任务
    return resolution == ConflictResolution.replace;
  }
}

