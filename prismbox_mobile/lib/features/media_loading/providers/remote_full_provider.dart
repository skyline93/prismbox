// lib/features/media_loading/providers/remote_full_provider.dart

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/remote_image_cache_manager.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/features/media_loading/loaders/image_loader.dart';
import 'package:prismbox/features/media_loading/mixins/cancellable_image_provider_mixin.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 远程原图提供者
/// 用于加载远程资源的预览图或原图
class RemoteFullImageProvider extends ImageProvider<RemoteFullImageProvider>
    with CancellableImageProviderMixin {
  /// 资产 ID
  final String assetId;
  
  /// 目标尺寸（可选）
  final Size? targetSize;
  
  /// 服务器 URL（可选）
  final String? serverUrl;
  
  /// 是否加载原图
  final bool loadOriginal;
  
  /// 缓存管理器（可选）
  final CacheManager? cacheManager;
  
  /// API 服务（用于构建 URL）
  final ApiService? apiService;

  final Logger _log = Logger('RemoteFullImageProvider');

  RemoteFullImageProvider({
    required this.assetId,
    this.targetSize,
    this.serverUrl,
    this.loadOriginal = false,
    this.cacheManager,
    this.apiService,
  });

  @override
  Future<RemoteFullImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    RemoteFullImageProvider key,
    ImageDecoderCallback decode,
  ) {
    // 重置取消状态
    reset();
    
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiImageStreamCompleter(
      codec: _loadImage(key, decode, chunkEvents),
      scale: 1.0,
      chunkEvents: chunkEvents.stream,
    );
  }

  /// 加载图片（支持渐进式加载）
  Stream<ui.Codec> _loadImage(
    RemoteFullImageProvider key,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async* {
    // 检查是否已取消
    checkCancelled();
    
    try {
      final cacheManager = key.cacheManager ?? RemoteImageCacheManager();
      final shouldLoadOriginal = key.loadOriginal || AppSetting.get(Setting.loadOriginal);

      // 阶段 1：加载预览图
      final previewUrl = _buildPreviewUrl(key);
      _log.fine('Loading preview: $previewUrl');

      final previewCodec = await _loadFromUrl(previewUrl, cacheManager, decode, chunkEvents);
      checkCancelled();
      yield previewCodec;

      // 阶段 2：如果需要，加载原图
      if (shouldLoadOriginal) {
        checkCancelled();
        final originalUrl = _buildOriginalUrl(key);
        _log.fine('Loading original: $originalUrl');

        final originalCodec = await _loadFromUrl(originalUrl, cacheManager, decode, chunkEvents);
        checkCancelled();
        yield originalCodec;
      }
    } on CancelledException {
      _log.fine('Full image loading cancelled: ${key.assetId}');
      rethrow;
    } catch (e, stackTrace) {
      _log.severe('Failed to load remote full image', e, stackTrace);
      rethrow;
    }
  }

  /// 从 URL 加载图片
  Future<ui.Codec> _loadFromUrl(
    String url,
    CacheManager cacheManager,
    ImageDecoderCallback decode,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    // 使用 ImageLoader 加载图片
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
  }

  /// 构建预览图 URL
  String _buildPreviewUrl(RemoteFullImageProvider key) {
    final baseUrl = key.serverUrl ?? '';
    return '$baseUrl/assets/${key.assetId}/thumbnail?size=preview';
  }

  /// 构建原图 URL
  String _buildOriginalUrl(RemoteFullImageProvider key) {
    final baseUrl = key.serverUrl ?? '';
    return '$baseUrl/assets/${key.assetId}/original';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteFullImageProvider &&
          runtimeType == other.runtimeType &&
          assetId == other.assetId &&
          targetSize == other.targetSize &&
          serverUrl == other.serverUrl &&
          loadOriginal == other.loadOriginal;

  @override
  int get hashCode => Object.hash(assetId, targetSize, serverUrl, loadOriginal);
}

/// 多图片流完成器
/// 支持渐进式加载：先显示预览图，再显示原图
class MultiImageStreamCompleter extends ImageStreamCompleter {
  final Stream<ui.Codec> codec;
  final Stream<ImageChunkEvent>? chunkEvents;
  bool _isDisposed = false;

  MultiImageStreamCompleter({
    required this.codec,
    required double scale,
    this.chunkEvents,
  }) : super() {
    _loadImages();
  }

  void _loadImages() async {
    try {
      await for (final codec in codec) {
        if (_isDisposed) {
          codec.dispose();
          continue;
        }

        try {
          final frame = await codec.getNextFrame();
          if (!_isDisposed) {
            setImage(ImageInfo(image: frame.image, scale: 1.0));
          }
        } catch (e) {
          if (!_isDisposed) {
            reportError(
              exception: e,
              stack: StackTrace.current,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        reportError(exception: e, stack: stackTrace);
      }
    }
  }

  void dispose() {
    _isDisposed = true;
  }
}

