// lib/core/cache/thumbnail_cache_manager.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';

/// 缩略图缓存管理器
/// 用于存储远程缩略图和本地生成的缩略图
/// 配置：最多 5000 个对象，30 天过期
class ThumbnailImageCacheManager extends CacheManager {
  static const key = 'thumbnail-cache';
  static const maxNrOfCacheObjects = 5000;
  static const stalePeriod = Duration(days: 30);

  final Logger _log = Logger('ThumbnailImageCacheManager');

  ThumbnailImageCacheManager()
      : super(
          Config(
            key,
            maxNrOfCacheObjects: maxNrOfCacheObjects,
            stalePeriod: stalePeriod,
          ),
        );

  /// 定期清理过期缓存
  Future<void> cleanExpiredCache() async {
    await emptyCache();
    _log.info('Thumbnail cache cleaned');
  }
}

