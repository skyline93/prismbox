// lib/ui/media/page/media_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
// 导入新的 Provider 和 Widget
import 'package:mobile/ui/media/widgets/media_grid_view.dart';
import 'package:mobile/ui/media/widgets/media_timeline_view.dart';
import 'package:mobile/ui/media/viewmodels/media_state.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineViewModelProvider);
    // 监听视图模式的 provider
    final viewMode = ref.watch(mediaViewModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('所有照片'),
        // 在 AppBar 中添加一个切换视图的按钮
        actions: [
          IconButton(
            icon: Icon(
              viewMode == MediaViewMode.grid
                  ? Icons
                        .view_timeline_outlined // 当前是网格，显示时间线图标
                  : Icons.grid_view_outlined, // 当前是时间线，显示网格图标
            ),
            onPressed: () {
              // 点击时，更新视图模式的状态
              final notifier = ref.read(mediaViewModeProvider.notifier);
              notifier.state = viewMode == MediaViewMode.grid
                  ? MediaViewMode.timeline
                  : MediaViewMode.grid;
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 触发下拉刷新逻辑，例如重新从 repository 加载
          // 这里可以调用 ViewModel 中的方法
          print("下拉刷新");
        },
        // 将 buildBody 的调用移到这里，并传入 viewMode
        child: _buildBody(context, ref, timelineState, viewMode),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    MediaState timelineState,
    MediaViewMode viewMode, // 接收当前视图模式
  ) {
    // 场景 1: 初始加载
    if (timelineState.isLoading && timelineState.media.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在索引本地媒体...'),
          ],
        ),
      );
    }

    // 场景 2: 发生错误
    if (timelineState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '出错了：\n${timelineState.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // 场景 3: 媒体库为空
    if (timelineState.media.isEmpty) {
      return const Center(child: Text('媒体库为空，快去拍些照片吧！'));
    }

    // 场景 4: 根据 viewMode 动态渲染对应的视图组件
    switch (viewMode) {
      case MediaViewMode.grid:
        return MediaGridView(media: timelineState.media);
      case MediaViewMode.timeline:
        return MediaTimelineView(media: timelineState.media);
    }
  }
}
