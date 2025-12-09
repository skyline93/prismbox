// lib/features/media_loading/providers/remote_thumb_provider.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/features/media_loading/exceptions/network_image_exception.dart';
import 'package:prismbox/features/media_loading/loaders/image_loader.dart';
import 'package:prismbox/features/media_loading/mixins/cancellable_image_provider_mixin.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 远程缩略图提供者
/// 用于加载远程资源的缩略图
class RemoteThumbProvider extends ImageProvider<RemoteThumbProvider>
    with CancellableImageProviderMixin {
  /// 资产 ID
  final String assetId;
  
  /// 目标尺寸
  final Size size;
  
  /// 服务器 URL（可选）
  final String? serverUrl;
  
  /// 缓存管理器（可选）
  final CacheManager? cacheManager;
  
  /// API 服务（用于构建 URL）
  final ApiService? apiService;

  final Logger _log = Logger('RemoteThumbProvider');

  RemoteThumbProvider({
    required this.assetId,
    required this.size,
    this.serverUrl,
    this.cacheManager,
    this.apiService,
  });

  @override
  Future<RemoteThumbProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    RemoteThumbProvider key,
    ImageDecoderCallback decode,
  ) {
    // 重置取消状态
    reset();
    
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadThumbnail(key, decode, chunkEvents),
      scale: 1.0,
      chunkEvents: chunkEvents.stream,
    );
  }

  /// 加载缩略图
  Future<ui.Codec> _loadThumbnail(
    RemoteThumbProvider key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    // 检查是否已取消
    checkCancelled();
    
    try {
      // 构建 URL
      final url = _buildUrl(key);
      
      // 使用缓存管理器加载
      final cacheManager = key.cacheManager ?? ThumbnailImageCacheManager();
      
      // 检查磁盘缓存（使用 ImageLoader）
      final cachedCodec = await ImageLoader.loadImageFromCache(url, cacheManager, decode);
      if (cachedCodec != null) {
        checkCancelled();
        return cachedCodec;
      }

      // 从网络下载（使用 ImageLoader）
      return await ImageLoader.loadImage(
        url,
        cacheManager,
        decode,
        onProgress: (downloaded, total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: downloaded,
            expectedTotalBytes: total,
          ));
        },
        onCancel: () => isCancelled,
        onSubscription: (subscription) {
          setCurrentSubscription(subscription);
        },
        fallbackToExpiredCache: true,
      );
    } on CancelledException {
      _log.fine('Thumbnail loading cancelled: ${_buildUrl(key)}');
      rethrow;
    } catch (e, stackTrace) {
      // 如果是网络错误，尝试回退到缓存（即使过期）
      if (e is NetworkImageException) {
        try {
          final url = _buildUrl(key);
          final cacheManager = key.cacheManager ?? ThumbnailImageCacheManager();
          final cachedFile = await cacheManager.getFileFromCache(url);
          if (cachedFile != null) {
            _log.info('Network error, using expired cache: $url');
            checkCancelled();
            try {
              final buffer = await ui.ImmutableBuffer.fromFilePath(cachedFile.file.path);
              checkCancelled();
              return await decode(buffer);
            } catch (decodeError) {
              _log.warning('Failed to decode expired cache', decodeError);
              // 继续抛出原始网络错误
            }
          }
        } catch (_) {
          // 忽略缓存回退失败
        }
      }
      
      _log.severe('Failed to load remote thumbnail', e, stackTrace);
      rethrow;
    }
  }

  /// 构建缩略图 URL
  String _buildUrl(RemoteThumbProvider key) {
    final baseUrl = key.serverUrl ?? '';
    final size = '${key.size.width.toInt()}x${key.size.height.toInt()}';
    return '$baseUrl/assets/${key.assetId}/thumbnail?size=$size';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteThumbProvider &&
          runtimeType == other.runtimeType &&
          assetId == other.assetId &&
          size == other.size &&
          serverUrl == other.serverUrl;

  @override
  int get hashCode => Object.hash(assetId, size, serverUrl);
}

