// lib/ui/album/widgets/album_item_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/domain/entities/unified_album_entity.dart';
import 'package:mobile/providers.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/ui/media/viewmodels/media_item_viewmodel.dart';

class AlbumItemWidget extends ConsumerWidget {
  const AlbumItemWidget({super.key, required this.album, required this.onTap});

  final UnifiedAlbumEntity album;
  final VoidCallback onTap;

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          Icons.photo_album_outlined,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    BuildContext context,
    WidgetRef ref,
    UnifiedMediaEntity coverEntity,
  ) {
    // 监听 thumbnailProvider 来获取最终的图片数据
    final thumbnailAsyncValue = ref.watch(thumbnailProvider(coverEntity));

    return thumbnailAsyncValue.when(
      data: (imageData) {
        if (imageData != null) {
          return Image.memory(
            imageData,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        }
        return _buildPlaceholder(context); // 图片数据为空
      },
      loading: () => _buildPlaceholder(context), // 正在加载图片数据
      error: (e, st) => _buildPlaceholder(context), // 加载图片数据失败
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coverEntityAsyncValue = ref.watch(albumCoverProvider(album));

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            coverEntityAsyncValue.when(
              data: (coverEntity) {
                if (coverEntity != null) {
                  // 成功获取封面实体，现在交给 _buildThumbnail 处理
                  return _buildThumbnail(context, ref, coverEntity);
                }
                // 相册为空，没有封面实体
                return _buildPlaceholder(context);
              },
              loading: () => _buildPlaceholder(context), // 正在获取封面实体
              error: (e, st) => _buildPlaceholder(context), // 获取封面实体失败
            ),

            // 底部渐变和文字
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8.0).copyWith(top: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      album.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${album.assetCount} 项',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 右上角来源图标
            Positioned(top: 6, right: 6, child: _buildSourceIcon(album.source)),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceIcon(AlbumSource source) {
    IconData iconData;
    switch (source) {
      case AlbumSource.local:
        iconData = Icons.phone_android_rounded;
        break;
      case AlbumSource.remote:
        iconData = Icons.cloud_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: Colors.white, size: 14),
    );
  }
}
