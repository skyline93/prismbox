// lib/ui/gallery/pages/gallery_item_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/gallery/widgets/image_content.dart';
import 'package:mobile/ui/gallery/widgets/video_content.dart';
import 'package:mobile/core/enums.dart';

class GalleryItemPage extends ConsumerWidget {
  // [修正] 修改为 ConsumerWidget
  final UnifiedMediaEntity entity;

  const GalleryItemPage({super.key, required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // [修正] 添加 WidgetRef
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // [任务 3.3 优化版] 在 AppBar 中添加入口
          if (entity.cloudUuid != null) // 只有云端文件才显示下载按钮
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ref
                    .read(transferServiceProvider)
                    .enqueueDownloadJob(
                      mediaUuid: entity.cloudUuid!, // 使用 cloudUuid
                      originalFilename: entity.fileName ?? 'downloaded_file',
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('下载任务已添加'),
                    duration: Duration(seconds: 2),
                  ),
                );
                // 导航到传输管理页面
                context.router.push(const TransferManagerRoute());
              },
            ),
        ],
      ),
      body: entity.assetType == MediaType.video
          ? VideoContent(entity: entity)
          : ImageContent(entity: entity),
    );
  }
}
