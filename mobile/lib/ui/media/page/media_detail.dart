// lib/ui/media/page/media_detail.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/providers.dart'; // 确保这个导入是正确的
import 'package:transparent_image/transparent_image.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

final fullMediaProvider = FutureProvider.family<dynamic, UnifiedMediaEntity>((
  ref,
  entity,
) async {
  // 1. 对于本地已有文件，直接返回文件对象
  if (entity.filePath != null && entity.filePath!.isNotEmpty) {
    final file = File(entity.filePath!);
    if (await file.exists()) {
      return file;
    }
  }

  // 2. 对于仅云端的资源，下载预览图用于显示
  if (entity.syncStatus == SyncStatus.cloudOnly && entity.cloudUuid != null) {
    try {
      final repository = ref.read(mediaRepositoryProvider);
      // 下载预览图字节数据，用于临时显示
      final previewBytes = await repository.downloadPreview(entity.cloudUuid!);

      // 如果是视频，需要先存为临时文件才能播放
      if (entity.isVideo) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(p.join(tempDir.path, '${entity.cloudUuid}.mp4'));
        await tempFile.writeAsBytes(previewBytes);
        return tempFile;
      }

      // 如果是图片，直接返回字节数据
      return previewBytes;
    } catch (e) {
      debugPrint("无法从云端下载预览媒体 for cloudUuid=${entity.cloudUuid}: $e");
      throw Exception('无法下载云端资源: $e');
    }
  }

  // 3. 如果资源不可用，抛出异常
  throw Exception('媒体资源不可用 for entity id: ${entity.id}');
});

@RoutePage()
class MediaDetailPage extends HookConsumerWidget {
  final List<UnifiedMediaEntity> media;
  final int initialIndex;

  const MediaDetailPage({
    super.key,
    required this.media,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 Hook 来创建和监听 PageController
    final pageController = usePageController(initialPage: initialIndex);
    // 使用 Hook 来追踪当前页面的索引
    final currentIndex = useState(initialIndex);

    // 使用 useEffect Hook 来添加监听器，并在组件销毁时自动移除
    useEffect(() {
      void listener() {
        if (pageController.page?.round() != currentIndex.value) {
          currentIndex.value = pageController.page!.round();
        }
      }

      pageController.addListener(listener);
      return () => pageController.removeListener(listener);
    }, [pageController]);

    // 获取当前正在显示的媒体实体
    final currentEntity = media[currentIndex.value];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
        ),
        actions: [_buildAppBarActions(context, ref, currentEntity)],
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: media.length,
        itemBuilder: (context, index) {
          final entity = media[index];
          // 重要的是，让每个页面监听自己的 fullMediaProvider
          if (entity.isVideo) {
            return MediaVideoViewer(entity: entity);
          } else {
            return MediaImageViewer(entity: entity);
          }
        },
      ),
    );
  }

  // AppBar 操作按钮的构建逻辑
  Widget _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    UnifiedMediaEntity entity,
  ) {
    switch (entity.syncStatus) {
      case SyncStatus.cloudOnly:
        return IconButton(
          icon: const Icon(Icons.cloud_download_outlined),
          tooltip: '下载到设备',
          onPressed: () async {
            try {
              await ref
                  .read(mediaRepositoryProvider)
                  .downloadAndSaveOriginal(entity);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('下载完成!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('下载失败: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      case SyncStatus.localOnlyNotSelected:
        return IconButton(
          icon: const Icon(Icons.cloud_upload_outlined),
          tooltip: '上传到云端',
          onPressed: () async {
            try {
              await ref.read(mediaRepositoryProvider).uploadLocalMedia(entity);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('上传成功!'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('上传失败: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      case SyncStatus.downloading:
      case SyncStatus.uploading:
        return const Padding(
          padding: EdgeInsets.all(16.0),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        );
      case SyncStatus.synced:
        return const IconButton(
          icon: Icon(Icons.cloud_done),
          tooltip: '已同步',
          onPressed: null, // 禁用按钮
        );
      default:
        return const SizedBox.shrink(); // 其他状态不显示按钮
    }
  }
}

// 图片查看器 (无改动)
class MediaImageViewer extends ConsumerWidget {
  final UnifiedMediaEntity entity;
  const MediaImageViewer({super.key, required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

// 视频播放器 (无改动)
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
    _initializeController(ref);
  }

  Future<void> _initializeController(WidgetRef ref) async {
    try {
      // 这里的逻辑现在可以正确处理下载的临时视频文件了
      final mediaData = await ref.read(fullMediaProvider(widget.entity).future);
      if (!mounted) return;

      if (mediaData is File) {
        _controller = VideoPlayerController.file(mediaData);
      } else {
        throw Exception("视频播放器接收到无效的数据类型");
      }

      _controller!.setLooping(true);
      _initializeVideoPlayerFuture = _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("视频控制器初始化失败: $e");
      if (mounted) {
        setState(() => _initializeVideoPlayerFuture = Future.error(e));
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
                onTap: () => setState(() {
                  _controller!.value.isPlaying
                      ? _controller!.pause()
                      : _controller!.play();
                }),
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
