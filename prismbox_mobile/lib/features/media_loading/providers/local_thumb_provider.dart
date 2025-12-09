// lib/features/media_loading/providers/local_thumb_provider.dart

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/features/media_loading/requests/local_image_request.dart';

/// 本地缩略图提供者
/// 用于加载本地资源的缩略图
class LocalThumbProvider extends ImageProvider<LocalThumbProvider> {
  /// photo_manager 的 AssetEntity
  final AssetEntity asset;
  
  /// 目标尺寸
  final Size size;
  
  /// 缓存管理器（可选）
  final ThumbnailImageCacheManager? cacheManager;
  
  /// 用户 ID（可选，用于多用户场景）
  final String? userId;
  
  /// 文件校验和（可选，用于检测文件变更）
  final String? checksum;

  LocalThumbProvider({
    required this.asset,
    required this.size,
    this.cacheManager,
    this.userId,
    this.checksum,
  });

  @override
  Future<LocalThumbProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    LocalThumbProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadThumbnail(key, decode),
      scale: 1.0,
    );
  }

  /// 加载缩略图
  /// 
  /// 使用 LocalImageRequest 处理加载逻辑，减少代码耦合
  Future<ui.Codec> _loadThumbnail(LocalThumbProvider key, ImageDecoderCallback decode) async {
    final request = LocalImageRequest(
      asset: key.asset,
      targetSize: key.size,
      cacheManager: key.cacheManager,
      userId: key.userId,
      checksum: key.checksum,
      isThumbnail: true,
    );
    
    return await request.load(decode);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalThumbProvider &&
          runtimeType == other.runtimeType &&
          asset.id == other.asset.id &&
          size == other.size &&
          userId == other.userId &&
          checksum == other.checksum;

  @override
  int get hashCode => Object.hash(asset.id, size, userId, checksum);
}

