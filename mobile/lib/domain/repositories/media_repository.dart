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

  /// 根据资源的状态（本地、云端、已同步）将其移至回收站或标记为已删除。
  ///
  /// 此方法会处理所有删除逻辑，包括：
  /// - 仅本地资源：移动本地文件到应用回收站，并更新数据库状态。
  /// - 仅云端资源：调用云端删除接口，并更新本地数据库记录状态。
  /// - 已同步资源：先调用云端删除，成功后再处理本地文件和数据库状态。
  Future<void> deleteAssets(List<UnifiedMediaEntity> assets);

  /// 从应用回收站中恢复资源。
  Future<void> restoreAssetsFromTrash(List<UnifiedMediaEntity> assets);

  /// 永久删除资源，包括删除本地文件和数据库记录。
  Future<void> permanentlyDeleteAssets(List<UnifiedMediaEntity> assets);
}
