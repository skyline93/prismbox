import 'dart:async';
import 'package:drift/drift.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../domain/entities/unified_media_entity.dart';
import '../../domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
import 'package:mobile/data/datasources/remote_media_source.dart'; // 为未来云端同步预留
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/models/media/media_model.dart';

/// MediaRepository 的具体实现。
///
/// 它的职责是作为领域层和数据层之间的协调者。
/// 它从一个或多个数据源（本地、远程）获取数据，并将这些数据源特定的模型
/// （如 `MediaAsset`）转换为领域层统一的实体（`UnifiedMediaEntity`）。
class MediaRepositoryImpl implements MediaRepository {
  final LocalMediaDataSource _localDataSource;
  final RemoteMediaDataSource _cloudDataSource;
  final MediaAssetDao _mediaAssetDao;

  MediaRepositoryImpl({
    required LocalMediaDataSource localDataSource,
    required RemoteMediaDataSource cloudDataSource,
    required AppDatabase db,
  }) : _localDataSource = localDataSource,
       _cloudDataSource = cloudDataSource,
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

  /// **核心实现：使用 getChanges 接口与云端同步**
  @override
  Future<void> syncWithCloud() async {
    print("Repository: 开始执行云端同步...");
    try {
      // 1. 调用您封装好的 getChanges API
      final MediaChangesResponse changes = await _cloudDataSource.getChanges();

      // 2. 准备需要创建/更新的数据
      // 合并 'created' 和 'updated' 列表，因为对于本地数据库来说，它们都是 "Upsert" 操作。
      final List<MediaResponse> assetsToProcess = [
        ...changes.created,
        ...changes.updated,
      ];

      // 将云端 DTO (MediaResponse) 转换为本地数据库模型 (MediaAssetsCompanion)
      final List<MediaAssetsCompanion> companionsToUpsert = [];
      for (final mediaResponse in assetsToProcess) {
        companionsToUpsert.add(_convertMediaResponseToCompanion(mediaResponse));
      }

      // 3. 调用 DAO 的新方法，将所有变更在一个事务中应用
      await _mediaAssetDao.applyCloudChanges(
        toUpsert: companionsToUpsert,
        uuidsToDelete: changes.deleted,
      );

      print("Repository: 云端同步成功完成。");
    } catch (e) {
      // 将底层的异常继续向上抛出，由 ViewModel 层处理
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
}
