// lib/data/database/tables/upload_task_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';

/// 上传任务实体表
/// 存储上传任务的详细信息
@DataClassName('UploadTaskEntityData')
@TableIndex(name: 'idx_upload_task_user_id', columns: {#userId})
@TableIndex(name: 'idx_upload_task_status', columns: {#status})
@TableIndex(name: 'idx_upload_task_type', columns: {#taskType})
@TableIndex(name: 'idx_upload_task_priority', columns: {#priority})
@TableIndex(name: 'idx_upload_task_asset_id', columns: {#assetId})
class UploadTaskEntity extends Table with DriftDefaultsMixin {
  const UploadTaskEntity();

  /// 任务 ID（主键）
  TextColumn get id => text()();

  /// 用户 ID（外键，用于多用户隔离）
  TextColumn get userId => text()
      .references(UserEntity, #id, onDelete: KeyAction.cascade)();

  /// 资产 ID（本地资产ID，关联LocalAssetEntity）
  TextColumn get assetId => text()();

  /// 本地文件路径
  TextColumn get localPath => text()();

  /// 远程路径（上传目标路径）
  TextColumn get remotePath => text()();

  /// 媒体 UUID（上传成功后从服务器响应中提取）
  TextColumn get mediaUuid => text().nullable()();

  /// 文件大小（字节）
  IntColumn get fileSize => integer()();

  /// 任务类型（manual/auto）
  IntColumn get taskType => intEnum<UploadTaskType>()();

  /// 优先级（数字越小优先级越高，manual: 1, auto: 5）
  IntColumn get priority => integer()
      .withDefault(const Constant(5))(); // 默认正常优先级

  /// 任务状态
  IntColumn get status => intEnum<UploadTaskStatus>()
      .withDefault(const Constant(0))(); // UploadTaskStatus.pending = 0

  /// 重试次数
  IntColumn get retryCount => integer()
      .withDefault(const Constant(0))();

  /// 最大重试次数（默认 3）
  IntColumn get maxRetries => integer()
      .withDefault(const Constant(3))();

  /// 错误信息
  TextColumn get errorMessage => text().nullable()();

  /// 上传完成时间
  DateTimeColumn get uploadedAt => dateTime().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  /// 进度百分比（0-100）
  IntColumn get progress => integer()
      .withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

