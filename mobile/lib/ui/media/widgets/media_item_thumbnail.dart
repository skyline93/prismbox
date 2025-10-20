// lib/ui/media/widgets/media_item_thumbnail.dart

import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/sync_status_icon.dart';
import 'package:mobile/ui/media/widgets/media_item_video_overlay.dart';
import 'package:mobile/ui/media/widgets/media_item_placeholder.dart';
import 'package:mobile/ui/media/widgets/thumbnail_load_strategy.dart';
import 'package:mobile/core/custom_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MediaItemThumbnail extends ConsumerWidget {
  final ThumbnailLoadStrategy strategy;
  final UnifiedMediaEntity entity;

  const MediaItemThumbnail({
    super.key,
    required this.strategy,
    required this.entity,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget imageWidget;
    switch (strategy) {
      // --- 修改核心 ---
      // 处理新的 LocalBytesStrategy
      case LocalBytesStrategy(bytes: final bytes):
        // debugPrint(
        //   "[Local Bytes] 媒体实体 ID: ${entity.id}, 加载 ${bytes.lengthInBytes} bytes 的缩略图数据",
        // );
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          frameBuilder: _imageFrameBuilder,
          errorBuilder: _imageErrorBuilder,
        );
        break;

      case NetworkUrlStrategy(url: final url):
        debugPrint(
          "[Network] 媒体实体 ID: ${entity.id}, Cloud UUID: ${entity.cloudUuid}, Image URL: $url",
        );
        imageWidget = _buildCachedNetworkImage(ref, url);
        break;

      case NoThumbnailStrategy():
        imageWidget = MediaItemPlaceholder(
          icon: entity.isVideo ? Icons.videocam : Icons.image,
        );
        break;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        imageWidget,
        if (entity.isVideo) VideoOverlay(durationSec: entity.durationSec ?? 0),
        Positioned(
          top: 4,
          right: 4,
          child: SyncStatusIcon(status: entity.syncStatus),
        ),
        if (entity.isRAW)
          Positioned(bottom: 4, right: 4, child: _buildRawBadge()),
      ],
    );
  }

  Widget _buildCachedNetworkImage(WidgetRef ref, String imageUrl) {
    final cacheManager = ref.watch(customCacheManagerProvider);
    return CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: cacheManager,
      cacheKey: entity.cloudUuid,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (context, url) => MediaItemPlaceholder(
        icon: entity.isVideo ? Icons.videocam : Icons.image,
      ),
      errorWidget: (context, url, error) {
        debugPrint("网络图片加载错误: $url, error: $error");
        return const MediaItemPlaceholder(icon: Icons.broken_image);
      },
    );
  }

  Widget _imageFrameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded) return child;
    return AnimatedOpacity(
      opacity: frame == null ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: child,
    );
  }

  Widget _imageErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    debugPrint("【严重】本地缩略图数据显示失败 (ID: ${entity.id}): $error");
    return const MediaItemPlaceholder(icon: Icons.broken_image);
  }

  Widget _buildRawBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'RAW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
