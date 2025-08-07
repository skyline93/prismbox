import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/app_database.dart';

/// 一个用于在网格中显示媒体（图片或视频）缩略图的组件。
///
/// 它会异步加载来自 `photo_manager` 的高质量缩略图，并根据媒体的状态
///（如是否为视频、同步状态等）在上方叠加相应的信息图标。
class MediaThumbnailWidget extends StatelessWidget {
  const MediaThumbnailWidget({super.key, required this.entity});

  // 现在这里的 `entity` 类型会正确地引用您项目中唯一的 UnifiedMediaEntity
  final UnifiedMediaEntity entity;

  /// 异步获取缩略图数据。
  Future<Uint8List?> _getThumbnailData() async {
    if (entity.localId == null) return null;

    try {
      final assetEntity = await AssetEntity.fromId(entity.localId!);
      if (assetEntity != null) {
        final thumbData = await assetEntity.thumbnailDataWithSize(
          const ThumbnailSize(200, 200),
        );
        return thumbData;
      }
    } catch (e) {
      debugPrint("无法通过 photo_manager 加载缩略图 for localId=${entity.localId}: $e");
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('Tapped on media with id: ${entity.id}');
        // TODO: 在这里实现点击后的导航逻辑，例如跳转到媒体详情页
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: FutureBuilder<Uint8List?>(
          future: _getThumbnailData(),
          builder: (context, snapshot) {
            Widget imageWidget;
            final thumbnailData = snapshot.data;

            if (snapshot.connectionState == ConnectionState.done &&
                thumbnailData != null) {
              imageWidget = Image.memory(
                thumbnailData,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              );
            } else if (entity.filePath != null &&
                File(entity.filePath!).existsSync()) {
              imageWidget = Image.file(
                File(entity.filePath!),
                fit: BoxFit.cover,
              );
            } else {
              imageWidget = Container(
                color: Colors.grey[300],
                child: Icon(
                  entity.isVideo ? Icons.videocam : Icons.image,
                  color: Colors.grey[600],
                ),
              );
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                imageWidget,
                if (entity.isVideo) _buildVideoGradient(),
                if (entity.isVideo) _buildVideoInfo(),
                // 3. 使用您更新后的 SyncStatus 枚举
                _buildSyncStatusIcon(entity.syncStatus),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoGradient() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black54],
            stops: [0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Positioned(
      bottom: 4,
      left: 4,
      child: Row(
        children: [
          const Icon(Icons.play_circle_filled, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            _formatDuration(entity.durationSec ?? 0),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 根据您项目中的实际 SyncStatus 枚举构建右上角的图标。
  Widget _buildSyncStatusIcon(SyncStatus status) {
    Widget iconWidget;
    switch (status) {
      case SyncStatus.uploading:
      case SyncStatus.downloading:
        iconWidget = Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
          ),
          child: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
        break;
      case SyncStatus.synced:
        iconWidget = _buildIconWithBackground(Icons.cloud_done, Colors.white);
        break;
      case SyncStatus.cloudOnly:
        iconWidget = _buildIconWithBackground(Icons.cloud_queue, Colors.white);
        break;
      case SyncStatus.error:
        iconWidget = _buildIconWithBackground(
          Icons.error_outline,
          Colors.redAccent,
        );
        break;
      case SyncStatus.localOnlyNotSelected:
      // 对于本地独有或未定义状态，不显示任何图标
        iconWidget = const SizedBox.shrink();
        break;
    }
    return Positioned(top: 4, right: 4, child: iconWidget);
  }

  Widget _buildIconWithBackground(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes.toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
