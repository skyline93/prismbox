// lib/features/media_loading/providers/lazy_local_full_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:prismbox/core/cache/thumbnail_cache_manager.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/media_loading/providers/local_full_provider.dart';

/// 延迟加载的本地原图提供者
/// 当 LocalAsset 的 assetEntity 为 null 时使用
/// 在 loadImage 时使用 AssetEntityLoader 异步获取 AssetEntity，然后委托给 LocalFullImageProvider
class LazyLocalFullImageProvider extends ImageProvider<LazyLocalFullImageProvider> {
  /// 本地资产
  final LocalAsset asset;
  
  /// AssetEntity 加载器（用于延迟获取）
  final AssetEntityLoader assetEntityLoader;
  
  /// 目标尺寸（可选）
  final Size? targetSize;
  
  /// 缓存管理器（可选）
  final ThumbnailImageCacheManager? cacheManager;
  
  /// 用户 ID（可选）
  final String? userId;
  
  /// 是否加载原图（可选，如果为 true 则在渐进式加载的最后阶段加载原图）
  final bool loadOriginal;

  LazyLocalFullImageProvider({
    required this.asset,
    required this.assetEntityLoader,
    this.targetSize,
    this.cacheManager,
    this.userId,
    this.loadOriginal = false,
  });

  @override
  Future<LazyLocalFullImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    LazyLocalFullImageProvider key,
    ImageDecoderCallback decode,
  ) {
    // 使用自定义的 StreamCompleter，在 loadImage 时异步获取 AssetEntity
    return _LazyLocalFullImageStreamCompleter(
      key: key,
      decode: decode,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LazyLocalFullImageProvider &&
          runtimeType == other.runtimeType &&
          asset.id == other.asset.id &&
          targetSize == other.targetSize &&
          userId == other.userId &&
          loadOriginal == other.loadOriginal;

  @override
  int get hashCode => Object.hash(asset.id, targetSize, userId, loadOriginal);
}

/// 延迟加载的图片流完成器
/// 在 loadImage 时异步获取 AssetEntity，然后委托给 LocalFullImageProvider
class _LazyLocalFullImageStreamCompleter extends ImageStreamCompleter {
  final LazyLocalFullImageProvider key;
  final ImageDecoderCallback decode;
  bool _isDisposed = false;

  _LazyLocalFullImageStreamCompleter({
    required this.key,
    required this.decode,
  }) : super() {
    _loadImage();
  }

  void _loadImage() async {
    try {
      // 使用 AssetEntityLoader 异步获取 AssetEntity（支持缓存）
      final assetEntity = await key.assetEntityLoader.loadAsync(key.asset);
      
      if (_isDisposed) {
        return;
      }
      
      if (assetEntity == null) {
        throw Exception('Failed to load AssetEntity: ${key.asset.id}');
      }

      // 创建 LocalFullImageProvider 并加载图片
      final provider = LocalFullImageProvider(
        asset: assetEntity,
        targetSize: key.targetSize,
        cacheManager: key.cacheManager,
        userId: key.userId,
        checksum: key.asset.checksum,
        loadOriginal: key.loadOriginal,
      );

      // 加载图片
      final completer = provider.loadImage(provider, decode);
      
      // 监听图片加载事件
      completer.addListener(ImageStreamListener(
        (ImageInfo imageInfo, bool synchronousCall) {
          if (!_isDisposed) {
            setImage(imageInfo);
          }
        },
        onError: (exception, stackTrace) {
          if (!_isDisposed) {
            reportError(
              exception: exception,
              stack: stackTrace,
            );
          }
        },
      ));
    } catch (e, stackTrace) {
      if (!_isDisposed) {
        reportError(
          exception: e,
          stack: stackTrace,
        );
      }
    }
  }
}

