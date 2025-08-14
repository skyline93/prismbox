// lib/ui/media/page/media_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/widgets/media_grid_view.dart';
import 'package:mobile/ui/media/widgets/media_timeline_view.dart';
// 【移除】不再需要导入 MediaThumbnailWidget
import 'package:mobile/ui/media/widgets/media_thumbnail_widget.dart';
// 【移除】不再需要直接导入 MediaState
// import 'package:mobile/ui/media/viewmodels/media_state.dart';
import 'package:mobile/ui/media/viewmodels/media_viewmodel.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 【调整】mediaState 现在是 MediaState.loading/data/error 之一
    final mediaState = ref.watch(mediaViewModelProvider);
    final viewModel = ref.read(mediaViewModelProvider.notifier);

    // 【新增】直接 watch 独立的 provider 来获取同步状态
    final isSyncing = ref.watch(isSyncingWithCloudProvider);
    final viewMode = ref.watch(mediaViewTypeProvider);

    // 【调整】监听独立的 cloudSyncErrorProvider
    ref.listen<String?>(
      cloudSyncErrorProvider, // 监听目标从 viewModelProvider.select 改为独立的 provider
      (previous, newError) {
        if (newError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(newError)),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              action: SnackBarAction(
                label: '重试',
                textColor: Colors.white,
                onPressed: () {
                  viewModel.syncWithCloud();
                },
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('所有照片'),
        actions: [
          // 【调整】使用从独立 provider 获取的 isSyncing 状态
          if (isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_cache') {
                ref.read(thumbnailCacheProvider.notifier).clearCache();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('缓存已清理')));
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('清理缓存'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              viewMode == MediaViewType.grid
                  ? Icons.view_timeline_outlined
                  : Icons.grid_view_outlined,
            ),
            onPressed: () {
              final notifier = ref.read(mediaViewTypeProvider.notifier);
              notifier.state = viewMode == MediaViewType.grid
                  ? MediaViewType.timeline
                  : MediaViewType.grid;
            },
          ),
        ],
      ),
      // 【核心修改】使用 mediaState.when 来构建主体 UI，不再需要 _buildBody 方法
      body: RefreshIndicator(
        onRefresh: viewModel.syncWithCloud, // 可以直接传递方法引用
        child: mediaState.when(
          // 状态一：加载中
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '正在加载媒体库...',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  '请稍候',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          // 状态二：发生错误
          error: (error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '出错了：\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.retry, // 直接引用重试方法
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          ),
          // 状态三：成功获取数据
          data: (media) {
            // 在 data 状态内部，处理列表为空的情况
            if (media.isEmpty) {
              return LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '相册为空',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '下拉以从云端同步',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[500]),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: viewModel.syncWithCloud,
                              icon: const Icon(Icons.sync),
                              label: const Text('立即同步'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            // 如果列表不为空，则根据 viewMode 显示不同的视图
            switch (viewMode) {
              case MediaViewType.grid:
                return MediaGridView(media: media);
              case MediaViewType.timeline:
                return MediaTimelineView(media: media);
            }
          },
        ),
      ),
    );
  }
}
