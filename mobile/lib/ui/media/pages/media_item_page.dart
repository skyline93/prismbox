import 'package:flutter/material.dart';

import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/gallery/widgets/image_content.dart';
import 'package:mobile/ui/gallery/widgets/video_content.dart';

class MediaItemPage extends StatelessWidget {
  final UnifiedMediaEntity entity;

  const MediaItemPage({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    // 逻辑分发中心：根据类型渲染不同的内容 Widget
    if (entity.isVideo) {
      return VideoContent(entity: entity);
    } else {
      return ImageContent(entity: entity);
    }
  }
}
