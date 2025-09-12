// lib/data/datasources/local_db/daos/media_asset_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [MediaAssets, SyncJobs])
class MediaAssetDao extends DatabaseAccessor<AppDatabase>
    with _$MediaAssetDaoMixin {
  MediaAssetDao(super.db);

  Future<List<String>> getAllLocalAssetIds() {
    final query = selectOnly(mediaAssets)
      ..addColumns([mediaAssets.localId])
      ..where(mediaAssets.localId.isNotNull());

    return query.map((row) => row.read(mediaAssets.localId)!).get();
  }

  Stream<List<MediaAsset>> watchAllMediaAssets() => select(mediaAssets).watch();

  Future<int> insertMediaAsset(MediaAssetsCompanion entity) =>
      into(mediaAssets).insert(entity);

  Future<void> bulkInsertCloudMedia(List<MediaAssetsCompanion> assets) async {
    await batch((batch) {
      batch.insertAll(mediaAssets, assets, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<void> updateAsset(MediaAssetsCompanion companion) {
    return (update(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
  }

  Future<void> updateAssetStatus(int assetId, SyncStatus status) {
    return (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(syncStatus: Value(status)),
    );
  }

  Future<void> deleteAllCloudRelatedAssets() {
    return (delete(mediaAssets)..where(
          (tbl) =>
              tbl.syncStatus.isNotValue(SyncStatus.localOnlyNotSelected.name),
        ))
        .go();
  }

  Future<void> markAsPendingBackup(List<int> assetIds) async {
    return transaction(() async {
      final query = update(mediaAssets)..where((tbl) => tbl.id.isIn(assetIds));
      await query.write(
        const MediaAssetsCompanion(syncStatus: Value(SyncStatus.uploading)),
      );
      final jobs = assetIds.map(
        (id) => SyncJobsCompanion.insert(
          assetId: Value(id),
          jobType: JobType.upload,
          status: JobStatus.pending,
        ),
      );
      await batch((batch) => batch.insertAll(syncJobs, jobs));
    });
  }

  Future<void> performOptimisticDelete(MediaAsset assetToDelete) async {
    return transaction(() async {
      await (delete(
        mediaAssets,
      )..where((tbl) => tbl.id.equals(assetToDelete.id))).go();
      if (assetToDelete.cloudUuid != null) {
        await into(syncJobs).insert(
          SyncJobsCompanion.insert(
            assetId: Value(assetToDelete.id),
            relatedCloudUuid: Value(assetToDelete.cloudUuid),
            jobType: JobType.deleteCloud,
            status: JobStatus.pending,
          ),
        );
      }
    });
  }

  Future<void> bulkUpsertCloudMedia(
    List<MediaAssetsCompanion> cloudAssets,
  ) async {
    if (cloudAssets.isEmpty) return;
    await transaction(() async {
      for (final asset in cloudAssets) {
        await into(mediaAssets).insertOnConflictUpdate(asset);
      }
    });
  }

  Future<void> applyCloudChanges({
    required List<MediaAssetsCompanion> toUpsert,
    required List<String> uuidsToDelete,
  }) async {
    log("开始应用云端变更，执行智能合并...", name: 'MediaAssetDao');
    log(
      "待处理: ${toUpsert.length} 条, 待删除: ${uuidsToDelete.length} 条。",
      name: 'MediaAssetDao',
    );

    await transaction(() async {
      if (uuidsToDelete.isNotEmpty) {
        final count = await (delete(
          mediaAssets,
        )..where((tbl) => tbl.cloudUuid.isIn(uuidsToDelete))).go();
        log("成功删除了 $count 条云端指定的记录。", name: 'MediaAssetDao');
      }

      if (toUpsert.isEmpty) return;

      int updatedByHash = 0;
      int newInserts = 0;
      int skipped = 0;

      for (final companion in toUpsert) {
        final contentHashValue = companion.contentHash.value;
        final cloudUuidValue = companion.cloudUuid.value;

        if (contentHashValue == null || cloudUuidValue == null) {
          log(
            "警告: 跳过一个没有有效 contentHash 或 cloudUuid 的云端资产。",
            name: 'MediaAssetDao',
          );
          skipped++;
          continue;
        }

        final existingAssetByHash =
            await (select(mediaAssets)
                  ..where((tbl) => tbl.contentHash.equals(contentHashValue)))
                .getSingleOrNull();

        if (existingAssetByHash != null &&
            existingAssetByHash.syncStatus == SyncStatus.localOnlyNotSelected) {
          await (update(
            mediaAssets,
          )..where((tbl) => tbl.contentHash.equals(contentHashValue))).write(
            companion.copyWith(
              syncStatus: const Value(SyncStatus.synced),
              updatedAt: Value(DateTime.now()),
            ),
          );
          updatedByHash++;
        } else {
          final existingAssetByUuid =
              await (select(mediaAssets)
                    ..where((tbl) => tbl.cloudUuid.equals(cloudUuidValue)))
                  .getSingleOrNull();

          if (existingAssetByUuid == null) {
            await into(mediaAssets).insert(companion);
            newInserts++;
          } else {
            skipped++;
          }
        }
      }

      log(
        "处理完成：通过哈希匹配更新 $updatedByHash 条记录，新增 $newInserts 条云端记录，跳过 $skipped 条记录。",
        name: 'MediaAssetDao',
      );
    });
  }

  Future<void> createUploadJobForExistingAsset(int assetId) async {
    return transaction(() async {
      await (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
        const MediaAssetsCompanion(syncStatus: Value(SyncStatus.uploading)),
      );

      await into(syncJobs).insert(
        SyncJobsCompanion.insert(
          assetId: Value(assetId),
          jobType: JobType.upload,
          status: JobStatus.pending,
          priority: Value(10),
        ),
      );
    });
  }

  Future<void> updateMediaAsset(int id, MediaAssetsCompanion companion) {
    return (update(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(id))).write(companion);
  }

  Future<void> updateMediaAssetWithlocalId(
    String localId,
    MediaAssetsCompanion companion,
  ) {
    return (update(
      mediaAssets,
    )..where((tbl) => tbl.localId.equals(localId))).write(companion);
  }

  Stream<MediaAsset> watchMediaAssetById(int id) {
    return (select(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(id))).watchSingle();
  }

  Future<List<MediaAsset>> getAssetsByLocalIds(List<String> ids) {
    return (select(mediaAssets)..where((tbl) => tbl.localId.isIn(ids))).get();
  }

  Future<MediaAsset?> getAssetByLocalId(String id) {
    return (select(
      mediaAssets,
    )..where((tbl) => tbl.localId.equals(id))).getSingleOrNull();
  }

  Stream<List<MediaAsset>> watchAssetsByLocalIds(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    final query = select(mediaAssets)..where((tbl) => tbl.localId.isIn(ids));
    return query.watch();
  }

  Future<MediaAsset?> getAssetByCloudUuid(String cloudUuid) {
    return (select(
      mediaAssets,
    )..where((tbl) => tbl.cloudUuid.equals(cloudUuid))).getSingleOrNull();
  }

  Future<MediaAsset?> getAssetById(int id) {
    return (select(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
}
