// lib/ui/media/page/media_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/widgets/media_grid_view.dart';
import 'package:mobile/ui/media/widgets/media_timeline_view.dart';
import 'package:mobile/ui/media/widgets/media_thumbnail_widget.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';
import 'package:mobile/ui/media/viewmodels/media_viewmodel.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaViewModelProvider);
    final viewModel = ref.read(mediaViewModelProvider.notifier);
    final viewMode = ref.watch(mediaViewTypeProvider);

    // 监听云端同步错误状态。
    // `ref.listen` 用于订阅 `mediaViewModelProvider` 中 `cloudSyncError` 字段的变化。
    // `select` 方法用于仅关注 `cloudSyncError` 字段，避免不必要的重绘。
    // 当 `cloudSyncError` 从 `null` 变为非 `null` 值时（即发生错误），会执行回调函数。
    ref.listen<String?>(
      mediaViewModelProvider.select((state) => state.cloudSyncError),
      (previous, newError) {
        if (newError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // SnackBar 的内容区域，包含一个错误图标和错误信息文本。
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(newError)),
                ],
              ),
              // SnackBar 的背景颜色使用主题中的错误颜色。
              backgroundColor: Theme.of(context).colorScheme.error,
              // SnackBar 的操作按钮，允许用户重试云端同步。
              action: SnackBarAction(
                label: '重试',
                textColor: Colors.white,
                onPressed: () {
                  // 当用户点击“重试”按钮时，调用 ViewModel 中的 `syncWithCloud` 方法。
                  viewModel.syncWithCloud();
                },
              ),
              // SnackBar 显示的持续时间。
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
          // 【新增】在 AppBar 中添加云端同步的加载指示器
          // 当正在与云端同步时，显示一个加载动画。
          if (mediaState.isSyncingWithCloud)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white, // AppBar 图标通常是白色
                  ),
                ),
              ),
            ),

          // 缓存管理按钮
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'clear_cache':
                  ref.read(thumbnailCacheProvider.notifier).clearCache();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('缓存已清理')));
                  break;
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

          // 视图切换按钮
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
      body: RefreshIndicator(
        onRefresh: () async {
          await viewModel.syncWithCloud();
        },
        // 将 buildBody 的调用移到这里，并传入 viewMode
        child: _buildBody(context, ref, mediaState, viewMode, viewModel),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MediaState mediaState,
    MediaViewType viewMode,
    MediaViewModel viewModel,
  ) {
    // 场景 1: 初始加载
    if (mediaState.isLoading) {
      return Center(
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
      );
    }

    // 场景 2: 发生严重错误（如数据库问题）
    if (mediaState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                '出错了：\n${mediaState.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // 重试加载
                  viewModel.retry();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    // 场景 3: 媒体库为空，提供更友好的交互提示
    if (mediaState.media.isEmpty) {
      // 使用 LayoutBuilder 和 SingleChildScrollView 确保即使在内容为空时，
      // 用户仍然可以下拉以触发 RefreshIndicator。
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          viewModel.syncWithCloud();
                        },
                        icon: const Icon(Icons.sync),
                        label: const Text('立即同步'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    switch (viewMode) {
      case MediaViewType.grid:
        return MediaGridView(media: mediaState.media);
      case MediaViewType.timeline:
        return MediaTimelineView(media: mediaState.media);
    }
  }
}
