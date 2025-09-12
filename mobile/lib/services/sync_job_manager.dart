// lib/services/sync_job_manager.dart

import 'dart:io';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/core/enums.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/services/background_service_manager.dart';

@lazySingleton
class SyncJobManager {
  // ignore: unused_field
  final AppDatabase _db;
  final MediaAssetDao _mediaAssetDao;
  final SyncJobDao _syncJobDao;

  SyncJobManager(this._db)
    : _mediaAssetDao = _db.mediaAssetDao,
      _syncJobDao = _db.syncJobDao;
  Future<void> createUploadJobForNewAsset(
    AssetEntity asset, {
    required bool isAutoBackupEnabled,
  }) async {
    try {
      final existingAsset = await _mediaAssetDao.getAssetByLocalId(asset.id);
      if (existingAsset != null) {
        if (existingAsset.contentHash == null) {
          final contentHash = await _calculateFileHash(asset);
          if (contentHash != null) {
            final companion = MediaAssetsCompanion(
              id: Value(existingAsset.id),
              contentHash: Value(contentHash),
            );
            await (_mediaAssetDao.update(_mediaAssetDao.mediaAssets)
                  ..where((tbl) => tbl.id.equals(existingAsset.id)))
                .write(companion);
          }
        }
        return;
      }

      final contentHash = await _calculateFileHash(asset);
      if (contentHash == null) {
        log('[SyncJobManager] 无法计算资产 ${asset.id} 的哈希值，跳过。');
        return;
      }

      final companion = await _assetEntityToCompanion(asset);
      if (companion == null) {
        log('[SyncJobManager] 无法处理资产 ${asset.id}，跳过。');
        return;
      }

      await _mediaAssetDao.insertMediaAsset(
        companion.copyWith(
          contentHash: Value(contentHash),
          syncStatus: Value(
            isAutoBackupEnabled
                ? SyncStatus.uploading
                : SyncStatus.localOnlyNotSelected,
          ),
        ),
      );

      if (isAutoBackupEnabled) {
        // TODO
      }
    } catch (e, s) {
      log('[SyncJobManager] 创建上传任务时出错', error: e, stackTrace: s);
    }
  }

  Future<String?> _calculateFileHash(AssetEntity asset) async {
    try {
      final File? file = await asset.originFile;

      if (file == null) {
        log('[SyncJobManager] 无法获取资产 ${asset.id} 的源文件。可能是网络或云端问题。');
        return null;
      }

      final stream = file.openRead();
      final hash = await sha256.bind(stream).first;
      return hash.toString();
    } catch (e, s) {
      // 捕获在下载或读取文件过程中可能发生的任何异常 (例如网络中断)。
      log(
        '[SyncJobManager] 在获取或哈希资产 ${asset.id} 的源文件时发生异常',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  Future<void> handleLocalAssetDeletion(String localId) async {
    final assetToDelete = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.localId.equals(localId))).getSingleOrNull();

    if (assetToDelete != null) {
      log('[SyncJobManager] 本地资产 $localId 已被删除，执行乐观删除...');
      await _mediaAssetDao.performOptimisticDelete(assetToDelete);

      BackgroundServiceManager.triggerImmediateSync();
    }
  }

  Future<void> createCloudChangesSyncJob({int priority = 0}) async {
    final existingJob =
        await (_syncJobDao.select(_syncJobDao.syncJobs)..where(
              (tbl) =>
                  tbl.jobType.equalsValue(JobType.syncCloudChanges) &
                  tbl.status.equalsValue(JobStatus.pending),
            ))
            .getSingleOrNull();

    if (existingJob != null) {
      log('[SyncJobManager] 已存在待处理的云端同步任务，跳过创建。');
      return;
    }

    await _syncJobDao
        .into(_syncJobDao.syncJobs)
        .insert(
          SyncJobsCompanion.insert(
            jobType: JobType.syncCloudChanges,
            status: JobStatus.pending,
            priority: Value(priority),
          ),
        );
    log('[SyncJobManager] 已创建检查云端变更的任务。');

    BackgroundServiceManager.triggerImmediateSync();
  }

  Future<MediaAssetsCompanion?> _assetEntityToCompanion(
    AssetEntity asset,
  ) async {
    final File? file = await asset.file;
    if (file == null) {
      log("[SyncJobManager] 警告: 无法获取资产文件路径: ${asset.id}");
      return null;
    }
    return MediaAssetsCompanion.insert(
      localId: Value(asset.id),
      syncStatus: SyncStatus.localOnlyNotSelected,
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
}
