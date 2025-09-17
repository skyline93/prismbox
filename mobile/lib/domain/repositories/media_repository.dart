// lib/domain/repositories/media_repository.dart

import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';

abstract class MediaRepository {
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  Future<Uint8List> downloadThumbnail(String uuid);

  Future<Uint8List> downloadPreview(String uuid);

  Stream<UnifiedMediaEntity> watchMediaEntity(int id);

  Stream<List<UnifiedAlbumEntity>> watchAlbums();

  Future<UnifiedMediaEntity?> getCoverForAlbum(UnifiedAlbumEntity album);

  Stream<List<UnifiedMediaEntity>> watchMediaFromAlbum(
    String albumId,
    AlbumSource source,
  );

  Future<UnifiedMediaEntity> uploadMedia(AssetEntity asset);

  Stream<List<UnifiedMediaEntity>> watchTrashedAssets();

  Future<void> moveAssetsToTrash(List<UnifiedMediaEntity> assets);

  Future<void> restoreAssetsFromTrash(List<UnifiedMediaEntity> assets);

  Future<void> permanentlyDeleteAssets(List<UnifiedMediaEntity> assets);
}
