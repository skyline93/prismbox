import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../providers.dart'; // 导入我们定义的 providers
// import '../widgets/media_thumbnail_widget.dart'; // 假设你有一个显示缩略图的组件

/// 时间线屏幕，现在是一个 `HookConsumerWidget`
///
/// 它能够从 Riverpod 中读取状态，并使用 Hooks 来管理生命周期。
class TimelineScreen extends HookConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 ref.watch 来监听 timelineViewModelProvider 的状态。
    // 每当 TimelineState 发生变化时，这个 build 方法就会被重新调用，
    // UI 会自动根据最新的状态进行刷新。
    final timelineState = ref.watch(timelineViewModelProvider);

    // 在这里，UI 的构建逻辑变得非常声明式和清晰。
    // 只需根据当前的状态来决定显示什么即可。
    return Scaffold(
      appBar: AppBar(
        title: const Text('媒体库'),
        actions: [
          // 如果正在加载，显示一个加载指示器
          if (timelineState.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.0),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(context, timelineState),
    );
  }

  Widget _buildBody(BuildContext context, timelineState) {
    // 场景 1: 处于初始加载状态，且没有任何数据显示
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

    // 场景 4: 成功加载并显示媒体
    // 使用 GridView.builder 来高效地显示大量媒体项
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 每行显示4个
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: timelineState.media.length,
      itemBuilder: (context, index) {
        final mediaEntity = timelineState.media[index];
        // 假设你有一个 MediaThumbnailWidget 来显示每个媒体项
        // return MediaThumbnailWidget(entity: mediaEntity);
      },
    );
  }
}
