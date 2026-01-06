// lib/services/backup/task_update_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';

/// 任务更新服务接口
///
/// **职责**：
/// - 提供任务更新的统一接口
/// - 解耦 UploadOrchestrator 和 UploadService 之间的循环依赖
///
/// **职责边界**：
/// - ✅ **负责**：任务信息的更新操作（路径、重试计数等）
/// - ❌ **不负责**：任务状态管理（由 UploadTaskStateMachine 负责）
/// - ❌ **不负责**：任务队列管理（由 UploadService 负责）
abstract class TaskUpdateService {
  /// 更新任务本地路径
  Future<void> updateTaskLocalPath({
    required String taskId,
    required String localPath,
  });

  /// 增加任务重试计数
  Future<void> incrementRetryCount(String taskId);
}

/// 任务更新服务实现
class TaskUpdateServiceImpl implements TaskUpdateService {
  final AppDatabase _database;
  final Logger _logger = Logger('TaskUpdateServiceImpl');

  TaskUpdateServiceImpl({
    required AppDatabase database,
  }) : _database = database;

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

  @override
  Future<void> incrementRetryCount(String taskId) async {
    _logger.fine('Incrementing retry count: taskId=$taskId');

    final dao = _database.uploadTaskDao;
    await dao.incrementRetryCount(taskId);

    _logger.fine('Retry count incremented: taskId=$taskId');
  }
}

