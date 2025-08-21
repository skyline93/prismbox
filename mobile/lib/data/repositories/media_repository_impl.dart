// lib/data/repositories/media_repository_impl.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:drift/drift.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/services/sync_job_manager.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';

@LazySingleton(as: MediaRepository)
class MediaRepositoryImpl implements MediaRepository {
  final RemoteMediaDataSource _cloudDataSource;
  final MediaAssetDao _mediaAssetDao;
  final SyncJobManager _syncJobManager;

  MediaRepositoryImpl({
    required RemoteMediaDataSource cloudDataSource,
    required AppDatabase db,
    required SyncJobManager syncJobManager,
  }) : _cloudDataSource = cloudDataSource,
       _mediaAssetDao = db.mediaAssetDao,
       _syncJobManager = syncJobManager;

  @override
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream() {
    return _mediaAssetDao.watchAllMediaAssets().map((dbAssets) {
      return dbAssets.map(UnifiedMediaEntity.fromDbModel).toList();
    });
  }

  @override
  Future<void> createDownloadJob(UnifiedMediaEntity entity) async {
    return _syncJobManager.createDownloadJob(entity);
  }

  @override
  Future<Uint8List> downloadThumbnail(String uuid) async {
    return _cloudDataSource.downloadThumbnail(uuid);
  }

  @override
  Future<Uint8List> downloadPreview(String uuid) async {
    return _cloudDataSource.downloadPreviewMedia(uuid);
  }

  @override
  Future<Set<String>> getAllSyncedLocalAssetIds() async {
    final idsList = await _mediaAssetDao.getAllLocalAssetIds();
    return idsList.toSet();
  }

  @override
  Future<void> updateMediaStatus(
    UnifiedMediaEntity entity,
    SyncStatus newStatus,
  ) async {
    // 使用 Drift 的 Companion 对象来更新特定字段
    final companion = MediaAssetsCompanion(
      syncStatus: Value(newStatus), // 设置要更新的状态
    );

    // 调用 DAO 的更新方法，通过 id 定位到要更新的记录
    return _mediaAssetDao.updateMediaAsset(entity.id, companion);
  }

  @override
  Stream<UnifiedMediaEntity> watchMediaEntity(int id) {
    return _mediaAssetDao
        .watchMediaAssetById(id)
        .map((dbAsset) => UnifiedMediaEntity.fromDbModel(dbAsset));
  }
}
