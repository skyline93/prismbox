// lib/data/datasources/local_db/tables/media_assets.dart

import 'package:drift/drift.dart';
import 'package:mobile/data/models/media/media_model.dart';
import '../enums.dart';

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
  IntColumn get width => integer().nullable()();
  IntColumn get height => integer().nullable()();
  IntColumn get durationSec => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
