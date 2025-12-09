// lib/core/cache/custom_image_cache.dart

import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/features/media_loading/providers/local_full_provider.dart';
import 'package:prismbox/features/media_loading/providers/remote_full_provider.dart';
import 'package:prismbox/features/media_loading/thumbhash/thumbhash_provider.dart';

/// 自定义图片缓存
/// 实现三级缓存分离：ThumbHash、小图、大图
/// 防止大图驱逐小图，优化内存使用
final class CustomImageCache implements ImageCache {
  final Logger _log = Logger('CustomImageCache');

  /// ThumbHash 缓存（临时存储，无限制）
  final ImageCache _thumbhash = ImageCache()..maximumSize = 0;

  /// 小图缓存（用于缩略图）
  final ImageCache _small = ImageCache();

  /// 大图缓存（用于完整图，最多 5 张）
  final ImageCache _large = ImageCache()..maximumSize = 5;

  /// 根据 Provider 类型路由到对应的缓存池
  ImageCache _getCacheForKey(Object key) {
    if (key is ThumbHashProvider) {
      return _thumbhash;
    }
    if (key is LocalFullImageProvider || key is RemoteFullImageProvider) {
      return _large;
    }
    return _small;
  }

  @override
  int get maximumSize => _small.maximumSize + _large.maximumSize;

  @override
  int get maximumSizeBytes => _small.maximumSizeBytes + _large.maximumSizeBytes;

  @override
  set maximumSize(int value) => _small.maximumSize = value;

  @override
  set maximumSizeBytes(int value) => _small.maximumSizeBytes = value;

  @override
  bool containsKey(Object key) => _getCacheForKey(key).containsKey(key);

  @override
  bool evict(Object key, {bool includeLive = true}) => _getCacheForKey(key).evict(key, includeLive: includeLive);

  @override
  ImageStreamCompleter? putIfAbsent(
    Object key,
    ImageStreamCompleter Function() loader, {
    ImageErrorListener? onError,
  }) => _getCacheForKey(key).putIfAbsent(key, loader, onError: onError);

  @override
  ImageCacheStatus statusForKey(Object key) => _getCacheForKey(key).statusForKey(key);

  @override
  int get liveImageCount => _thumbhash.liveImageCount + _small.liveImageCount + _large.liveImageCount;

  @override
  int get pendingImageCount => _thumbhash.pendingImageCount + _small.pendingImageCount + _large.pendingImageCount;

  @override
  void clear() {
    _thumbhash.clear();
    _small.clear();
    _large.clear();
    _log.info('CustomImageCache cleared');
  }

  @override
  void clearLiveImages() {
    _thumbhash.clearLiveImages();
    _small.clearLiveImages();
    _large.clearLiveImages();
  }

  /// 清理大图缓存
  void evictLargeImages() {
    _large.clear();
    _log.info('Large images cache cleared');
  }

  /// 清理小图缓存
  void evictSmallImages() {
    _small.clear();
    _log.info('Small images cache cleared');
  }

  /// 处理内存压力
  void handleMemoryPressure() {
    _large.clear();
    _small.clearLiveImages();
    _log.warning('Memory pressure handled: cleared large images and live small images');
  }

  @override
  int get currentSize => _thumbhash.currentSize + _small.currentSize + _large.currentSize;

  @override
  int get currentSizeBytes =>
      _thumbhash.currentSizeBytes + _small.currentSizeBytes + _large.currentSizeBytes;
}

