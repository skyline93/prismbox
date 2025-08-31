// lib/ui/album/page/album_page.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/routing/app_router.dart';
import 'package:mobile/ui/album/widgets/album_item_widget.dart';

@RoutePage()
class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 albumStreamProvider 的状态
    final albumsAsyncValue = ref.watch(albumStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('相册'), centerTitle: false),
      body: albumsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载相册失败: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(albumStreamProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (albums) {
          if (albums.isEmpty) {
            return const Center(child: Text('没有找到任何相册'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.8,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return AlbumItemWidget(
                album: album,
                onTap: () {
                  AutoRouter.of(context).push(
                    AlbumDetailRoute(
                      albumId: album.id,
                      albumSource: album.source,
                      albumName: album.name,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
