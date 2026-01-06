// lib/core/cache/remote_image_cache_manager.dart

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

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
            fileService: _RemoteImageAuthenticatedHttpFileService(),
          ),
        );

  /// 定期清理过期缓存
  Future<void> cleanExpiredCache() async {
    await emptyCache();
    _log.info('Remote image cache cleaned');
  }
}

/// 带认证头的 HTTP 文件服务（用于远程图片）
class _RemoteImageAuthenticatedHttpFileService extends HttpFileService {
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

