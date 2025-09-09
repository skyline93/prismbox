// lib/ui/album/page/album_detail_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/ui/media/widgets/media_body_grid.dart';

@RoutePage()
class AlbumDetailPage extends ConsumerWidget {
  final String albumId;
  final AlbumSource albumSource;
  final String albumName;

  const AlbumDetailPage({
    super.key,
    required this.albumId,
    required this.albumSource,
    required this.albumName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModelProvider = albumDetailViewModelProvider((
      albumId,
      albumSource,
    ));
    final mediaState = ref.watch(viewModelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(viewModelProvider.notifier).loadMedia(),
        child: mediaState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('加载失败: $err'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      ref.read(viewModelProvider.notifier).loadMedia(),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
          data: (mediaList) {
            if (mediaList.isEmpty) {
              return const Center(child: Text('这个相册是空的'));
            }
            // 这里我们复用 MediaBodyGrid 组件来显示网格
            // 假设 MediaBodyGrid 只需要一个媒体列表
            return MediaGridBody(media: mediaList);
          },
        ),
      ),
    );
  }
}
