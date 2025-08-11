// lib/data/repositories/media_repository_impl.dart

import 'dart:async';
import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../domain/entities/unified_media_entity.dart';
import '../../domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/data/datasources/remote_media_source.dart'; // 为未来云端同步预留
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/core/storage/sync_state_service.dart';

/// MediaRepository 的具体实现。
///
/// 它的职责是作为领域层和数据层之间的协调者。
/// 它从一个或多个数据源（本地、远程）获取数据，并将这些数据源特定的模型
/// （如 `MediaAsset`）转换为领域层统一的实体（`UnifiedMediaEntity`）。
class MediaRepositoryImpl implements MediaRepository {
  final LocalMediaDataSource _localDataSource;
  final RemoteMediaDataSource _cloudDataSource;
  final SyncStateService _syncStateService;
  final MediaAssetDao _mediaAssetDao;

  MediaRepositoryImpl({
    required LocalMediaDataSource localDataSource,
    required RemoteMediaDataSource cloudDataSource,
    required SyncStateService syncStateService,
    required AppDatabase db,
  }) : _localDataSource = localDataSource,
       _cloudDataSource = cloudDataSource,
       _syncStateService = syncStateService,
       _mediaAssetDao = db.mediaAssetDao;

  @override
  Future<void> loadAndIndexLocalMedia() {
    // 将具体的扫描和索引任务委托给专门的 LocalMediaDataSource。
    return _localDataSource.scanAndIndexLocalMedia();
  }

  @override
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream() {
    // 使用 Drift 强大的 `watch` 功能。每当 `mediaAssets` 表发生变化时，
    // 这个流就会自动触发并发出最新的数据列表。
    return _mediaAssetDao.watchAllMediaAssets().map((
      List<MediaAsset> dbAssets,
    ) {
      // **核心映射逻辑**
      // 在这里，我们将数据层的模型 List<MediaAsset> 转换为领域层的模型 List<UnifiedMediaEntity>。
      // ViewModel 将只接收到这个转换后的、干净的实体列表。
      return dbAssets
          .map((asset) => UnifiedMediaEntity.fromDbModel(asset))
          .toList();
    });
  }

  @override
  Future<void> syncWithCloud() async {
    print("Repository: 开始执行云端同步...");
    try {
      final lastSyncTimestamp = await _syncStateService.getLastSyncTimestamp();

      if (lastSyncTimestamp == null) {
        print("Repository: 执行首次全量同步 (since is null)");
        // 在全量同步前，清空本地所有与云端相关的记录
        // 【修正】直接使用 _mediaAssetDao 来访问和操作 mediaAssets 表
        (_mediaAssetDao.delete(_mediaAssetDao.mediaAssets)).where(
          (tbl) =>
              tbl.syncStatus.isNotValue(SyncStatus.localOnlyNotSelected.name),
        );
        print("Repository: 已清空旧的云端数据，准备全量写入。");
      } else {
        print("Repository: 执行增量同步，since: $lastSyncTimestamp");
      }

      // 【修正】使用正确的成员变量名 _cloudDataSource
      final MediaChangesResponse changes = await _cloudDataSource.getChanges(
        since: lastSyncTimestamp,
      );

      // 将 'created' 和 'updated' 合并处理
      final List<MediaResponse> assetsToProcess = [
        ...changes.created,
        ...changes.updated,
      ];

      // 调用辅助方法将 DTO 列表转换为数据库 Companion 列表
      final List<MediaAssetsCompanion> companionsToUpsert = assetsToProcess
          .map((res) => _convertMediaResponseToCompanion(res))
          .toList();

      // 调用 DAO 将所有变更在一个事务中应用
      // 【修正】直接使用 _mediaAssetDao
      await _mediaAssetDao.applyCloudChanges(
        toUpsert: companionsToUpsert,
        uuidsToDelete: changes.deleted,
      );

      // 同步成功后，更新时间戳
      await _syncStateService.setLastSyncTimestamp(DateTime.now());

      print("Repository: 云端同步成功完成，并已更新同步时间戳。");
    } catch (e) {
      print("Repository: 云端同步失败 - $e");
      rethrow;
    }
  }

  /// 私有辅助方法，用于将云端数据模型转换为本地数据库模型。
  /// 这种转换是 Repository 层的核心职责之一。
  MediaAssetsCompanion _convertMediaResponseToCompanion(
    MediaResponse response,
  ) {
    // 处理从 String 到 Enum 的转换
    final assetType = response.itemType.toUpperCase() == AssetType.video
        ? MediaType.video
        : MediaType.image;

    // 从云端拉取的数据，我们默认其状态为 'cloudOnly'。
    // 如果本地已有文件，后续的 hash 检查和状态更新流程会将其变为 'synced'。
    // 但对于纯元数据同步，'cloudOnly' 是最安全和正确的初始状态。
    final status = SyncStatus.cloudOnly;

    return MediaAssetsCompanion(
      cloudUuid: Value(response.uuid),
      assetType: Value(assetType),
      syncStatus: Value(status),
      // 注意：您的 MediaResponse 模型中没有 width, height, hash 等信息。
      // 在这个场景下这是可以接受的，因为这些详细信息可以在用户查看单张图片时再去拉取和填充。
      // 如果列表接口能提供这些信息，可以在这里添加。
      createdAt: Value(
        DateTime.tryParse(response.mediaTakenAt ?? response.createdAt) ??
            DateTime.now(),
      ),
      updatedAt: Value(DateTime.now()),
    );
  }

  @override
  Future<Uint8List> downloadThumbnail(String uuid) async {
    return await _cloudDataSource.downloadThumbnail(uuid);
  }
}
