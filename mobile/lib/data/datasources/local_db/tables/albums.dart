// lib/data/datasources/local_db/tables/albums.dart

import 'package:drift/drift.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';

/// 定义 `Albums` 表，用于存储本地和云端相册的元数据。
@DataClassName('Album')
class Albums extends Table {
  @override
  String get tableName => 'albums';

  /// 相册的唯一ID，来自 photo_manager 或服务器。
  /// 设置为[id]为主键
  @override
  Set<Column> get primaryKey => {id};

  /// 相册ID (主键, 文本类型)
  TextColumn get id => text()();

  /// 相册名称
  TextColumn get name => text()();

  /// 相册包含的媒体数量
  IntColumn get assetCount => integer()();

  /// 相册来源 (本地或云端)
  IntColumn get source => intEnum<AlbumSource>()();

  /// 封面媒体的ID (可空)
  TextColumn get thumbnailId => text().nullable()();
}
