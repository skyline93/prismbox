// lib/presentation/widgets/posts/post_media_image_provider.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/remote_image_cache_manager.dart';
import 'package:prismbox/features/media_loading/mixins/cancellable_image_provider_mixin.dart';
import 'package:prismbox/features/media_loading/providers/remote_full_provider.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 帖子媒体图片提供者
/// 用于加载帖子中的媒体图片，支持认证头
class PostMediaImageProvider extends ImageProvider<PostMediaImageProvider>
    with CancellableImageProviderMixin {
  /// 图片 URL
  final String url;

  /// 缓存管理器（可选）
  final CacheManager? cacheManager;

  final Logger _log = Logger('PostMediaImageProvider');

  PostMediaImageProvider({
    required this.url,
    this.cacheManager,
  });

  @override
  Future<PostMediaImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    PostMediaImageProvider key,
    ImageDecoderCallback decode,
  ) {
    // 重置取消状态
    reset();

    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiImageStreamCompleter(
      codec: _loadImageStream(key, decode, chunkEvents),
      scale: 1.0,
      chunkEvents: chunkEvents.stream,
    );
  }

  /// 加载图片流
  Stream<ui.Codec> _loadImageStream(
    PostMediaImageProvider key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async* {
    checkCancelled();

    try {
      // 使用缓存管理器加载
      final cacheManager = key.cacheManager ?? RemoteImageCacheManager();

      // 获取认证头
      final headers = await ApiService.getRequestHeaders();

      _log.fine('[PostMediaImageProvider] Loading image: ${key.url}');

      // 使用 getFileStream 加载图片（支持认证头）
      final stream = cacheManager.getFileStream(
        key.url,
        withProgress: true,
        headers: headers,
      );

      await for (final response in stream) {
        checkCancelled();

        if (response is DownloadProgress) {
          chunkEvents.add(
            ImageChunkEvent(
              cumulativeBytesLoaded: response.downloaded,
              expectedTotalBytes: response.totalSize,
            ),
          );
        } else if (response is FileInfo) {
          try {
            final buffer = await ui.ImmutableBuffer.fromFilePath(response.file.path);
            checkCancelled();
            final codec = await decode(buffer);
            _log.fine('[PostMediaImageProvider] Image loaded successfully: ${key.url}');
            yield codec;
            break; // 加载成功后退出
          } catch (e) {
            _log.warning('[PostMediaImageProvider] Failed to decode image: ${key.url}', e);
            rethrow;
          }
        }
      }
    } on CancelledException {
      _log.fine('[PostMediaImageProvider] Image loading cancelled: ${key.url}');
      rethrow;
    } catch (e, stackTrace) {
      _log.severe('[PostMediaImageProvider] Failed to load image: ${key.url}', e, stackTrace);
      rethrow;
    } finally {
      chunkEvents.close();
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostMediaImageProvider &&
          runtimeType == other.runtimeType &&
          url == other.url;

  @override
  int get hashCode => url.hashCode;
}

