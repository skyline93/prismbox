// lib/services/sync_job_manager.dart

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:path/path.dart' as p;
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/services/background_service_manager.dart';

@lazySingleton
class SyncJobManager {
  final AppDatabase _db;
  final MediaAssetDao _mediaAssetDao;
  final SyncJobDao _syncJobDao;

  SyncJobManager(this._db)
    : _mediaAssetDao = _db.mediaAssetDao,
      _syncJobDao = _db.syncJobDao;

  /// 为新发现的本地媒体资产创建记录和上传任务。
  /// [isAutoBackupEnabled] 参数决定是否立即创建上传任务。
  Future<void> createUploadJobForNewAsset(
    AssetEntity asset, {
    required bool isAutoBackupEnabled,
  }) async {
    try {
      // 1. 防止重复处理
      final existingAsset = await (_mediaAssetDao.select(
        _mediaAssetDao.mediaAssets,
      )..where((tbl) => tbl.localId.equals(asset.id))).getSingleOrNull();

      if (existingAsset != null) {
        // 如果资产已存在，无需任何操作
        return;
      }

      // 2. 将 AssetEntity 转换为数据库实体
      final companion = await _assetEntityToCompanion(asset);
      if (companion == null) {
        print('[SyncJobManager] 无法处理资产 ${asset.id}，跳过。');
        return;
      }

      // 3. 将新资产插入数据库
      final newDbId = await _mediaAssetDao.insertMediaAsset(
        companion.copyWith(
          // 如果自动备份开启，乐观地将状态设置为 uploading
          syncStatus: Value(
            isAutoBackupEnabled
                ? SyncStatus.uploading
                : SyncStatus.localOnlyNotSelected,
          ),
        ),
      );

      // 4. 如果用户开启了自动备份，则创建上传任务
      if (isAutoBackupEnabled) {
        await _syncJobDao
            .into(_syncJobDao.syncJobs)
            .insert(
              SyncJobsCompanion.insert(
                assetId: newDbId,
                jobType: JobType.UPLOAD,
                status: JobStatus.pending,
                priority: Value(1), // 新增上传任务优先级较高
              ),
            );
        print('[SyncJobManager] 已为新资产 ${asset.id} 创建上传任务。');
        // [+] 关键修复：立即触发后台任务处理器
        BackgroundServiceManager.triggerImmediateSync();
      } else {
        print('[SyncJobManager] 已为新资产 ${asset.id} 创建本地记录。');
      }
    } catch (e, s) {
      print('[SyncJobManager] 创建上传任务时出错: $e');
      print(s);
    }
  }

  /// 处理本地媒体被删除的事件。
  Future<void> handleLocalAssetDeletion(String localId) async {
    final assetToDelete = await (_mediaAssetDao.select(
      _mediaAssetDao.mediaAssets,
    )..where((tbl) => tbl.localId.equals(localId))).getSingleOrNull();

    if (assetToDelete != null) {
      print('[SyncJobManager] 本地资产 $localId 已被删除，执行乐观删除...');
      // 调用 DAO 中已有的乐观删除逻辑
      await _mediaAssetDao.performOptimisticDelete(assetToDelete);

      // [+] 关键修复：创建删除任务后，立即触发后台任务处理器
      BackgroundServiceManager.triggerImmediateSync();
    }
  }

