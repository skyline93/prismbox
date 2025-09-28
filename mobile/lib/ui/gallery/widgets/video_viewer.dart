// lib/ui/gallery/widgets/video_viewer.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:video_player_hdr/video_player_hdr.dart';

class MediaVideoViewer extends HookConsumerWidget {
  final File videoFile;
  final VoidCallback onTap;
  // 新增：接收背景色和前景色
  final Color backgroundColor;
  final Color foregroundColor;

  const MediaVideoViewer({
    super.key,
    required this.videoFile,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
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

    // 当视频控制器还未初始化时，显示加载动画
    if (!controller.value.isInitialized) {
      // 使用 Container 来确保背景色被应用
      return Container(
        color: backgroundColor,
        child: Center(
          // 使用动态的前景色
          child: CircularProgressIndicator(color: foregroundColor),
        ),
      );
    }

    if (controller.value.hasError) {
      debugPrint("视频播放器错误: ${controller.value.errorDescription}");
      return Container(
        color: backgroundColor,
        child: const Center(
          child: Text('视频播放失败', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    // --- START: FINAL AND CORRECT SOLUTION ---

    // 使用 Container 作为根组件，并强制设置背景色。
    // 这将确保视频上下方的空白区域（"黑边"）始终是我们想要的颜色。
    return Container(
      color: backgroundColor,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onDoubleTap: () {
          controller.value.isPlaying ? controller.pause() : controller.play();
        },
        child: Column(
          children: [
            const Spacer(),
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
            const Spacer(),
          ],
        ),
      ),
    );
    // --- END: FINAL AND CORRECT SOLUTION ---
  }
}
