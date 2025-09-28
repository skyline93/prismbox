// lib/ui/gallery/widgets/video_viewer.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

class MediaVideoViewer extends HookConsumerWidget {
  final File videoFile;

  const MediaVideoViewer({super.key, required this.videoFile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(
      () => VideoPlayerHdrController.file(videoFile),
      [videoFile.path],
    );

    useEffect(() {
      controller.setLooping(true);
      controller.initialize();
      return controller.dispose;
    }, [controller]);

    useListenable(controller);

    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (controller.value.hasError) {
      debugPrint("视频播放器错误: ${controller.value.errorDescription}");
      return const Center(
        child: Text('视频播放失败', style: TextStyle(color: Colors.red)),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: GestureDetector(
          onTap: () => controller.value.isPlaying
              ? controller.pause()
              : controller.play(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayerHdr(controller),
              if (!controller.value.isPlaying)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
