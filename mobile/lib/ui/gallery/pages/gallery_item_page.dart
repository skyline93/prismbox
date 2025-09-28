// lib/ui/gallery/pages/gallery_item_page.dart
import 'package:flutter/material.dart';

import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/gallery/widgets/image_content.dart';
import 'package:mobile/ui/gallery/widgets/video_content.dart';
import 'package:mobile/core/enums.dart';

class GalleryItemPage extends StatelessWidget {
  final UnifiedMediaEntity entity;
  final VoidCallback onTap;
  // START: --- MODIFICATION ---
  final Color foregroundColor; // 新增：接收前景色
  final Color backgroundColor;
  // END: --- MODIFICATION ---

  const GalleryItemPage({
    super.key,
    required this.entity,
    required this.onTap,
    // START: --- MODIFICATION ---
    required this.foregroundColor, // 新增：在构造函数中接收
    required this.backgroundColor,
    // END: --- MODIFICATION ---
  });

  @override
  Widget build(BuildContext context) {
    // 将 onTap 回调和 foregroundColor 继续传递给子组件
    return entity.assetType == MediaType.video
        ? VideoContent(
            entity: entity,
            onTap: onTap,
            // START: --- MODIFICATION ---
            foregroundColor: foregroundColor, // 传递给 VideoContent
            backgroundColor: backgroundColor,
            // END: --- MODIFICATION ---
          )
        : ImageContent(
            entity: entity,
            onTap: onTap,
            // START: --- MODIFICATION ---
            foregroundColor: foregroundColor, // 传递给 ImageContent
            backgroundColor: backgroundColor,
            // END: --- MODIFICATION ---
          );
  }
}
