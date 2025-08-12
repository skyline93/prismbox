// lib/ui/media/page/media_detail.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/app_database.dart'; // SyncStatus için gerekli
// import 'package:mobile/providers.dart'; // mediaRepositoryProvider için gerekli
import 'package:transparent_image/transparent_image.dart';
import 'package:video_player/video_player.dart';

/// ---------------------------------------------------------------------------
/// **为详情页创建数据提供者 (Provider)**
///
/// 这个 Provider 负责异步获取全分辨率的媒体数据。
/// - 对于本地媒体，它会直接返回一个 File 对象。
/// - 对于仅云端的媒体，它会调用 repository 的方法下载数据。
/// ---------------------------------------------------------------------------
final fullMediaProvider = FutureProvider.family<dynamic, UnifiedMediaEntity>((
  ref,
  entity,
) async {
  // 1. 对于本地资源，直接返回文件对象以获得最佳性能
  if (entity.filePath != null && entity.filePath!.isNotEmpty) {
    final file = File(entity.filePath!);
    if (await file.exists()) {
      return file;
    }
  }

  // 2. 对于仅云端的资源，调用 repository 下载完整媒体
  if (entity.syncStatus == SyncStatus.cloudOnly && entity.cloudUuid != null) {
    // TODO
    // try {
    //   final repository = ref.read(mediaRepositoryProvider);
    //   return await repository.downloadMedia(entity.cloudUuid!);
    // } catch (e) {
    //   debugPrint("无法从云端下载完整媒体 for cloudUuid=${entity.cloudUuid}: $e");
    //   throw Exception('无法下载云端资源: $e');
    // }
  }

  // 3. 如果本地文件丢失或资源不可用，则抛出异常
  throw Exception('媒体资源不可用 for entity id: ${entity.id}');
});

@RoutePage()
class MediaDetailPage extends ConsumerWidget {
  final List<UnifiedMediaEntity> media;
  final int initialIndex;

  const MediaDetailPage({
    super.key,
    required this.media,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = PageController(initialPage: initialIndex);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        // 【修正】使用推荐的常量色值
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
        ),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: media.length,
        itemBuilder: (context, index) {
          final currentEntity = media[index];
          if (currentEntity.isVideo) {
            return MediaVideoViewer(entity: currentEntity);
          } else {
            return MediaImageViewer(entity: currentEntity);
          }
        },
      ),
    );
  }
}

/// 用于显示单张图片的组件
class MediaImageViewer extends ConsumerWidget {
  final UnifiedMediaEntity entity;
  const MediaImageViewer({super.key, required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 fullMediaProvider 的状态，这部分逻辑是正确的
    final mediaAsyncValue = ref.watch(fullMediaProvider(entity));

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 5.0,
      child: Center(
        child: mediaAsyncValue.when(
          data: (mediaData) {
            if (mediaData is File) {
              return FadeInImage(
                fit: BoxFit.contain,
                placeholder: MemoryImage(kTransparentImage),
                image: FileImage(mediaData),
              );
            } else if (mediaData is Uint8List) {
              return FadeInImage(
                fit: BoxFit.contain,
                placeholder: MemoryImage(kTransparentImage),
                image: MemoryImage(mediaData),
              );
            }
            return const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 60,
            );
          },
          loading: () => const CircularProgressIndicator(color: Colors.white),
          error: (err, stack) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text('无法加载图片', style: TextStyle(color: Colors.red.shade200)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 用于显示和播放单个视频的组件
class MediaVideoViewer extends ConsumerStatefulWidget {
  final UnifiedMediaEntity entity;
  const MediaVideoViewer({super.key, required this.entity});

  @override
  ConsumerState<MediaVideoViewer> createState() => _MediaVideoViewerState();
}

class _MediaVideoViewerState extends ConsumerState<MediaVideoViewer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    // 使用 ref 调用初始化方法，这是推荐的做法
    _initializeController(ref);
  }

  // 【修正】将 WidgetRef 作为参数传入
  Future<void> _initializeController(WidgetRef ref) async {
    // 【核心修正】直接从 provider 中获取 .future 对象，然后 await 它
    // 这可以确保我们等待的是异步操作的结果，而不是 AsyncValue 本身
    try {
      final mediaData = await ref.read(fullMediaProvider(widget.entity).future);

      if (!mounted) return;

      if (mediaData is File) {
        // 现在 mediaData 是一个正确的 File 对象，不会再报错
        _controller = VideoPlayerController.file(mediaData);
      } else {
        // 此处的逻辑保持不变，用于处理其他数据类型或错误
        debugPrint("视频播放暂不支持直接从内存加载，需要实现文件缓存。");
        throw Exception("不支持从内存播放视频");
      }

      _controller!.setLooping(true);
      // 将初始化结果赋值给 Future，以便 FutureBuilder 可以监听
      _initializeVideoPlayerFuture = _controller!.initialize();
      // 刷新UI以显示 FutureBuilder
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("视频控制器初始化失败: $e");
      if (mounted) {
        // 设置一个失败的 Future 以便 FutureBuilder 显示错误状态
        setState(() {
          _initializeVideoPlayerFuture = Future.error(e);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializeVideoPlayerFuture == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            !snapshot.hasError) {
          return Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    if (!_controller!.value.isPlaying)
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
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text('无法播放视频', style: TextStyle(color: Colors.red.shade200)),
              ],
            ),
          );
        }
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
    );
  }
}
