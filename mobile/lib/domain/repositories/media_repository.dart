// lib/domain/repositories/media_repository.dart

import 'dart:typed_data';
import 'package:mobile/domain/entities/unified_media_entity.dart';

abstract class MediaRepository {
  Stream<List<UnifiedMediaEntity>> getUnifiedMediaStream();

  Future<void> createDownloadJob(UnifiedMediaEntity entity);

  Future<Uint8List> downloadThumbnail(String uuid);
  Future<Uint8List> downloadPreview(String uuid);

  /// 获取数据库中存储的所有本地资产的 ID。
  /// 这些是应用认为已经处理过或已知的资产。
  Future<Set<String>> getAllSyncedLocalAssetIds();
}
