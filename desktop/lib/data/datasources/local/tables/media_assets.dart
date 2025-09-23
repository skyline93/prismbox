// lib/data/datasources/local/tables/media_assets.dart

import 'package:drift/drift.dart';

@DataClassName('MediaAsset')
class MediaAssets extends Table {
  @override
  String get tableName => 'media_assets';

  TextColumn get uuid => text().nullable()();
  TextColumn get filename => text().nullable()();
  TextColumn get originalFilename => text()();
  TextColumn get itemType => text()();
  TextColumn get hash => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get mediaTakenAt => text().nullable()();
  TextColumn get thumbnailUrl => text()();
  TextColumn get previewUrl => text()();
  TextColumn get downloadUrl => text()();

  @override
  Set<Column> get primaryKey => {uuid};
}
