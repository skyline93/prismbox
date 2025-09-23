// lib/data/datasources/local/daos/media_asset_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [MediaAssets])
class MediaAssetDao extends DatabaseAccessor<AppDatabase>
    with _$MediaAssetDaoMixin {
  MediaAssetDao(super.db);

  Stream<List<MediaAsset>> watchAllAssets() {
    return (select(
      mediaAssets,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
  }

  Future<List<MediaAsset>> getAllAssets() {
    return (select(
      mediaAssets,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<void> upsertAssets(List<MediaAsset> assets) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(mediaAssets, assets);
    });
  }

  Future<void> clearAssets() {
    return delete(mediaAssets).go();
  }
}
