// lib/features/background_jobs/impl/media_sync/handlers/asset_action_handler.dart

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/models/sync_models.dart'
    hide SyncStatus;
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/extensions/asset_type_extensions.dart';
import 'package:mobile/utils/hash.dart';

@lazySingleton
class AssetChangeExecutor {
  // ignore: unused_field
  final AppDatabase _db;
  final MediaAssetDao _mediaAssetDao;
  final _log = Logger('AssetChangeExecutor');

  AssetChangeExecutor(this._db) : _mediaAssetDao = _db.mediaAssetDao;

  /// --------------------------------------------------------------------------
  /// 处理本地新增的媒体资源
  /// ---------------------------------------------------------------------------

  /// 批量处理一组新增的本地媒体ID。
  /// 此方法是并发安全的，可以同时处理多个ID。
  Future<void> handleNewLocalAssets(Set<String> assetIds) async {
    _log.info('Handling ${assetIds.length} new local assets.');
    await _processInBatches(assetIds, _processSingleNewAsset);
  }

  /// 处理单个新增的本地媒体资源。
  /// 此方法严格遵循以下优先级规则：
  /// 1. 如果存在相同 localId 的记录，则跳过。
  /// 2. 如果不存在相同 localId，但存在相同哈希值且状态为“仅云端”的记录，则关联该记录并更新。
  /// 3. 如果以上条件都不满足，则作为新记录插入。
  Future<void> _processSingleNewAsset(String assetId) async {
    _log.fine('Processing new asset with local ID: $assetId');
    try {
      // 规则 1: 检查是否存在同样 localId 的记录，如果存在则跳过
      final existingByLocalId = await _mediaAssetDao.getAssetByLocalId(assetId);
      if (existingByLocalId != null) {
        _log.info(
          'Rule 1: Asset with local ID $assetId already exists in DB. Skipping.',
        );
        return;
      }

      // 获取 AssetEntity 并计算文件哈希
      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) {
        _log.warning(
          'Could not find AssetEntity for ID: $assetId. It might have been deleted.',
        );
        return;
      }

      final isRaw = await isRawFile(asset);

      final file = await asset.originFile;
      final contentHash = await calculateFileHash(file!);

      // 规则 2: 直接查询是否存在同样 hash 值的“仅云端”记录
      final cloudOnlyMatch = await _mediaAssetDao.getFirstAssetByHashAndStatus(
        contentHash,
        SyncStatus.cloudOnly,
      );

      if (cloudOnlyMatch != null) {
        // 如果找到，则关联这条记录并更新
        _log.info(
          'Rule 2: Found a cloud-only record (ID: ${cloudOnlyMatch.id}) with hash $contentHash. Associating with local asset $assetId.',
        );
        final file = await asset.originFile;
        if (file == null) {
          _log.warning(
            "Cannot get file path for asset: ${asset.id} for association. Skipping.",
          );
          return;
        }

        final companion = MediaAssetsCompanion(
          id: Value(cloudOnlyMatch.id),
          localId: Value(assetId),
          filePath: Value(file.path),
          isRAW: Value(isRaw),
          syncStatus: const Value(SyncStatus.synced), // 状态更新为已同步
          updatedAt: Value(DateTime.now()),
        );
        await _mediaAssetDao.updateAsset(companion);
        _log.info(
          'Successfully associated local asset $assetId with record ${cloudOnlyMatch.id}.',
        );
        return;
      }

      // 规则 3: 如果以上条件都不满足，则新增记录
      _log.info(
        'Rule 3: No existing localId or suitable hash found. Inserting as a new asset.',
      );
      final companion = await _assetEntityToCompanion(asset);
      if (companion == null) {
        _log.severe(
          'Failed to create companion for asset ${asset.id}. Skipping.',
        );
        return;
      }

      await _mediaAssetDao.insertMediaAsset(
        companion.copyWith(
          contentHash: Value(contentHash),
          syncStatus: const Value(SyncStatus.localOnly),
          isRAW: Value(isRaw),
        ),
      );
      _log.info('Successfully inserted new asset with local ID: ${asset.id}');
    } catch (e, s) {
      _log.severe('Error processing new asset ID $assetId.', e, s);
    }
  }

  /// ---------------------------------------------------------------------------
  /// 处理本地删除的媒体资源
  /// ---------------------------------------------------------------------------

  /// 批量处理一组被删除的本地媒体ID。
  Future<void> handleDeletedLocalAssets(Set<String> assetIds) async {
    _log.info('Handling ${assetIds.length} deleted local assets.');
    await _processInBatches(assetIds, _processSingleDeletedAsset);
  }

  Future<void> _processSingleDeletedAsset(String localId) async {
    final asset = await _mediaAssetDao.getAssetByLocalId(localId);

    if (asset == null) {
      _log.warning(
        'Tried to process deletion for local asset $localId, but it was not found in the DB.',
      );
      return;
    }

    // 检查资产是否已与云端同步或正在同步
    final bool isCloudAsset =
        asset.syncStatus == SyncStatus.synced ||
        asset.syncStatus == SyncStatus.uploading;

    if (isCloudAsset) {
      // 如果资产已同步到云端，则更新其状态为仅云端，并移除本地信息
      _log.info(
        'Local asset $localId deleted, but it is synced. Transitioning to cloud-only state.',
      );
      await _mediaAssetDao.transitionToCloudOnly(asset.id);
    } else {
      // 如果资产仅存在于本地，则直接从数据库中删除
      _log.info(
        'Local asset $localId deleted. It was local-only, so deleting from DB.',
      );
      await _mediaAssetDao.deleteLocalOnlyAsset(asset.id);
    }
  }

  /// ---------------------------------------------------------------------------
  /// 处理云端变更
  /// ---------------------------------------------------------------------------

  /// 应用来自云端的变更集。
  /// This is a wrapper around the DAO's method. The original logic was in `SyncJobProcessor`.
  Future<void> handleCloudChanges(CloudSyncResult result) async {
    _log.info(
      'Applying cloud changes. Upserts: ${result.toUpsert.length}, Deletes: ${result.uuidsToDelete.length}.',
    );
    await _mediaAssetDao.applyCloudChanges(
      toUpsert: result.toUpsert,
      uuidsToDelete: result.uuidsToDelete,
    );
  }

  /// Logic migrated from `SyncJobManager._assetEntityToCompanion`.
  Future<MediaAssetsCompanion?> _assetEntityToCompanion(
    AssetEntity asset,
  ) async {
    final File? file = await asset.originFile;
    if (file == null) {
      _log.warning("Cannot get file path for asset: ${asset.id}");
      return null;
    }
    return MediaAssetsCompanion.insert(
      localId: Value(asset.id),
      syncStatus: SyncStatus.localOnly,
      // Default status is set by the calling method
      assetType: asset.type.toMediaType(),
      filePath: Value(file.path),
      fileName: Value(p.basename(file.path)),
      width: Value(asset.width),
      height: Value(asset.height),
      durationSec: Value(asset.duration),
      createdAt: asset.createDateTime,
      updatedAt: DateTime.now(),
    );
  }

  /// Generic batch processing helper.
  /// Logic from `LocalMediaObserver._processInBatches`.
  Future<void> _processInBatches<T>(
    Iterable<T> items,
    Future<void> Function(T item) processFunction, {
    int batchSize = 10,
  }) async {
    final itemList = items.toList();
    for (int i = 0; i < itemList.length; i += batchSize) {
      final end = (i + batchSize < itemList.length)
          ? i + batchSize
          : itemList.length;
      final batch = itemList.sublist(i, end);
      await Future.wait(batch.map(processFunction));
      await Future.delayed(Duration.zero); // Yield to the event loop
    }
  }

  Future<bool> isRawFile(AssetEntity asset) async {
    String? mimeType = await asset.mimeTypeAsync; // 或者使用同步的 asset.mimeType
    if (mimeType == null) {
      return false;
    }

    // 常见的 RAW MIME 类型列表 (可根据需要扩展)
    const rawMimeTypes = [
      'image/dng',
      'image/x-adobe-dng',
      'image/x-canon-cr2',
      'image/x-canon-cr3',
      'image/x-nikon-nef',
      'image/x-sony-arw',
      'image/x-olympus-orf',
      'image/x-panasonic-rw2',
      'image/x-fuji-raf',
    ];

    return rawMimeTypes.contains(mimeType.toLowerCase());
  }
}
