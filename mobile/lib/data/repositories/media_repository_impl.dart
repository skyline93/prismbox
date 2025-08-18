// lib/data/repositories/media_repository_impl.dart

import 'dart:async';
import 'dart:typed_data';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/repositories/media_repository.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/services/sync_job_manager.dart'; // [+] Import the SyncJobManager

class MediaRepositoryImpl implements MediaRepository {
  // --- Dependencies ---
  final RemoteMediaDataSource _cloudDataSource;
  final MediaAssetDao _mediaAssetDao;
  final SyncJobManager _syncJobManager; // [+] Add SyncJobManager

  MediaRepositoryImpl({
    required RemoteMediaDataSource cloudDataSource,
    required AppDatabase db,
    required SyncJobManager syncJobManager, // [+] Add to constructor
  }) : _cloudDataSource = cloudDataSource,
       _mediaAssetDao = db.mediaAssetDao,
       _syncJobManager = syncJobManager; // [+] Initialize it

  @override
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream() {
    // This remains the same, as it's the core of our reactive UI.
    return _mediaAssetDao.watchAllMediaAssets().map(
      (dbAssets) => dbAssets.map(UnifiedMediaEntity.fromDbModel).toList(),
    );
  }

  @override
  Future<void> createDownloadJob(UnifiedMediaEntity entity) async {
    // The new implementation. It's incredibly simple!
    // It just tells the SyncJobManager what to do and returns.
    return _syncJobManager.createDownloadJob(entity);
  }

  @override
  Future<Uint8List> downloadThumbnail(String uuid) async {
    // This can remain as it's a direct fetch for UI display.
    return _cloudDataSource.downloadThumbnail(uuid);
  }

  @override
  Future<Uint8List> downloadPreview(String uuid) async {
    // This can also remain for a similar reason.
    return _cloudDataSource.downloadPreviewMedia(uuid);
  }

  // NOTE: All other methods (syncWithCloud, uploadLocalMedia, downloadAndSaveOriginal, etc.)
  // have been completely removed from this file. Their logic now lives inside the
  // SyncJobProcessor and is triggered by jobs, not direct repository calls.
}
