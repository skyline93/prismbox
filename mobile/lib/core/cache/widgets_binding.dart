// lib/core/cache/widgets_binding.dart

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/cache/custom_image_cache.dart';

/// 自定义 WidgetsFlutterBinding
/// 重写 createImageCache() 方法以使用 CustomImageCache
final class PrismBoxWidgetsBinding extends WidgetsFlutterBinding {
  static final Logger _log = Logger('PrismBoxWidgetsBinding');

  PrismBoxWidgetsBinding() {
    _log.info('✅ CustomImageCache 已初始化（三级缓存分离：ThumbHash/小图/大图）');
  }

  @override
  ImageCache createImageCache() {
    final cache = CustomImageCache();
    _log.info('✅ CustomImageCache 实例已创建');
    return cache;
  }
}

