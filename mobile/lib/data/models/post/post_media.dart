// lib/data/models/post/post_media.dart

/// 帖子媒体数据模型（仅用于 API 响应解析）
class PostMedia {
  final String uuid;
  final String? filename;
  final String? originalFilename;
  final String itemType; // 'IMAGE' or 'VIDEO'
  final String? hash;
  final int? width;
  final int? height;
  final String? createdAt;
  final String? updatedAt;
  final String? mediaTakenAt;
  final String? thumbnailUrl;
  final String? previewUrl;
  final String? downloadUrl;
  /// Live Photo 关联视频的 media UUID（后端返回 live_photo_video_id）
  final String? livePhotoVideoId;

  PostMedia({
    required this.uuid,
    this.filename,
    this.originalFilename,
    required this.itemType,
    this.hash,
    this.width,
    this.height,
    this.createdAt,
    this.updatedAt,
    this.mediaTakenAt,
    this.thumbnailUrl,
    this.previewUrl,
    this.downloadUrl,
    this.livePhotoVideoId,
  });

  factory PostMedia.fromJson(Map<String, dynamic> json) {
    return PostMedia(
      uuid: json['uuid'] as String,
      filename: json['filename'] as String?,
      originalFilename: json['original_filename'] as String?,
      itemType: json['item_type'] as String,
      hash: json['hash'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      mediaTakenAt: json['media_taken_at'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      previewUrl: json['preview_url'] as String?,
      downloadUrl: json['download_url'] as String?,
      livePhotoVideoId: json['live_photo_video_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      if (filename != null) 'filename': filename,
      if (originalFilename != null) 'original_filename': originalFilename,
      'item_type': itemType,
      if (hash != null) 'hash': hash,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (mediaTakenAt != null) 'media_taken_at': mediaTakenAt,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (previewUrl != null) 'preview_url': previewUrl,
      if (downloadUrl != null) 'download_url': downloadUrl,
      if (livePhotoVideoId != null) 'live_photo_video_id': livePhotoVideoId,
    };
  }

  bool get isImage => itemType == 'IMAGE';
  bool get isVideo => itemType == 'VIDEO';
}

