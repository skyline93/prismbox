// lib/ui/media/widgets/media_item_thumbnail.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/widgets/sync_status_icon.dart';
import 'package:mobile/ui/media/widgets/media_item_video_overlay.dart';
import 'package:mobile/ui/media/widgets/media_item_placeholder.dart';

class MediaItemThumbnail extends StatelessWidget {
  final Uint8List? thumbnailData;
  final UnifiedMediaEntity entity;

  const MediaItemThumbnail({
    super.key,
    required this.thumbnailData,
    required this.entity,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (thumbnailData != null) {
      imageWidget = Image.memory(
        thumbnailData!,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint("图片显示错误: $error");
          return const MediaItemPlaceholder(icon: Icons.broken_image);
        },
      );
    } else {
      // 当数据为空但不是错误时，也显示占位符
      imageWidget = MediaItemPlaceholder(
        icon: entity.isVideo ? Icons.videocam : Icons.image,
      );
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
      ],
    );
  }
}
