// lib/data/database/tables/mixins/asset_entity_mixin.dart

import 'package:drift/drift.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';

/// 资产实体通用字段 Mixin
mixin AssetEntityMixin on Table {
  /// 资产名称
  TextColumn get name => text()();
  
  /// 资产类型
  IntColumn get type => integer().map(intEnum<AssetType>())();
  
  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();
  
  /// 更新时间
  DateTimeColumn get updatedAt => dateTime()();
  
  /// 宽度（像素）
  IntColumn get width => integer().nullable()();
  
  /// 高度（像素）
  IntColumn get height => integer().nullable()();
  
  /// 时长（秒，仅视频/音频）
  IntColumn get durationInSeconds => integer().nullable()();
}

