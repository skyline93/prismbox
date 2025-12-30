// lib/services/encrypted_space/retry_queue_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:uuid/uuid.dart';

/// 重试任务类型
enum RetryTaskType {
  addAssets,
  removeAssets,
  migrateToPrivateSpace,
  migrateFromPrivateSpace,
}

/// 重试任务
class RetryTask {
  final RetryTaskType type;
  final String albumId;
  final List<String> assetIds;
  final Map<String, dynamic>? extraData;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? lastRetryAt;

  RetryTask({
    required this.type,
    required this.albumId,
    required this.assetIds,
    this.extraData,
    this.retryCount = 0,
    DateTime? createdAt,
    this.lastRetryAt,
  }) : createdAt = createdAt ?? DateTime.now();

  RetryTask copyWith({
    RetryTaskType? type,
    String? albumId,
    List<String>? assetIds,
    Map<String, dynamic>? extraData,
    int? retryCount,
    DateTime? createdAt,
    DateTime? lastRetryAt,
  }) {
    return RetryTask(
      type: type ?? this.type,
      albumId: albumId ?? this.albumId,
      assetIds: assetIds ?? this.assetIds,
      extraData: extraData ?? this.extraData,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}

/// 重试队列服务
/// 用于处理网络异常等情况下的操作重试
/// 支持持久化存储，应用重启后可以恢复任务
class RetryQueueService {
  static final RetryQueueService _instance = RetryQueueService._internal();
  factory RetryQueueService() => _instance;
  RetryQueueService._internal();

  final Logger _log = Logger('RetryQueueService');
  final Uuid _uuid = const Uuid();

  // 数据库实例（可选，如果提供则启用持久化）
  AppDatabase? _database;

  // 重试队列（内存缓存）
  final List<RetryTask> _retryQueue = [];

  // 最大重试次数
  static const int _maxRetryCount = 3;

  // 重试间隔（指数退避）
  static const Duration _baseRetryInterval = Duration(seconds: 5);

  // 重试回调函数
  Future<bool> Function(RetryTask)? _retryCallback;

  // 重试计时器
  Timer? _retryTimer;

  // 是否已初始化
  bool _initialized = false;

  /// 初始化服务（启用持久化）
  Future<void> initialize(AppDatabase database) async {
    if (_initialized) {
      _log.warning('RetryQueueService already initialized');
      return;
    }

    _database = database;
    _initialized = true;

    // 从数据库加载待处理的任务
    await _loadTasksFromDatabase();

    _log.info('RetryQueueService initialized with ${_retryQueue.length} pending tasks');
  }

  /// 设置重试回调函数
  void setRetryCallback(Future<bool> Function(RetryTask) callback) {
    _retryCallback = callback;
    _startRetryTimer();
  }

  /// 添加任务到重试队列
  Future<void> addTask(RetryTask task) async {
    _retryQueue.add(task);
    
    // 持久化到数据库
    if (_database != null) {
      await _saveTaskToDatabase(task);
    }
    
    _log.info('Task added to retry queue: ${task.type}, albumId: ${task.albumId}, assetCount: ${task.assetIds.length}');
    _startRetryTimer();
  }

  /// 从重试队列移除任务
  void removeTask(RetryTask task) {
    _retryQueue.remove(task);
    _log.info('Task removed from retry queue: ${task.type}, albumId: ${task.albumId}');
  }

  /// 启动重试计时器
  void _startRetryTimer() {
    if (_retryQueue.isEmpty || _retryCallback == null) {
      _retryTimer?.cancel();
      _retryTimer = null;
      return;
    }

    if (_retryTimer?.isActive ?? false) {
      return;
    }

    // 找到最早的任务，计算重试时间
    final nextTask = _retryQueue.first;
    final retryInterval = _calculateRetryInterval(nextTask.retryCount);

    _retryTimer = Timer(retryInterval, () {
      _processRetryQueue();
    });
  }

  /// 计算重试间隔（指数退避）
  Duration _calculateRetryInterval(int retryCount) {
    if (retryCount == 0) {
      return _baseRetryInterval;
    }
    // 指数退避：5s, 10s, 20s
    return Duration(seconds: _baseRetryInterval.inSeconds * (1 << retryCount));
  }

  /// 处理重试队列
  Future<void> _processRetryQueue() async {
    if (_retryQueue.isEmpty || _retryCallback == null) {
      return;
    }

    final task = _retryQueue.first;
    
    // 检查是否超过最大重试次数
    if (task.retryCount >= _maxRetryCount) {
      _log.warning('Task exceeded max retry count, removing from queue: ${task.type}, albumId: ${task.albumId}');
      final removedTask = _retryQueue.removeAt(0);
      if (_database != null) {
        await _deleteTaskFromDatabase(removedTask);
      }
      _startRetryTimer();
      return;
    }

    try {
      _log.info('Retrying task: ${task.type}, albumId: ${task.albumId}, retryCount: ${task.retryCount}');
      
      // 执行重试
      final success = await _retryCallback!(task);
      
      if (success) {
        // 重试成功，移除任务
        final removedTask = _retryQueue.removeAt(0);
        if (_database != null) {
          await _deleteTaskFromDatabase(removedTask);
        }
        _log.info('Task retry succeeded: ${task.type}, albumId: ${task.albumId}');
      } else {
        // 重试失败，增加重试次数
        final updatedTask = task.copyWith(
          retryCount: task.retryCount + 1,
          lastRetryAt: DateTime.now(),
        );
        _retryQueue[0] = updatedTask;
        if (_database != null) {
          await _updateTaskInDatabase(updatedTask);
        }
        _log.warning('Task retry failed, will retry later: ${task.type}, albumId: ${task.albumId}, retryCount: ${updatedTask.retryCount}');
      }
    } catch (e, stackTrace) {
      _log.severe('Error during task retry: ${task.type}, albumId: ${task.albumId}', e, stackTrace);
      
      // 增加重试次数
      final updatedTask = task.copyWith(
        retryCount: task.retryCount + 1,
        lastRetryAt: DateTime.now(),
      );
      _retryQueue[0] = updatedTask;
      if (_database != null) {
        await _updateTaskInDatabase(updatedTask);
      }
    }

    // 继续处理下一个任务
    _startRetryTimer();
  }

  /// 获取队列中的所有任务
  List<RetryTask> getPendingTasks() {
    return List.unmodifiable(_retryQueue);
  }

  /// 清空重试队列
  Future<void> clearQueue() async {
    _retryQueue.clear();
    _retryTimer?.cancel();
    _retryTimer = null;
    
    if (_database != null) {
      await _database!.retryTaskDao.deleteAllTasks();
    }
    
    _log.info('Retry queue cleared');
  }

  /// 清理资源
  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryQueue.clear();
    _retryCallback = null;
    _database = null;
    _initialized = false;
    _log.info('RetryQueueService disposed');
  }

  /// 从数据库加载任务
  Future<void> _loadTasksFromDatabase() async {
    if (_database == null) return;

    try {
      final tasks = await _database!.retryTaskDao.getAllPendingTasks();
      for (final taskData in tasks) {
        final task = _entityToTask(taskData);
        if (task != null) {
          _retryQueue.add(task);
        }
      }
      _log.info('Loaded ${_retryQueue.length} tasks from database');
    } catch (e, stackTrace) {
      _log.warning('Failed to load tasks from database', e, stackTrace);
    }
  }

  /// 保存任务到数据库
  Future<void> _saveTaskToDatabase(RetryTask task) async {
    if (_database == null) return;

    try {
      final taskId = _getTaskId(task);
      final entity = _taskToEntity(task, taskId);
      await _database!.retryTaskDao.saveTask(entity);
    } catch (e, stackTrace) {
      _log.warning('Failed to save task to database', e, stackTrace);
    }
  }

  /// 更新数据库中的任务
  Future<void> _updateTaskInDatabase(RetryTask task) async {
    if (_database == null) return;

    try {
      final taskId = _getTaskId(task);
      final entity = _taskToEntity(task, taskId);
      await _database!.retryTaskDao.updateTask(entity);
    } catch (e, stackTrace) {
      _log.warning('Failed to update task in database', e, stackTrace);
    }
  }

  /// 从数据库删除任务
  Future<void> _deleteTaskFromDatabase(RetryTask task) async {
    if (_database == null) return;

    try {
      final taskId = _getTaskId(task);
      await _database!.retryTaskDao.deleteTask(taskId);
    } catch (e, stackTrace) {
      _log.warning('Failed to delete task from database', e, stackTrace);
    }
  }

  /// 获取任务ID（用于数据库存储）
  String _getTaskId(RetryTask task) {
    // 使用任务属性生成唯一ID
    final data = '${task.type}_${task.albumId}_${task.assetIds.join(",")}_${task.createdAt.millisecondsSinceEpoch}';
    return _uuid.v5(Uuid.NAMESPACE_OID, data);
  }

  /// 将RetryTask转换为RetryTaskEntityData
  RetryTaskEntityData _taskToEntity(RetryTask task, String taskId) {
    // 将createdAt存储到extraData中（因为RetryTaskEntityData没有createdAt字段）
    final extraData = <String, dynamic>{
      if (task.extraData != null) ...task.extraData!,
      '_createdAt': task.createdAt.toIso8601String(),
    };
    
    return RetryTaskEntityData(
      id: taskId,
      taskType: _taskTypeToInt(task.type),
      albumId: task.albumId,
      assetIds: jsonEncode(task.assetIds),
      extraData: jsonEncode(extraData),
      retryCount: task.retryCount,
      lastRetryAt: task.lastRetryAt,
    );
  }

  /// 将RetryTaskEntityData转换为RetryTask
  RetryTask? _entityToTask(RetryTaskEntityData entity) {
    try {
      Map<String, dynamic>? extraDataMap;
      DateTime? createdAt;
      
      if (entity.extraData != null) {
        extraDataMap = jsonDecode(entity.extraData!) as Map<String, dynamic>;
        // 从extraData中提取createdAt
        if (extraDataMap.containsKey('_createdAt')) {
          createdAt = DateTime.parse(extraDataMap.remove('_createdAt') as String);
        }
      }
      
      return RetryTask(
        type: _intToTaskType(entity.taskType),
        albumId: entity.albumId,
        assetIds: (jsonDecode(entity.assetIds) as List).cast<String>(),
        extraData: extraDataMap?.isNotEmpty == true ? extraDataMap : null,
        retryCount: entity.retryCount,
        createdAt: createdAt ?? DateTime.now(), // 如果没有存储的createdAt，使用当前时间
        lastRetryAt: entity.lastRetryAt,
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to convert entity to task', e, stackTrace);
      return null;
    }
  }

  /// 任务类型转整数
  int _taskTypeToInt(RetryTaskType type) {
    switch (type) {
      case RetryTaskType.addAssets:
        return 0;
      case RetryTaskType.removeAssets:
        return 1;
      case RetryTaskType.migrateToPrivateSpace:
        return 2;
      case RetryTaskType.migrateFromPrivateSpace:
        return 3;
    }
  }

  /// 整数转任务类型
  RetryTaskType _intToTaskType(int value) {
    switch (value) {
      case 0:
        return RetryTaskType.addAssets;
      case 1:
        return RetryTaskType.removeAssets;
      case 2:
        return RetryTaskType.migrateToPrivateSpace;
      case 3:
        return RetryTaskType.migrateFromPrivateSpace;
      default:
        return RetryTaskType.addAssets;
    }
  }
}

