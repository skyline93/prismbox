// lib/ui/gallery/pages/gallery_item_page.dart

import 'package:flutter/material.dart';

import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/gallery/widgets/image_content.dart';
import 'package:mobile/ui/gallery/widgets/video_content.dart';
import 'package:mobile/core/enums.dart';

class GalleryItemPage extends StatelessWidget {
  final UnifiedMediaEntity entity;

  const GalleryItemPage({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    // [修正] 移除 Scaffold 和 AppBar, 直接根据媒体类型返回对应的内容组件
    return entity.assetType == MediaType.video
        ? VideoContent(entity: entity)
        : ImageContent(entity: entity);
  }
}
