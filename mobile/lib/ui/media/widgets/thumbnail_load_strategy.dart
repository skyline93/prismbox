// lib/ui/media/widgets/thumbnail_load_strategy.dart

import 'package:flutter/foundation.dart';

@immutable
sealed class ThumbnailLoadStrategy {
  const ThumbnailLoadStrategy();
}

/// 加载 Uint8List 格式的本地缩略图数据
class LocalBytesStrategy extends ThumbnailLoadStrategy {
  final Uint8List bytes;
  const LocalBytesStrategy(this.bytes);
}

/// 加载网络图片
class NetworkUrlStrategy extends ThumbnailLoadStrategy {
  final String url;
  const NetworkUrlStrategy(this.url);
}

/// 无法加载，显示占位符
class NoThumbnailStrategy extends ThumbnailLoadStrategy {
  const NoThumbnailStrategy();
}
