// lib/domain/repositories/media_repository.dart

import 'dart:typed_data';
import 'package:mobile/domain/entities/unified_media_entity.dart';

abstract class MediaRepository {
  /// Watches the local database and provides a continuous stream of all media assets.
  /// This is the primary method for the UI to get data.
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  /// Creates a job to download the original version of a cloud-only media asset.
  /// This method returns immediately and does not wait for the download to complete.
  Future<void> createDownloadJob(UnifiedMediaEntity entity);

  // --- Low-level data fetching methods, potentially for specific UI needs ---

  Future<Uint8List> downloadThumbnail(String uuid);
  Future<Uint8List> downloadPreview(String uuid);
}
