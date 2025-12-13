// lib/services/backup/backup_query_builder.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';

/// 备份查询构建器：强制 userId 过滤
/// 
/// **设计目的**：确保所有查询包含 userId，确保多用户数据隔离。
/// 
/// **使用示例**：
/// ```dart
/// // ✅ 正确使用
/// final tasks = await BackupQueryBuilder(database)
///     .withUserId(userId)
///     .buildTaskQuery(status: UploadTaskStatus.pending)
///     .get();
///
/// // ❌ 错误使用（会抛出异常）
/// final tasks = await BackupQueryBuilder(database)
///     .buildTaskQuery()  // 缺少 userId，会抛出 StateError
///     .get();
/// ```
class BackupQueryBuilder {
  final AppDatabase _database;
  String? _userId;

  BackupQueryBuilder(this._database);

  /// 设置用户 ID（必须调用）
  BackupQueryBuilder withUserId(String userId) {
    _userId = userId;
    return this;
  }

  /// 构建任务查询：强制包含 userId 过滤
  /// 
  /// **参数**：
  /// - [status] - 任务状态过滤（可选）
  /// - [taskType] - 任务类型过滤（可选）
  /// 
  /// **返回**：Selectable<UploadTaskEntityData>
  /// 
  /// **异常**：如果未设置 userId，会抛出 StateError
  Selectable<UploadTaskEntityData> buildTaskQuery({
    UploadTaskStatus? status,
    UploadTaskType? taskType,
  }) {
    if (_userId == null) {
      throw StateError(
        'userId must be provided before building query. '
        'Call withUserId() first.',
      );
    }

    var query = _database.select(_database.uploadTaskEntity)
      ..where((t) => t.userId.equals(_userId!));

    if (status != null) {
      query = query..where((t) => t.status.equalsValue(status));
    }

    if (taskType != null) {
      query = query..where((t) => t.taskType.equalsValue(taskType));
    }

    return query;
  }

  /// 构建备份状态查询
  /// 
  /// **返回**：Future<BackupStatusEntityData?>
  /// 
  /// **异常**：如果未设置 userId，会抛出 StateError
  Future<BackupStatusEntityData?> getBackupStatus() async {
    if (_userId == null) {
      throw StateError(
        'userId must be provided. Call withUserId() first.',
      );
    }

    return await (_database.select(_database.backupStatusEntity)
          ..where((t) => t.userId.equals(_userId!)))
        .getSingleOrNull();
  }

  /// 监听备份状态变化
  /// 
  /// **返回**：Stream<BackupStatusEntityData?>
  /// 
  /// **异常**：如果未设置 userId，会抛出 StateError
  Stream<BackupStatusEntityData?> watchBackupStatus() {
    if (_userId == null) {
      throw StateError(
        'userId must be provided. Call withUserId() first.',
      );
    }

    return (_database.select(_database.backupStatusEntity)
          ..where((t) => t.userId.equals(_userId!)))
        .watchSingleOrNull();
  }

  /// 监听任务变化
  /// 
  /// **参数**：
  /// - [status] - 任务状态过滤（可选）
  /// - [taskType] - 任务类型过滤（可选）
  /// 
  /// **返回**：Stream<List<UploadTaskEntityData>>
  /// 
  /// **异常**：如果未设置 userId，会抛出 StateError
  Stream<List<UploadTaskEntityData>> watchTasks({
    UploadTaskStatus? status,
    UploadTaskType? taskType,
  }) {
    if (_userId == null) {
      throw StateError(
        'userId must be provided. Call withUserId() first.',
      );
    }

    var query = _database.select(_database.uploadTaskEntity)
      ..where((t) => t.userId.equals(_userId!));

    if (status != null) {
      query = query..where((t) => t.status.equalsValue(status));
    }

    if (taskType != null) {
      query = query..where((t) => t.taskType.equalsValue(taskType));
    }

    return query.watch();
  }
}

