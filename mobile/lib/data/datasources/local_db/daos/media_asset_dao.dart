// lib/data/datasources/local_db/daos/media_asset_dao.dart

part of '../app_database.dart';

@DriftAccessor(tables: [MediaAssets, SyncJobs])
class MediaAssetDao extends DatabaseAccessor<AppDatabase>
    with _$MediaAssetDaoMixin {
  // 创建一个 Logger 实例
  final _log = Logger('MediaAssetDao');

  MediaAssetDao(super.db);

  Future<List<String>> getAllLocalAssetIds() {
    _log.fine('Executing query: getAllLocalAssetIds');
    final query = selectOnly(mediaAssets)
      ..addColumns([mediaAssets.localId])
      ..where(mediaAssets.localId.isNotNull());

    return query.map((row) => row.read(mediaAssets.localId)!).get();
  }

  Stream<List<MediaAsset>> watchAllMediaAssets() {
    _log.fine('Watching all media assets.');
    return select(mediaAssets).watch();
  }

  Future<int> insertMediaAsset(MediaAssetsCompanion entity) {
    _log.fine(
      'Inserting a single media asset: ${entity.localId.value ?? entity.cloudUuid.value}',
    );
    return into(mediaAssets).insert(entity);
  }

  Future<void> bulkInsertCloudMedia(List<MediaAssetsCompanion> assets) async {
    if (assets.isEmpty) {
      _log.info(
        'bulkInsertCloudMedia called with an empty list. Nothing to do.',
      );
      return;
    }
    _log.info(
      'Bulk inserting ${assets.length} cloud media assets with insertOrIgnore mode.',
    );
    await batch((batch) {
      batch.insertAll(mediaAssets, assets, mode: InsertMode.insertOrIgnore);
    });
  }

  Future<void> updateAsset(MediaAssetsCompanion companion) {
    _log.fine('Updating asset with ID: ${companion.id.value}');
    return (update(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(companion);
  }

  Future<void> updateAssetStatus(int assetId, SyncStatus status) {
    _log.fine('Updating status for asset ID $assetId to ${status.name}');
    return (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
      MediaAssetsCompanion(syncStatus: Value(status)),
    );
  }

  Future<void> deleteAllCloudRelatedAssets() {
    _log.warning(
      'Deleting all cloud-related assets (everything except localOnlyNotSelected).',
    );
    return (delete(mediaAssets)..where(
          (tbl) =>
              tbl.syncStatus.isNotValue(SyncStatus.localOnlyNotSelected.name),
        ))
        .go();
  }

  Future<void> markAsPendingBackup(List<int> assetIds) async {
    if (assetIds.isEmpty) {
      _log.info('markAsPendingBackup called with empty list. No action taken.');
      return;
    }
    _log.info(
      'Marking ${assetIds.length} assets as pending backup and creating upload jobs within a transaction.',
    );
    return transaction(() async {
      _log.fine('Transaction started for markAsPendingBackup.');
      final query = update(mediaAssets)..where((tbl) => tbl.id.isIn(assetIds));
      final updatedRows = await query.write(
        const MediaAssetsCompanion(syncStatus: Value(SyncStatus.uploading)),
      );
      _log.fine('Updated $updatedRows assets to uploading status.');

      final jobs = assetIds.map(
        (id) => SyncJobsCompanion.insert(
          assetId: Value(id),
          jobType: JobType.upload,
          status: JobStatus.pending,
        ),
      );
      await batch((batch) => batch.insertAll(syncJobs, jobs));
      _log.fine('Created ${jobs.length} new upload jobs.');
      _log.fine('Transaction committed for markAsPendingBackup.');
    });
  }

  /// 将指定的媒体资源转换为“仅云端”状态。
  /// 这会清除其本地 ID 和文件路径，并更新同步状态。
  Future<void> transitionToCloudOnly(int assetId) async {
    _log.info('Transitioning asset ID $assetId to cloud-only state.');
    final companion = MediaAssetsCompanion(
      localId: const Value(null),
      filePath: const Value(null),
      syncStatus: const Value(
        SyncStatus.cloudOnly,
      ), // 假设 SyncStatus 枚举中有 cloudOnly
      updatedAt: Value(DateTime.now()),
    );
    await (update(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(assetId))).write(companion);
    _log.fine('Successfully transitioned asset ID $assetId to cloud-only.');
  }

  /// 从数据库中永久删除一个仅本地存在的媒体资源记录。
  Future<void> deleteLocalOnlyAsset(int assetId) async {
    _log.info('Permanently deleting local-only asset with ID: $assetId');
    await (delete(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).go();
    _log.fine('Successfully deleted local-only asset ID $assetId.');
  }

  Future<void> bulkUpsertCloudMedia(
    List<MediaAssetsCompanion> cloudAssets,
  ) async {
    if (cloudAssets.isEmpty) {
      _log.info(
        'bulkUpsertCloudMedia called with an empty list. Nothing to do.',
      );
      return;
    }
    _log.info(
      'Bulk upserting ${cloudAssets.length} cloud media assets within a transaction.',
    );
    await transaction(() async {
      _log.fine('Transaction started for bulkUpsertCloudMedia.');
      for (final asset in cloudAssets) {
        // insertOnConflictUpdate is generally efficient in Drift
        await into(mediaAssets).insertOnConflictUpdate(asset);
      }
      _log.fine('Transaction committed for bulkUpsertCloudMedia.');
    });
  }

  Future<void> applyCloudChanges({
    required List<MediaAssetsCompanion> toUpsert,
    required List<String> uuidsToDelete,
  }) async {
    _log.info(
      'Starting to apply cloud changes. Upserts: ${toUpsert.length}, Deletes: ${uuidsToDelete.length}.',
    );

    await transaction(() async {
      _log.info('Transaction started for applyCloudChanges.');
      if (uuidsToDelete.isNotEmpty) {
        final count = await (delete(
          mediaAssets,
        )..where((tbl) => tbl.cloudUuid.isIn(uuidsToDelete))).go();
        _log.info(
          'Successfully deleted $count records specified by the cloud.',
        );
      }

      if (toUpsert.isEmpty) {
        _log.info('No assets to upsert. Finishing transaction.');
        return;
      }

      int updatedByHash = 0;
      int newInserts = 0;
      int skipped = 0;

      for (final companion in toUpsert) {
        final contentHashValue = companion.contentHash.value;
        final cloudUuidValue = companion.cloudUuid.value;

        if (contentHashValue == null || cloudUuidValue == null) {
          _log.warning(
            'Skipping a cloud asset due to missing contentHash or cloudUuid.',
          );
          skipped++;
          continue;
        }

        final existingAssetByHash =
            await (select(mediaAssets)
                  ..where((tbl) => tbl.contentHash.equals(contentHashValue)))
                .getSingleOrNull();

        // 核心逻辑：如果本地已存在一个未选择备份的同哈希值文件，则将其与云端记录合并
        if (existingAssetByHash != null &&
            existingAssetByHash.syncStatus == SyncStatus.localOnlyNotSelected) {
          _log.fine(
            'Found existing local-only asset with hash $contentHashValue. Merging with cloud data for UUID $cloudUuidValue.',
          );
          await (update(
            mediaAssets,
          )..where((tbl) => tbl.id.equals(existingAssetByHash.id))).write(
            // 使用 cloud companion 的数据，但保留本地 ID，并更新状态
            companion.copyWith(
              id: const Value.absent(), // 不更新 ID
              localId: Value(existingAssetByHash.localId), // 确保 localId 保留
              syncStatus: const Value(SyncStatus.synced),
              updatedAt: Value(DateTime.now()),
            ),
          );
          updatedByHash++;
        } else {
          // 否则，按云端 UUID 查找，如果不存在则为新插入
          final existingAssetByUuid =
              await (select(mediaAssets)
                    ..where((tbl) => tbl.cloudUuid.equals(cloudUuidValue)))
                  .getSingleOrNull();

          if (existingAssetByUuid == null) {
            _log.finer(
              'Inserting new cloud-only asset with UUID $cloudUuidValue.',
            );
            await into(mediaAssets).insert(companion);
            newInserts++;
          } else {
            _log.finer(
              'Asset with UUID $cloudUuidValue already exists and is not a candidate for merging. Skipping.',
            );
            skipped++;
          }
        }
      }

      _log.info(
        'Cloud changes applied successfully: $updatedByHash merged by hash, $newInserts newly inserted, $skipped skipped.',
      );
      _log.info('Transaction committed for applyCloudChanges.');
    });
  }

  // ... (其他方法的日志可以类似地添加) ...
  // 为了简洁，我将省略其余方法的日志添加，但模式是相同的：
  // 在函数入口处记录意图和参数，在出口处记录结果。

  Future<void> createUploadJobForExistingAsset(int assetId) async {
    _log.info('Creating upload job for existing asset ID: $assetId');
    return transaction(() async {
      await (update(mediaAssets)..where((tbl) => tbl.id.equals(assetId))).write(
        const MediaAssetsCompanion(syncStatus: Value(SyncStatus.uploading)),
      );
      _log.fine('Updated asset $assetId status to uploading.');

      await into(syncJobs).insert(
        SyncJobsCompanion.insert(
          assetId: Value(assetId),
          jobType: JobType.upload,
          status: JobStatus.pending,
          priority: const Value(10),
        ),
      );
      _log.fine('Inserted high-priority upload job for asset $assetId.');
    });
  }

  Future<void> updateMediaAsset(int id, MediaAssetsCompanion companion) {
    _log.fine('Updating media asset with ID: $id');
    return (update(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(id))).write(companion);
  }

  Future<void> updateMediaAssetWithlocalId(
    String localId,
    MediaAssetsCompanion companion,
  ) {
    _log.fine('Updating media asset with localId: $localId');
    return (update(
      mediaAssets,
    )..where((tbl) => tbl.localId.equals(localId))).write(companion);
  }

  Stream<MediaAsset> watchMediaAssetById(int id) {
    _log.fine('Watching media asset by ID: $id');
    return (select(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(id))).watchSingle();
  }

  Future<List<MediaAsset>> getAssetsByLocalIds(List<String> ids) {
    _log.fine('Getting assets by ${ids.length} local IDs.');
    return (select(mediaAssets)..where((tbl) => tbl.localId.isIn(ids))).get();
  }

  Future<MediaAsset?> getAssetByLocalId(String id) {
    _log.fine('Getting asset by local ID: $id');
    return (select(
      mediaAssets,
    )..where((tbl) => tbl.localId.equals(id))).getSingleOrNull();
  }

  Stream<List<MediaAsset>> watchAssetsByLocalIds(List<String> ids) {
    _log.fine('Watching assets by ${ids.length} local IDs.');
    if (ids.isEmpty) return Stream.value([]);
    final query = select(mediaAssets)..where((tbl) => tbl.localId.isIn(ids));
    return query.watch();
  }

  Future<MediaAsset?> getAssetByCloudUuid(String cloudUuid) {
    _log.fine('Getting asset by cloud UUID: $cloudUuid');
    return (select(
      mediaAssets,
    )..where((tbl) => tbl.cloudUuid.equals(cloudUuid))).getSingleOrNull();
  }

  Future<MediaAsset?> getAssetById(int id) {
    _log.fine('Getting asset by ID: $id');
    return (select(
      mediaAssets,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
}
