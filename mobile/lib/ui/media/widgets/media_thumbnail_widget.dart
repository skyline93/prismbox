// lib/ui/media/widgets/media_thumbnail_widget.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/providers.dart';

/// ---------------------------------------------------------------------------
/// **第 1 步: 创建数据提供者 (Provider)**
///
/// 我们创建一个 `FutureProvider.family`，它负责异步获取缩略图数据。
/// - `FutureProvider`：非常适合处理一次性的异步操作，并会自动缓存结果。
/// - `.family`：允许我们根据传入的参数（这里是 `UnifiedMediaEntity`）创建不同的 Provider 实例。
///   Riverpod 会根据参数的 `hashCode` 和 `==` 来决定是否复用缓存。
/// ---------------------------------------------------------------------------
final thumbnailProvider = FutureProvider.family<Uint8List?, UnifiedMediaEntity>(
  (ref, entity) async {
    // 优先尝试通过 photo_manager 从本地相册加载高质量缩略图
    if (entity.localId != null && entity.localId!.isNotEmpty) {
      try {
        final assetEntity = await AssetEntity.fromId(entity.localId!);
        if (assetEntity != null) {
          // 请求一个合适的尺寸，这个尺寸可以根据UI需求调整
          final thumbData = await assetEntity.thumbnailDataWithSize(
            const ThumbnailSize(250, 250), // 尺寸可以适当调大以提高清晰度
          );
          if (thumbData != null) {
            return thumbData;
          }
        }
      } catch (e) {
        // 如果 photo_manager 失败（例如，用户拒绝权限或资源已被删除），
        // 打印日志，然后继续尝试后备方案。
        debugPrint(
          "无法通过 photo_manager 加载缩略图 for localId=${entity.localId}: $e",
        );
      }
    }

    // 后备方案：如果本地资源ID不可用，或 photo_manager 失败，
    // 尝试直接从文件路径异步读取文件。
    // 这是完全异步的，不会阻塞UI线程。
    if (entity.filePath != null && entity.filePath!.isNotEmpty) {
      final file = File(entity.filePath!);
      // 使用异步方法检查文件是否存在
      if (await file.exists()) {
        // 使用异步方法读取文件内容
        return await file.readAsBytes();
      }
    }

    // 后备方案 2：如果是一个仅云端的资源，则从网络下载缩略图
    if (entity.syncStatus == SyncStatus.cloudOnly && entity.cloudUuid != null) {
      try {
        // 从 ref 读取 repository 实例
        final repository = ref.read(
          mediaRepositoryProvider,
        ); // 替换为你的 repository provider
        // 调用新方法下载数据
        return await repository.downloadThumbnail(entity.cloudUuid!);
      } catch (e) {
        debugPrint("无法从云端加载缩略图 for cloudUuid=${entity.cloudUuid}: $e");
        // 如果网络请求失败，继续执行到最后返回 null
      }
    }

    // 如果所有方法都失败，返回 null，UI 将会显示占位符。
    return null;
  },
);

/// ---------------------------------------------------------------------------
/// **第 2 步: 重构UI组件 (Widget)**
///
/// `MediaThumbnailWidget` 现在是一个 `ConsumerWidget`。
/// - `ConsumerWidget`：一个来自 `flutter_riverpod` 的特殊 Widget，
///   它提供了一个 `WidgetRef` 对象，用于与 Provider 进行交互。
/// ---------------------------------------------------------------------------
class MediaThumbnailWidget extends ConsumerWidget {
  const MediaThumbnailWidget({super.key, required this.entity});

  final UnifiedMediaEntity entity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 使用 `ref.watch` 来监听 `thumbnailProvider` 的状态。
    // 当 `Future` 完成、失败或正在加载时，`ref.watch` 会通知此组件重建。
    // 因为 Provider 有缓存，所以即使多次 `watch` 同一个 `entity`，
    // 底层的异步操作也只会执行一次。
    final thumbnailAsyncValue = ref.watch(thumbnailProvider(entity));

    return GestureDetector(
      onTap: () {
        debugPrint('Tapped on media with id: ${entity.id}');
        // TODO: 在这里实现点击后的导航逻辑
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        // `AsyncValue.when` 是处理异步状态的最佳实践。
        // 它强制你处理 `data`, `loading`, 和 `error` 三种情况，
        // 使代码更加健壮和清晰。
        child: thumbnailAsyncValue.when(
          data: (thumbnailData) {
            // --- 数据加载成功 ---
            Widget imageWidget;
            if (thumbnailData != null) {
              // 如果成功获取到缩略图数据，则使用 Image.memory 显示
              imageWidget = Image.memory(
                thumbnailData,
                fit: BoxFit.cover,
                // 保留了平滑的淡入动画，提升用户体验
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
            } else {
              // 如果数据为 null (所有加载方式都失败了)，显示一个通用的占位符
              imageWidget = _buildPlaceholder();
            }

            // 使用 Stack 叠加视频信息和同步状态图标
            return Stack(
              fit: StackFit.expand,
              children: [
                imageWidget,
                if (entity.isVideo) _buildVideoGradient(),
                if (entity.isVideo) _buildVideoInfo(),
                _buildSyncStatusIcon(entity.syncStatus),
              ],
            );
          },
          loading: () {
            // --- 正在加载 ---
            // 在加载时，显示一个简单的灰色占位符。
            // 也可以在这里添加一个 `CircularProgressIndicator`。
            return Stack(
              fit: StackFit.expand,
              children: [
                _buildPlaceholder(),
                // 可以在加载时也显示同步状态
                _buildSyncStatusIcon(entity.syncStatus),
              ],
            );
          },
          error: (error, stackTrace) {
            // --- 发生错误 ---
            // 如果 Provider 的 Future 抛出未捕获的异常，会进入此分支。
            debugPrint("缩略图加载失败 for entityId=${entity.id}: $error");
            return Stack(
              fit: StackFit.expand,
              children: [
                // 显示一个明确的错误状态
                _buildPlaceholder(
                  icon: Icons.broken_image,
                  color: Colors.red.shade300,
                ),
                _buildSyncStatusIcon(entity.syncStatus),
              ],
            );
          },
        ),
      ),
    );
  }

  // 占位符抽离成一个独立的方法，便于复用
  Widget _buildPlaceholder({IconData? icon, Color? color}) {
    return Container(
      color: Colors.grey[300],
      child: Icon(
        icon ?? (entity.isVideo ? Icons.videocam : Icons.image),
        color: color ?? Colors.grey[600],
        size: 24,
      ),
    );
  }

  // --- 以下的辅助方法与原代码保持一致，因为它们只依赖于 `entity` 的同步属性 ---

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
