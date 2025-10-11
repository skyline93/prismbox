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
import 'package:mobile/providers/upload_orchestrator.dart';

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
    final mediaList = useState(List<UnifiedMediaEntity>.from(media));
    final areBarsVisible = useState(true);

    final bool isImmersive = !areBarsVisible.value;
    final Color backgroundColor = isImmersive ? Colors.black : Colors.white;
    final Color foregroundColor = isImmersive ? Colors.white : Colors.black;
    final Color barBackgroundColor = isImmersive
        ? Colors.black54
        : Colors.white.withOpacity(0.9);
    final Brightness statusBarBrightness = isImmersive
        ? Brightness.dark
        : Brightness.light;

    void toggleBarsVisibility() {
      areBarsVisible.value = !areBarsVisible.value;
      if (areBarsVisible.value) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    }

    useEffect(() {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      return () => SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }, const []);

    if (mediaList.value.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).pop();
      });
      return Scaffold(backgroundColor: backgroundColor);
    }

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
        if (context.mounted) _initialLoad(ref, initialIndex, mediaList.value);
      });
      pageController.addListener(listener);
      return () => pageController.removeListener(listener);
    }, [pageController, mediaList.value.length]);

    final onEditPressed =
        (currentEntity.isVideo || currentEntity.localId == null)
        ? null
        : () async {
            final asset = await AssetEntity.fromId(currentEntity.localId!);
            if (asset == null || !context.mounted) return;
            await Navigator.push<AssetEntity?>(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoEditorPage(assetEntity: asset),
              ),
            );
          };

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AnimatedOpacity(
          opacity: areBarsVisible.value ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !areBarsVisible.value,
            child: AppBar(
              backgroundColor: barBackgroundColor,
              foregroundColor: foregroundColor,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarBrightness: statusBarBrightness,
              ),
              actions: [
                asyncCurrentEntity.when(
                  data: (entity) => _buildAppBarActions(
                    context,
                    ref,
                    entity,
                    foregroundColor: foregroundColor,
                  ),
                  loading: () => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: foregroundColor,
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
          ),
        ),
      ),
      body: PageView.builder(
        controller: pageController,
        itemCount: mediaList.value.length,
        itemBuilder: (context, index) {
          return Container(
            color: backgroundColor,
            child: SafeArea(
              child: GalleryItemPage(
                entity: mediaList.value[index],
                onTap: toggleBarsVisibility,
                foregroundColor: foregroundColor,
                backgroundColor: backgroundColor,
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AnimatedOpacity(
        opacity: areBarsVisible.value ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !areBarsVisible.value,
          child: BottomAppBar(
            color: barBackgroundColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildBottomBarButton(
                  icon: Icons.edit_outlined,
                  label: '编辑',
                  onPressed: onEditPressed,
                  foregroundColor: foregroundColor,
                ),
                _buildBottomBarButton(
                  icon: Icons.share_outlined,
                  label: '分享',
                  onPressed: () {},
                  foregroundColor: foregroundColor,
                ),
                _buildBottomBarButton(
                  icon: Icons.delete_outline,
                  label: '删除',
                  onPressed: () async {
                    final entityToDelete = mediaList.value[currentIndex.value];
                    final bool? shouldDelete = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('确认删除'),
                        content: const Text(
                          '你确定要删除这个项目吗？\n它将在回收站中保存30天, 之后将被永久删除。',
                        ),
                        actions: <Widget>[
                          TextButton(
                            child: const Text('取消'),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                          TextButton(
                            child: Text(
                              '删除',
                              style: TextStyle(
                                color: Theme.of(ctx).colorScheme.error,
                              ),
                            ),
                            onPressed: () => Navigator.of(ctx).pop(true),
                          ),
                        ],
                      ),
                    );

                    if (shouldDelete == true) {
                      if (!context.mounted) return;
                      await ref.read(mediaRepositoryProvider).deleteAssets([
                        entityToDelete,
                      ]);
                      final removedIndex = currentIndex.value;
                      mediaList.value = List.from(mediaList.value)
                        ..removeAt(removedIndex);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('1 个项目已移至回收站')),
                      );
                    }
                  },
                  foregroundColor: foregroundColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color foregroundColor,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        disabledForegroundColor: Colors.grey[600],
        padding: const EdgeInsets.symmetric(vertical: 8.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon),
          const SizedBox(height: 4),
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
    if (index + 1 < media.length) _precacheEntity(ref, media[index + 1]);
    if (index - 1 >= 0) _precacheEntity(ref, media[index - 1]);
  }

  void _precacheEntity(WidgetRef ref, UnifiedMediaEntity entity) {
    if (entity.isVideo) return;
    // ignore: body_might_complete_normally_catch_error
    ref.read(mediaDetailProvider(entity).future).catchError((_) {});
  }

  Widget _buildAppBarActions(
    BuildContext context,
    WidgetRef ref,
    UnifiedMediaEntity entity, {
    required Color foregroundColor,
  }) {
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
                CircularProgressIndicator(
                  color: foregroundColor,
                  strokeWidth: 2.5,
                ),
                Icon(icon, color: foregroundColor, size: 16),
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
          onPressed: () =>
              ref.read(mediaDetailProvider(entity).notifier).download(),
        );
      case SyncStatus.downloadFailed:
        return IconButton(
          icon: const Icon(
            Icons.cloud_download_outlined,
            color: Colors.orangeAccent,
          ),
          tooltip: '下载失败，点击重试',
          onPressed: () =>
              ref.read(mediaDetailProvider(entity).notifier).download(),
        );
      case SyncStatus.downloading:
        return buildInProgressIndicator('下载中...', icon: Icons.download);
      case SyncStatus.localOnly:
        return IconButton(
          icon: const Icon(Icons.cloud_upload_outlined),
          tooltip: '上传到云端',
          onPressed: () async {
            final asset = await AssetEntity.fromId(entity.localId!);
            if (asset == null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('无法找到本地媒体资源，上传失败')));
              return;
            }

            final file = await asset.originFile;

            ref
                .read(transferManagerProvider)
                .uploadService
                .enqueueMultipleJobs([
                  UploadTaskPayload(
                    file: file!,
                    assetId: asset.id,
                    mediaType: entity.assetType,
                  ),
                ]);
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
                context,
              ).showSnackBar(const SnackBar(content: Text('无法找到本地媒体资源，上传失败')));
              return;
            }

            final file = await asset.originFile;

            ref
                .read(transferManagerProvider)
                .uploadService
                .enqueueMultipleJobs([
                  UploadTaskPayload(
                    file: file!,
                    assetId: asset.id,
                    mediaType: entity.assetType,
                  ),
                ]);
          },
        );
      case SyncStatus.uploading:
        return buildInProgressIndicator('上传中...', icon: Icons.upload);
      case SyncStatus.synced:
        return IconButton(
          icon: const Icon(Icons.cloud_done),
          tooltip: '已同步',
          onPressed: null,
          disabledColor: foregroundColor.withOpacity(0.6),
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
