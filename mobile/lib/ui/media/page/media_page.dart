// lib/ui/media/page/media_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart'; // 确保你的 providers 都在这里
import 'package:mobile/ui/media/widgets/media_grid_view.dart';
import 'package:mobile/ui/media/widgets/media_timeline_view.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 【修改】统一使用 mediaViewModelProvider
    final mediaState = ref.watch(mediaViewModelProvider);
    final viewModel = ref.read(mediaViewModelProvider.notifier);
    final viewMode = ref.watch(mediaViewModeProvider);

    // 【新增】使用 ref.listen 专门处理一次性事件，如显示 SnackBar
    // 这比在 build 方法中判断更高效，因为它不会在每次重建时都执行。
    ref.listen<String?>(
      mediaViewModelProvider.select((state) => state.cloudSyncError),
      (previous, newError) {
        if (newError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newError),
              backgroundColor: Theme.of(context).colorScheme.error,
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

          // 您原有的视图切换按钮保持不变
          IconButton(
            icon: Icon(
              viewMode == MediaViewMode.grid
                  ? Icons.view_timeline_outlined
                  : Icons.grid_view_outlined,
            ),
            onPressed: () {
              final notifier = ref.read(mediaViewModeProvider.notifier);
              notifier.state = viewMode == MediaViewMode.grid
                  ? MediaViewMode.timeline
                  : MediaViewMode.grid;
            },
          ),
        ],
      ),
      // 【修改】将 RefreshIndicator 与 ViewModel 连接起来
      body: RefreshIndicator(
        onRefresh: () async {
          // 当用户执行下拉手势时，直接调用 ViewModel 的 syncWithCloud 方法。
          print("UI: 用户触发下拉刷新，调用 viewModel.syncWithCloud()");
          await viewModel.syncWithCloud();
        },
        // 将 buildBody 的调用移到这里，并传入 viewMode
        child: _buildBody(context, ref, mediaState, viewMode),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MediaState mediaState, // 【修改】参数名统一为 mediaState
    MediaViewMode viewMode,
  ) {
    // 【修改】场景 1: 初始加载，使用 isInitialLoading 字段
    if (mediaState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载媒体库...'),
          ],
        ),
      );
    }

    // 【修改】场景 2: 发生严重错误（如数据库问题）
    if (mediaState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '出错了：\n${mediaState.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // 【修改】场景 3: 媒体库为空，提供更友好的交互提示
    if (mediaState.media.isEmpty) {
      // 使用 LayoutBuilder 和 SingleChildScrollView 确保即使在内容为空时，
      // 用户仍然可以下拉以触发 RefreshIndicator。
      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    '相册为空\n\n下拉以从云端同步',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // 场景 4: 根据 viewMode 动态渲染对应的视图组件（此部分逻辑不变）
    switch (viewMode) {
      case MediaViewMode.grid:
        return MediaGridView(media: mediaState.media);
      case MediaViewMode.timeline:
        return MediaTimelineView(media: mediaState.media);
    }
  }
}
