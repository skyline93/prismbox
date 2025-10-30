// lib/data/datasources/local_db/tables/media_assets.dart

import 'package:drift/drift.dart';
import 'package:mobile/core/enums.dart';

@DataClassName('MediaAsset')
class MediaAssets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localId => text().unique().nullable()();
  TextColumn get cloudUuid => text().unique().nullable()();
  TextColumn get contentHash => text().nullable()();
  TextColumn get syncStatus =>
      text().map(const EnumNameConverter(SyncStatus.values))();
  TextColumn get assetType =>
      text().map(const EnumNameConverter(MediaType.values))();
  TextColumn get filePath => text().nullable()();
  TextColumn get fileName => text().nullable()();
  BoolColumn get isRAW => boolean().withDefault(const Constant(false))();
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationSec => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get mediaTakenAt => dateTime()(); // 媒体拍摄时间（非空）
  DateTimeColumn get updatedAt => dateTime()();

  TextColumn get lifecycleState => text()
      .map(const EnumNameConverter(LifecycleState.values))
      .withDefault(const Constant('active'))();
  DateTimeColumn get lifecycleModifiedDate => dateTime().nullable()();
  TextColumn get trashPath => text().nullable()();
}
