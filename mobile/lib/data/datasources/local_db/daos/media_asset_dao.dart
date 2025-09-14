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

  /// 将云端的变化（删除、更新、插入）应用到本地数据库。
  /// 此方法经过重构，以提高性能、健壮性和数据一致性。
  Future<void> applyCloudChanges({
    required List<MediaAssetsCompanion> toUpsert,
    required List<String> uuidsToDelete,
  }) async {
    _log.info(
      'Starting to apply cloud changes. Upserts: ${toUpsert.length}, Deletes: ${uuidsToDelete.length}.',
    );

    await transaction(() async {
      _log.info('Transaction started for applyCloudChanges.');

      // 步骤 1: 处理删除
      await _applyDeletesInTransaction(uuidsToDelete);

      // 步骤 2: 处理更新或插入 (Upserts)
      await _applyUpsertsInTransaction(toUpsert);

      _log.info('Transaction committed for applyCloudChanges.');
    });
  }

  /// 在事务中执行删除操作。
  Future<void> _applyDeletesInTransaction(List<String> uuidsToDelete) async {
    if (uuidsToDelete.isEmpty) {
      return;
    }

    final count = await (delete(
      mediaAssets,
    )..where((tbl) => tbl.cloudUuid.isIn(uuidsToDelete))).go();
    _log.info('Successfully deleted $count records specified by the cloud.');
  }

  Future<void> _applyUpsertsInTransaction(
    List<MediaAssetsCompanion> companions,
  ) async {
    if (companions.isEmpty) {
      _log.info('No assets to upsert.');
      return;
    }

    // --- 1. 准备阶段：提取所有需要的 IDs 和 Hashes ---
    final cloudUuids = companions
        .map((c) => c.cloudUuid.value)
        .whereType<String>()
        .toSet();
    final contentHashes = companions
        .map((c) => c.contentHash.value)
        .whereType<String>()
        .toSet();

    // --- 2. 批量获取阶段：一次性从数据库查询所有相关记录 ---
    final existingByUuidQuery = select(mediaAssets)
      ..where((tbl) => tbl.cloudUuid.isIn(cloudUuids));
    final existingByHashQuery = select(mediaAssets)
      ..where((tbl) => tbl.contentHash.isIn(contentHashes));

    final assetsByUuid = {
      for (var asset in await existingByUuidQuery.get())
        asset.cloudUuid!: asset,
    };

    final assetsByHash = <String, List<MediaAsset>>{};
    for (var asset in await existingByHashQuery.get()) {
      (assetsByHash[asset.contentHash!] ??= []).add(asset);
    }

    // --- 3. 处理阶段：遍历云端数据，决定执行更新、合并还是插入 ---
    int updated = 0, merged = 0, inserted = 0, skipped = 0;

    for (final companion in companions) {
      final cloudUuid = companion.cloudUuid.value;
      final contentHash = companion.contentHash.value;

      if (cloudUuid == null || contentHash == null) {
        _log.warning(
          'Skipping a cloud asset due to missing contentHash or cloudUuid.',
        );
        skipped++;
        continue;
      }

      final existingAsset = assetsByUuid[cloudUuid];

      // 策略 1: 按 Cloud UUID 匹配
      if (existingAsset != null) {
        _log.finer(
          'Found existing asset by UUID $cloudUuid. Updating metadata.',
        );
        await (update(
          mediaAssets,
        )..where((tbl) => tbl.id.equals(existingAsset.id))).write(companion);
        updated++;
        continue;
      }

      // 策略 2: 按 Content Hash 匹配
      final potentialMatches = assetsByHash[contentHash] ?? [];

      // ======================= ここが修正点です (This is the fix) =======================
      // 使用 firstWhereOrNull，它会安全地返回 MediaAsset? 类型
      final assetToMerge = potentialMatches.firstWhereOrNull(
        (asset) => asset.syncStatus == SyncStatus.localOnlyNotSelected,
      );
      // ==========================================================================

      if (assetToMerge != null) {
        _log.fine(
          'Found local-only asset with hash $contentHash. Merging with cloud data for UUID $cloudUuid.',
        );
        await (update(
          mediaAssets,
        )..where((tbl) => tbl.id.equals(assetToMerge.id))).write(
          companion.copyWith(
            localId: Value(assetToMerge.localId),
            filePath: Value(assetToMerge.filePath),
            syncStatus: const Value(SyncStatus.synced),
            updatedAt: Value(DateTime.now()),
          ),
        );
        merged++;
        continue;
      }

      // 策略 3: 插入新记录
      _log.finer('Inserting new cloud-only asset with UUID $cloudUuid.');
      await into(mediaAssets).insert(companion);
      inserted++;
    }

    _log.info(
      'Cloud changes applied successfully: $updated updated, $merged merged, $inserted newly inserted, $skipped skipped.',
    );
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

  /// 根据内容哈希和同步状态查询第一条匹配的记录。
  /// 这种方法更高效，因为它直接在数据库层面进行过滤和限制。
  Future<MediaAsset?> getFirstAssetByHashAndStatus(
    String hash,
    SyncStatus status,
  ) {
    _log.fine(
      'Getting first asset by hash "$hash" and status "${status.name}"',
    );
    return (select(mediaAssets)
          ..where(
            (tbl) =>
                tbl.contentHash.equals(hash) &
                tbl.syncStatus.equals(status.name),
          )
          ..limit(1))
        .getSingleOrNull();
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
