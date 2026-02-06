// lib/data/database/tables/download_task_entity.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/tables/mixins/drift_defaults_mixin.dart';
import 'package:prismbox/data/database/tables/user_entity.dart';
import 'package:prismbox/data/database/enums/download_task_status.dart';
import 'package:prismbox/data/database/enums/media_download_source_type.dart';

/// 下载任务实体表
/// 一条记录表示用户可见的一条下载（普通媒体 1 个文件，Live Photo 1 条记录对应 2 个文件）
@DataClassName('DownloadTaskEntityData')
@TableIndex(name: 'idx_download_task_user_id', columns: {#userId})
@TableIndex(name: 'idx_download_task_status', columns: {#status})
@TableIndex(name: 'idx_download_task_source_type', columns: {#sourceType})
@TableIndex(name: 'idx_download_task_source_id', columns: {#sourceId})
class DownloadTaskEntity extends Table with DriftDefaultsMixin {
  const DownloadTaskEntity();

  /// 任务 ID（主键）
  TextColumn get id => text()();

  /// 用户 ID（外键）
  TextColumn get userId => text()
      .references(UserEntity, #id, onDelete: KeyAction.cascade)();

  /// 来源类型：timeline_asset | post_media
  IntColumn get sourceType => intEnum<MediaDownloadSourceType>()();

  /// 来源 ID：时间线为 assetId，帖子为 media.uuid
  TextColumn get sourceId => text()();

  /// 主资源 media UUID（原图/主图）
  TextColumn get mediaUuid => text()();

  /// Live Photo 时视频的 media UUID，非 Live 为 null
  TextColumn get livePhotoVideoUuid => text().nullable()();

  /// 展示用文件名
  TextColumn get filename => text()();

  /// 主资源类型：IMAGE | VIDEO
  TextColumn get itemType => text()();

  /// 任务状态
  IntColumn get status => intEnum<DownloadTaskStatus>()
      .withDefault(const Constant(0))(); // DownloadTaskStatus.pending = 0

  /// 进度 0–100，Live Photo 可为两文件综合进度
  IntColumn get progress => integer().withDefault(const Constant(0))();

  /// 失败原因
  TextColumn get errorMessage => text().nullable()();

  /// 主图下载完成后的临时路径（后处理写相册后删除）
  TextColumn get imageTempPath => text().nullable()();

  /// Live 视频临时路径（仅 Live Photo）
  TextColumn get videoTempPath => text().nullable()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
