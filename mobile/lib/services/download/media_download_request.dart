// lib/services/download/media_download_request.dart

import 'package:prismbox/data/database/enums/media_download_source_type.dart';

/// 统一下载请求（照片页时间线资产 或 帖子媒体）
class MediaDownloadRequest {
  final String userId;
  final MediaDownloadSourceType sourceType;
  final String sourceId;
  final String mediaUuid;
  final String? livePhotoVideoUuid;
  final String itemType; // 'IMAGE' | 'VIDEO'
  final String filename;

  const MediaDownloadRequest({
    required this.userId,
    required this.sourceType,
    required this.sourceId,
    required this.mediaUuid,
    this.livePhotoVideoUuid,
    required this.itemType,
    required this.filename,
  });
}
