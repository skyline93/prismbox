// lib/ui/gallery/widgets/image_content.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/gallery/viewmodels/gallery_viewmodel.dart';
import 'package:mobile/ui/gallery/widgets/error_display.dart';
import 'package:mobile/ui/gallery/widgets/image_viewer.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class ImageContent extends ConsumerWidget {
  final UnifiedMediaEntity entity;

  const ImageContent({super.key, required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsyncValue = ref.watch(mediaDetailProvider(entity));

    return mediaAsyncValue.when(
      data: (mediaData) {
        final ImageProvider imageProvider = mediaData.when(
          asset: (assetEntity) =>
              AssetEntityImageProvider(assetEntity, isOriginal: true),
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
      error: (err, _) => ErrorDisplay(title: '无法加载媒体', message: err.toString()),
    );
  }
}
