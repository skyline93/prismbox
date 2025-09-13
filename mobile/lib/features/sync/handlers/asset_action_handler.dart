// lib/features/sync/handlers/asset_action_handler.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/features/sync/models/sync_models.dart';
import 'package:path/path.dart' as p;
import 'package:photo_manager/photo_manager.dart';

@lazySingleton
class AssetActionHandler {
  // ignore: unused_field
  final AppDatabase _db;
  final MediaAssetDao _mediaAssetDao;
  final _log = Logger('AssetActionHandler');

  AssetActionHandler(this._db) : _mediaAssetDao = _db.mediaAssetDao;

  /// ---------------------------------------------------------------------------
  /// 处理本地新增的媒体资源
  /// ---------------------------------------------------------------------------

  /// 批量处理一组新增的本地媒体ID。
  /// 此方法是并发安全的，可以同时处理多个ID。
  Future<void> handleNewLocalAssets(Set<String> assetIds) async {
    _log.info('Handling ${assetIds.length} new local assets.');
    await _processInBatches(assetIds, _processSingleNewAsset);
  }

  /// 处理单个新增的本地媒体资源。
  /// Logic migrated and combined from:
  /// - `LocalMediaObserver._processNewAsset`
  /// - `SyncJobManager.createUploadJobForNewAsset`
  Future<void> _processSingleNewAsset(String assetId) async {
    _log.fine('Processing new asset with local ID: $assetId');
    try {
      // 1. 检查数据库中是否已存在记录
      final existingAsset = await _mediaAssetDao.getAssetByLocalId(assetId);
      if (existingAsset != null) {
        _log.warning(
          'Asset with local ID $assetId already exists in DB. Skipping.',
        );
        // 可选：未来可在此处添加哈希值校验和更新逻辑
        return;
      }

      final asset = await AssetEntity.fromId(assetId);
      if (asset == null) {
        _log.warning(
          'Could not find AssetEntity for ID: $assetId. It might have been deleted.',
        );
        return;
      }

      // 2. 计算文件哈希值
      final contentHash = await _calculateFileHash(asset);
      if (contentHash == null) {
        _log.severe(
          'Failed to calculate hash for asset ${asset.id}. Skipping.',
        );
        return;
      }

      // 3. 将 AssetEntity 转换为数据库 Companion 对象
      final companion = await _assetEntityToCompanion(asset);
      if (companion == null) {
        _log.severe(
          'Failed to create companion for asset ${asset.id}. Skipping.',
        );
        return;
      }

      // 4. 插入数据库
      await _mediaAssetDao.insertMediaAsset(
        companion.copyWith(
          contentHash: Value(contentHash),
          // 新发现的资产默认为 "仅本地" 状态
          syncStatus: const Value(SyncStatus.localOnlyNotSelected),
        ),
      );
      _log.info('Successfully processed and inserted new asset: ${asset.id}');
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

  /// ---------------------------------------------------------------------------
  /// 私有辅助方法
  /// ---------------------------------------------------------------------------

  /// Logic migrated from `SyncJobManager._calculateFileHash`.
  Future<String?> _calculateFileHash(AssetEntity asset) async {
    try {
      final File? file = await asset.originFile;
      if (file == null) {
        _log.warning('Failed to get originFile for asset ${asset.id}.');
        return null;
      }
      final stream = file.openRead();
      final hash = await sha256.bind(stream).first;
      return hash.toString();
    } catch (e, s) {
      _log.severe('Exception while hashing file for asset ${asset.id}.', e, s);
      return null;
    }
  }

  /// Logic migrated from `SyncJobManager._assetEntityToCompanion`.
  Future<MediaAssetsCompanion?> _assetEntityToCompanion(
    AssetEntity asset,
  ) async {
    final File? file = await asset.file;
    if (file == null) {
      _log.warning("Cannot get file path for asset: ${asset.id}");
      return null;
    }
    return MediaAssetsCompanion.insert(
      localId: Value(asset.id),
      syncStatus: SyncStatus.localOnlyNotSelected,
      // Default status is set by the calling method
      assetType: asset.type == AssetType.video
          ? MediaType.video
          : MediaType.image,
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
}
