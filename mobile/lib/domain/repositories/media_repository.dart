// lib/domain/repositories/media_repository.dart

import 'dart:typed_data';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';

abstract class MediaRepository {
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  Future<void> createDownloadJob(UnifiedMediaEntity entity);

  Future<Uint8List> downloadThumbnail(String uuid);

  Future<Uint8List> downloadPreview(String uuid);

  Future<Set<String>> getAllSyncedLocalAssetIds();

  Future<void> updateMediaStatus(
    UnifiedMediaEntity entity,
    SyncStatus newStatus,
  );

  Stream<UnifiedMediaEntity> watchMediaEntity(int id);
}
