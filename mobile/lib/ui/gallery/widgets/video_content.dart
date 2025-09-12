// lib/ui/gallery/widgets/video_content.dart

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/gallery/viewmodels/gallery_viewmodel.dart';
import 'package:mobile/ui/gallery/widgets/error_display.dart';
import 'package:mobile/ui/gallery/widgets/video_viewer.dart';

class VideoContent extends ConsumerWidget {
  final UnifiedMediaEntity entity;

  const VideoContent({super.key, required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsyncValue = ref.watch(mediaDetailProvider(entity));

    return mediaAsyncValue.when(
      data: (mediaData) => mediaData.when(
        file: (file) => MediaVideoViewer(videoFile: file),
        asset: (_) => const ErrorDisplay(
          title: '逻辑错误',
          message: '收到了媒体库资产（Asset），但此处需要一个视频文件（File）。',
        ),
        bytes: (_) =>
            const ErrorDisplay(title: '数据类型错误', message: '应为视频文件，但收到了字节数据。'),
      ),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (err, _) => ErrorDisplay(title: '无法加载视频', message: err.toString()),
    );
  }
}
