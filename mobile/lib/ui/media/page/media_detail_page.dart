// lib/ui/media/page/media_detail_page.dart

// 移除了 'dart:io'
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/ui/media/viewmodels/media_detail_viewmodel.dart';
import 'package:mobile/ui/media/widgets/media_image_viewer.dart';
import 'package:mobile/ui/media/widgets/media_video_viewer.dart';

// 缓存 AssetEntity 的 Provider (保持不变，设计很好)
final assetEntityCacheProvider = StateProvider<Map<String, AssetEntity>>(
  (ref) => {},
);

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
    final pageController = usePageController(initialPage: initialIndex);
    final currentIndex = useState(initialIndex);
    final currentEntity = media[currentIndex.value];

    useEffect(() {
      // 页面滑动时的监听器，只预加载相邻页面
      void listener() {
        final newIndex = pageController.page?.round() ?? initialIndex;
        if (newIndex != currentIndex.value) {
          currentIndex.value = newIndex;
          // 这个函数现在只负责预热“邻居”
          _precacheAdjacent(context, ref, newIndex);
        }
      }

      // 页面首次构建后，立即加载当前页和相邻页
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _initialLoad(context, ref, initialIndex);
        }
      });

      pageController.addListener(listener);
      return () => pageController.removeListener(listener);
    }, [pageController]);

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
          // --- 逻辑分发中心 ---
          // 在这里根据媒体类型构建对应的 Viewer
          final entity = media[index];
          if (entity.isVideo) {
            return _buildVideoPage(ref, entity);
          } else {
            return _buildImagePage(context, ref, entity);
          }
        },
      ),
    );
  }

  /// 构建图片页面
  Widget _buildImagePage(
    BuildContext context,
    WidgetRef ref,
    UnifiedMediaEntity entity,
  ) {
    // 检查是否可以使用 PhotoManager (本地、有 localId)
    final canUsePhotoManager =
        entity.localId != null && entity.localId!.isNotEmpty;

    if (canUsePhotoManager) {
      // --- 主路径: PhotoManager (更高效) ---
      final cachedAssets = ref.watch(assetEntityCacheProvider);
      final assetEntity = cachedAssets[entity.localId];

      if (assetEntity != null) {
        // 缓存命中：立即渲染，无任何异步等待，体验最丝滑
        return MediaImageViewer(
          key: ValueKey(assetEntity.id),
          imageProvider: AssetEntityImageProvider(assetEntity),
          heroTag: assetEntity.id,
        );
      }
      // 缓存未命中：显示一个黑色占位符，等待预加载完成触发重建
      return Container(color: Colors.black);
    } else {
      // --- 备用路径: 从文件/网络加载 ---
      final mediaAsyncValue = ref.watch(mediaDetailProvider(entity));
      return mediaAsyncValue.when(
        data: (mediaData) => mediaData.when(
          bytes: (bytes) => MediaImageViewer(
            key: ValueKey(entity.id),
            imageProvider: MemoryImage(bytes),
            heroTag: entity.id.toString(),
          ),
          file: (file) => MediaImageViewer(
            key: ValueKey("${entity.id}_file"), // 使用不同的key以确保重建
            imageProvider: FileImage(file),
            heroTag: entity.id.toString(),
          ),
        ),
        loading: () => Container(color: Colors.black),
        error: (err, _) => _buildErrorWidget(err.toString()),
      );
    }
  }

  /// 构建视频页面
  Widget _buildVideoPage(WidgetRef ref, UnifiedMediaEntity entity) {
    final mediaAsyncValue = ref.watch(mediaDetailProvider(entity));
    return mediaAsyncValue.when(
      data: (mediaData) => mediaData.when(
        bytes: (_) => _buildErrorWidget("数据类型错误：应为视频文件"),
        file: (file) => MediaVideoViewer(videoFile: file),
      ),
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      error: (err, _) => _buildErrorWidget(err.toString()),
    );
  }

  // ⭐️【 新增 】: 页面首次加载的专用函数
  void _initialLoad(BuildContext context, WidgetRef ref, int index) {
    // 1. 立即加载当前实体
    _precacheEntity(context, ref, media[index]);
    // 2. 预加载相邻实体
    _precacheAdjacent(context, ref, index);
  }

  // ⭐️【 重命名并明确职责 】: 此函数现在只负责预加载相邻页面
  void _precacheAdjacent(BuildContext context, WidgetRef ref, int index) {
    final nextIndex = index + 1;
    if (nextIndex < media.length) {
      _precacheEntity(context, ref, media[nextIndex]);
    }
    final prevIndex = index - 1;
    if (prevIndex >= 0) {
      _precacheEntity(context, ref, media[prevIndex]);
    }
  }

  /// 针对单个实体的智能预加载
  void _precacheEntity(
    BuildContext context,
    WidgetRef ref,
    UnifiedMediaEntity entity,
  ) {
    if (entity.isVideo) return; // 视频不预加载

    final canUsePhotoManager =
        entity.localId != null && entity.localId!.isNotEmpty;

    if (canUsePhotoManager) {
      // 如果已在缓存，则跳过
      if (ref.read(assetEntityCacheProvider)[entity.localId!] != null) return;

      // 异步获取 AssetEntity 并放入缓存，这将触发 UI 刷新
      AssetEntity.fromId(entity.localId!)
          .then((asset) {
            if (asset != null && context.mounted) {
              // 1. 将获取到的 AssetEntity 存入缓存
              ref.read(assetEntityCacheProvider.notifier).update((state) {
                return {...state, entity.localId!: asset};
              });
              // 2. 预解码图片到 Flutter 的图片缓存
              precacheImage(AssetEntityImageProvider(asset), context);
            }
          })
          .catchError((_) {});
    } else {
      // 标准路径预加载：预热 Notifier，让它在后台读取文件字节
      // ⭐️⭐️⭐️【 已修复 】⭐️⭐️⭐️
      // 使用 .when() 方法来安全地处理 MediaData 的不同状态，而不是 `is _MediaDataBytes`
      ref
          .read(mediaDetailProvider(entity).future)
          .then((mediaData) {
            if (context.mounted) {
              mediaData.when(
                bytes: (bytes) => precacheImage(MemoryImage(bytes), context),
                file: (_) {
                  /* 视频文件或其他文件类型，在预缓存图片时忽略 */
                },
              );
            }
          })
          .catchError((_) {});
    }
  }

  // AppBar Actions (逻辑不变)
  Widget _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    UnifiedMediaEntity entity,
  ) {
    final mediaState = ref.watch(mediaDetailProvider(entity));

    if (mediaState.isLoading && !mediaState.isRefreshing) {
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
    }

    switch (entity.syncStatus) {
      case SyncStatus.cloudOnly:
        return IconButton(
          icon: const Icon(Icons.cloud_download_outlined),
          tooltip: '下载到设备',
          onPressed: () =>
              ref.read(mediaDetailProvider(entity).notifier).download(),
        );
      case SyncStatus.localOnlyNotSelected:
        return IconButton(
          icon: const Icon(Icons.cloud_upload_outlined),
          tooltip: '上传到云端',
          onPressed: () =>
              ref.read(mediaDetailProvider(entity).notifier).upload(),
        );
      case SyncStatus.synced:
        return const IconButton(
          icon: Icon(Icons.cloud_done),
          tooltip: '已同步',
          onPressed: null,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  /// 统一的错误显示 Widget
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 16),
            Text(
              '无法加载媒体',
              style: TextStyle(color: Colors.red.shade200, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
