// lib/ui/gallery/widgets/image_content.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/gallery/viewmodels/gallery_viewmodel.dart';
import 'package:mobile/ui/gallery/widgets/error_display.dart';
import 'package:mobile/ui/gallery/widgets/image_viewer.dart';
// import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ImageContent extends ConsumerWidget {
  final UnifiedMediaEntity entity;

  const ImageContent({super.key, required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsyncValue = ref.watch(mediaDetailProvider(entity));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: mediaAsyncValue.when(
        data: (mediaData) {
          final ImageProvider imageProvider = mediaData.when(
            asset: (assetEntity) => AssetEntityImageProvider(
              assetEntity,
              isOriginal: true, // 请求原图以获得最佳质量
            ),
            bytes: (bytes) => MemoryImage(bytes),
            file: (file) => FileImage(file),
          );

          precacheImage(imageProvider, context);

          return MediaImageViewer(
            key: ValueKey(entity.id),
            imageProvider: imageProvider,
            heroTag: entity.id.toString(),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) =>
            ErrorDisplay(title: '无法加载媒体', message: err.toString()),
      ),
      // [任务 3.3] 添加下载按钮
      floatingActionButton: entity.isRemote
          ? FloatingActionButton(
              onPressed: () {
                ref
                    .read(transferServiceProvider)
                    .enqueueDownloadJob(
                      mediaUuid: entity.cloudUuid!,
                      originalFilename: entity.fileName!,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Download started.'),
                    duration: Duration(seconds: 2),
                  ),
                );
                // 导航到传输管理页面
                context.router.push(const TransferManagerRoute());
              },
              child: const Icon(Icons.download),
            )
          : null, // 本地文件不显示下载按钮
    );
  }
}
