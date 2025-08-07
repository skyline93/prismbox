import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/ui/media/widgets/media_thumbnail_widget.dart';

@RoutePage()
class MediaPage extends HookConsumerWidget {
  const MediaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineState = ref.watch(timelineViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('所有照片')),
      body: RefreshIndicator(
        child: _buildBody(context, timelineState),
        onRefresh: () async => {print("下拉刷新")},
      ),
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
        print(
          "mediaEntity: index: $index, mediaEntity: ${mediaEntity.toString()}",
        );
        // 假设你有一个 MediaThumbnailWidget 来显示每个媒体项
        return GestureDetector(
          child: Stack(
            fit: StackFit.expand,
            children: [MediaThumbnailWidget(entity: mediaEntity)],
          ),
        );

        // return MediaThumbnailWidget(entity: mediaEntity);
      },
    );
  }
}
