// lib/domain/repositories/media_repository.dart

import 'dart:typed_data';
// import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

abstract class MediaRepository {
  Future<void> loadAndIndexLocalMedia();

  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  Future<void> syncWithCloud();

  Future<void> uploadLocalMedia(UnifiedMediaEntity entity);

  Future<UnifiedMediaEntity> downloadAndSaveOriginal(UnifiedMediaEntity entity);

  Future<Uint8List> downloadThumbnail(String uuid);

  Future<Uint8List> downloadPreview(String uuid);

  Future<Uint8List> downloadOrigin(String uuid);

  Future<MediaResponse> uploadMedia({
    required Uint8List file,
    required String hash,
    required MediaType itemType,
    String? originalFilename,
  });
}
