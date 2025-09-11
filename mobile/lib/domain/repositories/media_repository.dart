// lib/domain/repositories/media_repository.dart

import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';

abstract class MediaRepository {
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  // Future<void> createDownloadJob(UnifiedMediaEntity entity);

  // Future<void> createUploadJobForExistingAsset(UnifiedMediaEntity entity);

  Future<Uint8List> downloadThumbnail(String uuid);

  Future<Uint8List> downloadPreview(String uuid);

  Future<Set<String>> getAllSyncedLocalAssetIds();

  Stream<UnifiedMediaEntity> watchMediaEntity(int id);

  Stream<List<UnifiedAlbumEntity>> watchAlbums();

  Future<List<UnifiedMediaEntity>> getMediaFromAlbum(
    String albumId,
    AlbumSource source,
  );

  Future<Uint8List?> getThumbnailForLocalAsset(String id);

  Future<UnifiedMediaEntity?> getCoverForAlbum(UnifiedAlbumEntity album);

  Stream<List<UnifiedMediaEntity>> watchMediaFromAlbum(
    String albumId,
    AlbumSource source,
  );

  /// 上传单个本地媒体资源。
  ///
  /// 这个方法会直接上传文件并返回包含服务器信息的完整领域实体，
  /// 适用于需要立即反馈的场景。
  ///
  /// @param asset 从 photo_manager 选择的资源。
  /// @return 上传成功后，包含云端UUID和其他元数据的 UnifiedMediaEntity。
  Future<UnifiedMediaEntity> uploadMedia(AssetEntity asset);
}
