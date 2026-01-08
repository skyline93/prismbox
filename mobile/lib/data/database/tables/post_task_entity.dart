// lib/data/database/tables/post_task_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/enums/post_task_status.dart';

/// 帖子任务实体表
/// 存储帖子发布任务的详细信息
@DataClassName('PostTaskEntityData')
@TableIndex(name: 'idx_post_task_user_id', columns: {#userId})
@TableIndex(name: 'idx_post_task_status', columns: {#status})
@TableIndex(name: 'idx_post_task_group_id', columns: {#groupId})
class PostTaskEntity extends Table with DriftDefaultsMixin {
  const PostTaskEntity();

  /// 任务 ID（主键）
  TextColumn get id => text()();

  /// 用户 ID（外键，用于多用户隔离）
  TextColumn get userId => text()
      .references(UserEntity, #id, onDelete: KeyAction.cascade)();

  /// 圈子 UUID
  TextColumn get groupId => text()();

  /// 帖子文字说明
  TextColumn get caption => text().nullable()();

  /// 媒体文件路径列表（JSON 格式）
  TextColumn get mediaPaths => text()();

  /// 媒体资产 ID 列表（JSON 格式，LocalAssetEntity 的 id，可选）
  TextColumn get mediaAssetIds => text().nullable()();

  /// 媒体 UUID 列表（JSON 格式，上传完成后填充）
  TextColumn get mediaUuids => text().nullable()();

  /// 任务状态
  IntColumn get status => intEnum<PostTaskStatus>()
      .withDefault(const Constant(0))(); // PostTaskStatus.pending = 0

  /// 进度百分比（0-100）
  IntColumn get progress => integer()
      .withDefault(const Constant(0))();

  /// 错误信息
  TextColumn get errorMessage => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

