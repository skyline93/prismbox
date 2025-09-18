// lib/ui/gallery/pages/gallery_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/ui/gallery/viewmodels/gallery_viewmodel.dart';
import 'package:mobile/ui/gallery/pages/gallery_item_page.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:photo_manager/photo_manager.dart';
import 'photo_editor_page.dart';

@RoutePage()
class GalleryPage extends HookConsumerWidget {
  final List<UnifiedMediaEntity> media;
  final int initialIndex;

  const GalleryPage({
    super.key,
    required this.media,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController(initialPage: initialIndex);
    final currentIndex = useState(initialIndex);
    // 使用 a mutable list 来支持删除操作
    final mediaList = useState(List<UnifiedMediaEntity>.from(media));

    // 如果列表为空，直接返回
    if (mediaList.value.isEmpty) {
      // 可以在这里返回一个空状态的 widget，或者直接 pop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    // 确保 currentIndex 不会越界
    if (currentIndex.value >= mediaList.value.length) {
      currentIndex.value = mediaList.value.length - 1;
    }

    final currentEntity = mediaList.value[currentIndex.value];
    final asyncCurrentEntity = ref.watch(mediaEntityProvider(currentEntity.id));

    useEffect(() {
      void listener() {
        final newIndex = pageController.page?.round() ?? initialIndex;
        if (newIndex != currentIndex.value &&
            newIndex < mediaList.value.length) {
          currentIndex.value = newIndex;
          _precacheAdjacent(ref, newIndex, mediaList.value);
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          _initialLoad(ref, initialIndex, mediaList.value);
        }
      });

      pageController.addListener(listener);
      return () => pageController.removeListener(listener);
    }, [pageController, mediaList.value.length]);

    // 定义按钮的 onPressed 回调
    final onEditPressed =
        (currentEntity.isVideo || currentEntity.localId == null)
        ? null // 禁用按钮
        : () async {
            final asset = await AssetEntity.fromId(currentEntity.localId!);

            // 确保 asset 存在且 context 仍然有效
            if (asset == null || !context.mounted) return;

            // 导航到照片编辑页面
            await Navigator.push<AssetEntity?>(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoEditorPage(assetEntity: asset),
              ),
            );
          };

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.dark,
        ),
        actions: [
          asyncCurrentEntity.when(
            data: (entity) => _buildAppBarActions(context, ref, entity),
            loading: () => const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            error: (err, stack) => const IconButton(
              icon: Icon(Icons.error_outline, color: Colors.red),
              tooltip: '加载状态失败',
              onPressed: null,
            ),
          ),
        ],
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: mediaList.value.length,
        itemBuilder: (context, index) {
          return GalleryItemPage(entity: mediaList.value[index]);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.black54,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildBottomBarButton(
              icon: Icons.edit_outlined,
              label: '编辑',
              onPressed: onEditPressed,
            ),
            _buildBottomBarButton(
              icon: Icons.share_outlined,
              label: '分享',
              onPressed: () {
                // 分享逻辑
              },
            ),
            // START: MODIFIED SECTION
            _buildBottomBarButton(
              icon: Icons.delete_outline,
              label: '删除',
              onPressed: () async {
                // 从 state 中获取当前实体
                final entityToDelete = mediaList.value[currentIndex.value];

                // 弹出确认对话框
                final bool? shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('确认删除'),
                      content: const Text(
                        '你确定要删除这个项目吗？\n它将在回收站中保存30天, 之后将被永久删除。',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('取消'),
                          onPressed: () {
                            Navigator.of(context).pop(false); // 关闭对话框，返回 false
                          },
                        ),
                        TextButton(
                          child: Text(
                            '删除',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop(true); // 关闭对话框，返回 true
                          },
                        ),
                      ],
                    );
                  },
                );

                // 如果用户确认删除，则执行删除操作
                if (shouldDelete == true) {
                  // 在执行异步操作前检查 context 是否仍然有效
                  if (!context.mounted) return;

                  await ref.read(mediaRepositoryProvider).deleteAssets([
                    entityToDelete,
                  ]);

                  // 从本地列表中移除
                  final removedIndex = currentIndex.value;
                  mediaList.value = List.from(mediaList.value)
                    ..removeAt(removedIndex);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('1 个项目已移至回收站')));
                }
              },
            ),
            // END: MODIFIED SECTION
          ],
        ),
      ),
    );
  }

  // 辅助方法，用于创建带图标和文字的底部栏按钮
  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white, // 设置按钮前景颜色（图标和文字）
        disabledForegroundColor: Colors.grey[600], // 设置禁用时的颜色
        padding: const EdgeInsets.symmetric(vertical: 8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // 让 Column 高度自适应内容
        children: <Widget>[
          Icon(icon),
          const SizedBox(height: 4), // 图标和文字之间的间距
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _initialLoad(WidgetRef ref, int index, List<UnifiedMediaEntity> media) {
    _precacheEntity(ref, media[index]);
    _precacheAdjacent(ref, index, media);
  }

  void _precacheAdjacent(
    WidgetRef ref,
    int index,
    List<UnifiedMediaEntity> media,
  ) {
    if (index + 1 < media.length) {
      _precacheEntity(ref, media[index + 1]);
    }
    if (index - 1 >= 0) {
      _precacheEntity(ref, media[index - 1]);
    }
  }

  void _precacheEntity(WidgetRef ref, UnifiedMediaEntity entity) {
    if (entity.isVideo) return;

    // ignore: body_might_complete_normally_catch_error
    ref.read(mediaDetailProvider(entity).future).catchError((_) {});
  }

  Widget _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    UnifiedMediaEntity entity,
  ) {
    Widget buildInProgressIndicator(String tooltip, {required IconData icon}) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 24,
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
                Icon(icon, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      );
    }

    switch (entity.syncStatus) {
      case SyncStatus.cloudOnly:
        return IconButton(
          icon: const Icon(Icons.cloud_download_outlined),
          tooltip: '下载到设备',
          onPressed: () {
            ref.read(mediaDetailProvider(entity).notifier).download();
          },
        );
      case SyncStatus.downloadFailed:
        return IconButton(
          icon: const Icon(
            Icons.cloud_download_outlined,
            color: Colors.orangeAccent,
          ),
          tooltip: '下载失败，点击重试',
          onPressed: () {
            ref.read(mediaDetailProvider(entity).notifier).download();
          },
        );
      case SyncStatus.downloading:
        return buildInProgressIndicator('下载中...', icon: Icons.download);
      case SyncStatus.localOnlyNotSelected:
        return IconButton(
          icon: const Icon(Icons.cloud_upload_outlined),
          tooltip: '上传到云端',
          onPressed: () async {
            final asset = await AssetEntity.fromId(entity.localId!);
            if (asset == null) {
              ScaffoldMessenger.of(
                // ignore: use_build_context_synchronously
                context,
              ).showSnackBar(const SnackBar(content: Text('无法找到本地媒体资源，上传失败')));
              return;
            }

            ref
                .read(transferManagerProvider)
                .uploadService
                .enqueueUploadJob(asset);
          },
        );
      case SyncStatus.uploadFailed:
        return IconButton(
          icon: const Icon(
            Icons.cloud_upload_outlined,
            color: Colors.orangeAccent,
          ),
          tooltip: '上传失败，点击重试',
          onPressed: () async {
            final asset = await AssetEntity.fromId(entity.localId!);
            if (asset == null) {
              ScaffoldMessenger.of(
                // ignore: use_build_context_synchronously
                context,
              ).showSnackBar(const SnackBar(content: Text('无法找到本地媒体资源，上传失败')));
              return;
            }

            ref
                .read(transferManagerProvider)
                .uploadService
                .enqueueUploadJob(asset);
          },
        );
      case SyncStatus.uploading:
        return buildInProgressIndicator('上传中...', icon: Icons.upload);
      case SyncStatus.synced:
        return const IconButton(
          icon: Icon(Icons.cloud_done, color: Colors.white),
          tooltip: '已同步',
          onPressed: null,
        );
      case SyncStatus.error:
        return const IconButton(
          icon: Icon(Icons.error_outline, color: Colors.red),
          tooltip: '同步失败',
          onPressed: null,
        );
    }
  }
}
