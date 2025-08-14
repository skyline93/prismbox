// lib/ui/gallery/pages/gallery_item_page.dart

import 'package:flutter/material.dart';

import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/gallery/widgets/image_content.dart';
import 'package:mobile/ui/gallery/widgets/video_content.dart';

class GalleryItemPage extends StatelessWidget {
  final UnifiedMediaEntity entity;

  const GalleryItemPage({super.key, required this.entity});

  @override
  Widget build(BuildContext context) {
    if (entity.isVideo) {
      return VideoContent(entity: entity);
    } else {
      return ImageContent(entity: entity);
    }
  }
}