  /// 创建一个检查云端变更的“元任务”。
  /// 这个任务将被后台处理器消费，触发与云端的完整同步检查。
  Future<void> createCloudChangesSyncJob({int priority = 0}) async {
    // 检查是否已有待处理的同类任务，避免短时间内重复创建
    final existingJob =
        await (_syncJobDao.select(_syncJobDao.syncJobs)..where(
              (tbl) =>
                  tbl.jobType.equalsValue(JobType.SYNC_CLOUD_CHANGES) &
                  tbl.status.equalsValue(JobStatus.pending),
            ))
            .getSingleOrNull();

    if (existingJob != null) {
      print('[SyncJobManager] 已存在待处理的云端同步任务，跳过创建。');
      return;
    }

    // --- 关键架构注意点 ---
    // 当前 SyncJobs.assetId 是一个指向 MediaAssets.id 的非空外键。
    // 而 SYNC_CLOUD_CHANGES 任务本身不与任何特定资产关联。
    // 为了满足外键约束，我们插入一个特殊的“虚拟”资产。
    // **长期建议**: 修改 SyncJobs 表，允许 assetId 为 NULL，这样更符合逻辑。
    // 在此之前，我们使用以下 workaround：
    final virtualAssetId = await _mediaAssetDao
        .into(_mediaAssetDao.mediaAssets)
        .insert(
          MediaAssetsCompanion.insert(
            syncStatus: SyncStatus.synced, // 表示它不是一个真实的用户媒体
            assetType: MediaType.image,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            fileName: Value('__VIRTUAL_SYNC_ASSET__'),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    await _syncJobDao
        .into(_syncJobDao.syncJobs)
        .insert(
          SyncJobsCompanion.insert(
            assetId: virtualAssetId,
            jobType: JobType.SYNC_CLOUD_CHANGES,
            status: JobStatus.pending,
            priority: Value(priority),
          ),
        );
    print('[SyncJobManager] 已创建检查云端变更的任务。');

    // [+] 关键修复：立即触发后台任务处理器
    BackgroundServiceManager.triggerImmediateSync();
  }

  // =======================================================================
  // [+] 新增方法：创建下载原始文件的任务
  // =======================================================================
  /// 为一个云端媒体实体创建下载任务。
  /// 此方法会立即将媒体状态更新为 `downloading` 以便 UI 及时响应，
  /// 然后将实际的下载工作放入后台任务队列。
  Future<void> createDownloadJob(UnifiedMediaEntity entity) async {
    // 1. 检查是否已有待处理的下载任务，防止用户重复点击
    final existingJob =
        await (_syncJobDao.select(_syncJobDao.syncJobs)..where(
              (tbl) =>
                  tbl.assetId.equals(entity.id) &
                  tbl.jobType.equalsValue(JobType.DOWNLOAD_ORIGINAL) &
                  tbl.status.equalsValue(JobStatus.pending),
            ))
            .getSingleOrNull();

    if (existingJob != null) {
      print('[SyncJobManager] 资产 ${entity.id} 已存在待处理的下载任务，跳过。');
      return;
    }

    try {
      // 2. 使用事务确保原子性操作：先更新UI状态，再创建任务
      await _db.transaction(() async {
        // 2.1. 立即更新数据库中该资产的状态为 "下载中"
        // UI 会通过数据流立即收到这个变化，并显示下载中状态
        await _mediaAssetDao.updateAssetStatus(
          entity.id,
          SyncStatus.downloading,
        );

        // 2.2. 创建一个高优先级的下载任务
        await _syncJobDao
            .into(_syncJobDao.syncJobs)
            .insert(
              SyncJobsCompanion.insert(
                assetId: entity.id,
                jobType: JobType.DOWNLOAD_ORIGINAL,
                status: JobStatus.pending,
                priority: Value(10), // 用户主动触发的操作，优先级设高一些
              ),
            );
      });
      print('[SyncJobManager] 已为资产 ${entity.id} 创建下载任务。');

      // [+] 关键修复：在事务成功后，立即触发后台任务处理器
      BackgroundServiceManager.triggerImmediateSync();
    } catch (e, s) {
      print('[SyncJobManager] 创建下载任务时出错: $e');
      print(s);
      // 如果出错，回滚状态，避免UI卡在 "下载中"
      await _mediaAssetDao.updateAssetStatus(entity.id, SyncStatus.cloudOnly);
    }
  }

  /// 将 AssetEntity 转换为用于数据库插入的 MediaAssetsCompanion。
  /// 这是从旧的 LocalMediaDataSource 中提取并优化的逻辑。
  Future<MediaAssetsCompanion?> _assetEntityToCompanion(
    AssetEntity asset,
  ) async {
    final File? file = await asset.file;
    if (file == null) {
      print("[SyncJobManager] 警告: 无法获取资产文件路径: ${asset.id}");
      return null;
    }
    return MediaAssetsCompanion.insert(
      localId: Value(asset.id),
      syncStatus: SyncStatus.localOnlyNotSelected, // 初始状态
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
