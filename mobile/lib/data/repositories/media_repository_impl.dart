import 'dart:async';

import '../../domain/entities/unified_media_entity.dart';
import '../../domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/local_media_source.dart';
// import '../datasources/remote/cloud_media_datasource.dart'; // 为未来云端同步预留
import 'package:mobile/data/datasources/app_database.dart';

/// MediaRepository 的具体实现。
///
/// 它的职责是作为领域层和数据层之间的协调者。
/// 它从一个或多个数据源（本地、远程）获取数据，并将这些数据源特定的模型
/// （如 `MediaAsset`）转换为领域层统一的实体（`UnifiedMediaEntity`）。
class MediaRepositoryImpl implements MediaRepository {
  final LocalMediaDataSource _localDataSource;
  // final CloudMediaDataSource _cloudDataSource; // 预留
  final MediaAssetDao _mediaAssetDao;

  MediaRepositoryImpl({
    required LocalMediaDataSource localDataSource,
    // required CloudMediaDataSource cloudDataSource,
    required AppDatabase db,
  }) : _localDataSource = localDataSource,
       // _cloudDataSource = cloudDataSource,
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
}
