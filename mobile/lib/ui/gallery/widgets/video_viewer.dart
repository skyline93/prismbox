// lib/ui/gallery/widgets/video_viewer.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

class MediaVideoViewer extends HookConsumerWidget {
  final File videoFile;
  final VoidCallback onTap;

  const MediaVideoViewer({
    super.key,
    required this.videoFile,
    required this.onTap,
  });

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

    // --- START: FINAL AND CORRECT SOLUTION ---

    // 使用 GestureDetector 包裹整个 Column，以便在屏幕任何位置（包括上下黑边）
    // 点击都能触发沉浸式切换。
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onDoubleTap: () {
        controller.value.isPlaying ? controller.pause() : controller.play();
      },
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.center, // 使用 Spacer 效果更好
        children: [
          // 上方的 Spacer，会占据所有可用空间的一部分
          const Spacer(),

          // AspectRatio 会自动使用 Column 提供的宽度（即屏幕宽度）
          // 并根据视频的宽高比来确定自己的高度。
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center,
              children: [
                VideoPlayerHdr(controller),
                if (!controller.value.isPlaying)
                  IgnorePointer(
                    child: Container(
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
                  ),
              ],
            ),
          ),

          // 下方的 Spacer，会与上方的 Spacer 平分剩余空间
          const Spacer(),
        ],
      ),
    );
    // --- END: FINAL AND CORRECT SOLUTION ---
  }
}
