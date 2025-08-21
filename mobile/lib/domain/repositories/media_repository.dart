// lib/domain/repositories/media_repository.dart

import 'dart:typed_data';
import 'package:mobile/domain/entities/unified_media_entity.dart';

abstract class MediaRepository {
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  Future<void> createDownloadJob(UnifiedMediaEntity entity);

  Future<Uint8List> downloadThumbnail(String uuid);

  Future<Uint8List> downloadPreview(String uuid);

  Future<Set<String>> getAllSyncedLocalAssetIds();
}
