// lib/ui/gallery/pages/gallery_item_page.dart

import 'package:flutter/material.dart';

import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/gallery/widgets/image_content.dart';
import 'package:mobile/ui/gallery/widgets/video_content.dart';
import 'package:mobile/core/enums.dart';

class GalleryItemPage extends StatelessWidget {
  final UnifiedMediaEntity entity;
  final VoidCallback onTap; // 新增：接收 onTap 回调

  const GalleryItemPage({
    super.key,
    required this.entity,
    required this.onTap, // 新增：在构造函数中接收
  });

  @override
  Widget build(BuildContext context) {
    // 将 onTap 回调继续传递给子组件
    return entity.assetType == MediaType.video
        ? VideoContent(entity: entity, onTap: onTap)
        : ImageContent(entity: entity, onTap: onTap);
  }
}
