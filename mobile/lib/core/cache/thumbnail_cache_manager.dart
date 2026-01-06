// lib/core/cache/thumbnail_cache_manager.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

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
            fileService: _ThumbnailAuthenticatedHttpFileService(),
          ),
        );

  /// 定期清理过期缓存
  Future<void> cleanExpiredCache() async {
    await emptyCache();
    _log.info('Thumbnail cache cleaned');
  }
}

/// 带认证头的 HTTP 文件服务（用于缩略图）
class _ThumbnailAuthenticatedHttpFileService extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    // 获取认证头
    final authHeaders = await ApiService.getRequestHeaders();
    
    // 合并传入的 headers 和认证头
    final mergedHeaders = <String, String>{
      ...authHeaders,
      if (headers != null) ...headers,
    };
    
    return super.get(url, headers: mergedHeaders);
  }
}

