// lib/data/repositories/media_repository_impl.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/services/sync_job_manager.dart';

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
    return _mediaAssetDao.watchAllMediaAssets().map(
      (dbAssets) {
        return dbAssets.map(UnifiedMediaEntity.fromDbModel).toList();
        },
    );
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
}
