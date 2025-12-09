// lib/core/cache/remote_image_cache_manager.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';

/// 远程图片缓存管理器
/// 用于存储远程预览图和原图
/// 配置：最多 500 个对象，30 天过期
class RemoteImageCacheManager extends CacheManager {
  static const key = 'remote-image-cache';
  static const maxNrOfCacheObjects = 500;
  static const stalePeriod = Duration(days: 30);

  final Logger _log = Logger('RemoteImageCacheManager');

  RemoteImageCacheManager()
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
    _log.info('Remote image cache cleaned');
  }
}

