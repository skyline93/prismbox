// lib/ui/media/widgets/media_thumbnail_widget.dart

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/app_database.dart';
import 'package:mobile/providers.dart';

/// 缩略图缓存提供者 - 用于内存缓存
/// 包含缓存大小限制和清理机制
final thumbnailCacheProvider =
    StateNotifierProvider<ThumbnailCacheNotifier, Map<String, Uint8List>>((
      ref,
    ) {
      return ThumbnailCacheNotifier();
    });

/// 缩略图缓存管理器
class ThumbnailCacheNotifier extends StateNotifier<Map<String, Uint8List>> {
  static const int _maxCacheSize = 100; // 最大缓存100个缩略图
  static const int _maxMemorySize = 50 * 1024 * 1024; // 最大50MB内存

  ThumbnailCacheNotifier() : super({});

  void addToCache(String key, Uint8List data) {
    // 检查缓存大小
    if (state.length >= _maxCacheSize) {
      _cleanupCache();
    }

    // 检查内存使用
    final currentMemoryUsage = _calculateMemoryUsage();
    if (currentMemoryUsage + data.length > _maxMemorySize) {
      _cleanupCache();
    }

    state = {...state, key: data};
  }

  void _cleanupCache() {
    // 简单的LRU策略：移除最旧的20%的缓存项
    final keysToRemove = state.keys.take((state.length * 0.2).round()).toList();
    final newCache = Map<String, Uint8List>.from(state);
    for (final key in keysToRemove) {
      newCache.remove(key);
    }
    state = newCache;
  }

  int _calculateMemoryUsage() {
    return state.values.fold(0, (sum, data) => sum + data.length);
  }

  void clearCache() {
    state = {};
  }
}

final thumbnailProvider = FutureProvider.family<Uint8List?, UnifiedMediaEntity>(
  (ref, entity) async {
    // 检查内存缓存
    final cache = ref.read(thumbnailCacheProvider);
    final cacheKey = '${entity.id}_${entity.localId ?? entity.cloudUuid}';

    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey];
    }

    Uint8List? thumbnailData;

    // 优先尝试通过 photo_manager 从本地相册加载高质量缩略图
    if (entity.localId != null && entity.localId!.isNotEmpty) {
      try {
        final assetEntity = await AssetEntity.fromId(entity.localId!);
        if (assetEntity != null) {
          // 使用默认尺寸，实际尺寸将在UI层根据屏幕密度调整
          thumbnailData = await assetEntity.thumbnailDataWithSize(
            const ThumbnailSize(200, 200),
          );
        }
      } catch (e) {
        // 记录具体错误类型，便于调试
        if (e.toString().contains('permission')) {
          debugPrint("权限被拒绝，无法访问本地相册: $e");
        } else if (e.toString().contains('not found')) {
          debugPrint("本地资源不存在: $e");
        } else {
          debugPrint("PhotoManager 加载失败: $e");
        }
      }
    }

    // 后备方案：如果本地资源ID不可用，或 photo_manager 失败，
    // 尝试从云端下载缩略图
    if (thumbnailData == null &&
        entity.syncStatus == SyncStatus.cloudOnly &&
        entity.cloudUuid != null) {
      try {
        final repository = ref.read(mediaRepositoryProvider);
        thumbnailData = await repository.downloadThumbnail(entity.cloudUuid!);
      } catch (e) {
        debugPrint("云端缩略图下载失败: $e");
      }
    }

    // 最后的后备方案：从文件路径读取并压缩
    if (thumbnailData == null &&
        entity.filePath != null &&
        entity.filePath!.isNotEmpty) {
      try {
        final file = File(entity.filePath!);
        if (await file.exists()) {
          // 读取文件并压缩
          final originalBytes = await file.readAsBytes();
          thumbnailData = await _compressImage(originalBytes, 200, 200);
        }
      } catch (e) {
        debugPrint("文件读取失败: $e");
      }
    }

    // 如果成功获取到数据，缓存到内存中
    if (thumbnailData != null) {
      ref
          .read(thumbnailCacheProvider.notifier)
          .addToCache(cacheKey, thumbnailData);
    }

    return thumbnailData;
  },
);

/// 图片压缩函数
Future<Uint8List> _compressImage(
  Uint8List bytes,
  int maxWidth,
  int maxHeight,
) async {
  try {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: maxWidth,
      targetHeight: maxHeight,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } catch (e) {
    debugPrint("图片压缩失败: $e");
    // 如果压缩失败，返回原始数据
    return bytes;
  }
}

/// ---------------------------------------------------------------------------
/// **第 2 步: 重构UI组件 (Widget)**
///
/// `MediaThumbnailWidget` 现在是一个 `ConsumerWidget`。
/// - `ConsumerWidget`：一个来自 `flutter_riverpod` 的特殊 Widget，
///   它提供了一个 `WidgetRef` 对象，用于与 Provider 进行交互。
/// ---------------------------------------------------------------------------
class MediaThumbnailWidget extends ConsumerWidget {
  final UnifiedMediaEntity entity;
  final int index; // 使用索引而不是完整列表
  final int totalCount; // 总数量用于调试
  final VoidCallback? onTap; // 添加点击回调

  const MediaThumbnailWidget({
    super.key,
    required this.entity,
    required this.index,
    required this.totalCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnailAsyncValue = ref.watch(thumbnailProvider(entity));

    return GestureDetector(
      onTap: () {
        // 使用传入的索引，避免 O(n) 的查找操作
        debugPrint(
          'Tapped on media id: ${entity.id}, index: $index/$totalCount. Navigating...',
        );

        // 使用回调函数处理导航
        if (onTap != null) {
          onTap!();
        } else {
          _navigateToDetail(context, index);
        }
      },
      child: ClipRRect(
        // borderRadius: BorderRadius.circular(4), // 添加圆角
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
                // 添加错误处理
                errorBuilder: (context, error, stackTrace) {
                  debugPrint("图片显示错误: $error");
                  return _buildPlaceholder(
                    icon: Icons.broken_image,
                    color: Colors.red.shade300,
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
                // 添加加载指示器
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
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

  // 导航到详情页面的方法
  void _navigateToDetail(BuildContext context, int index) {
    // 这个方法需要在父组件中实现，传递完整的媒体列表
    // 暂时使用一个占位符实现
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('点击了第 $index 个媒体项'),
        duration: const Duration(seconds: 1),
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
        iconWidget = _buildProgressIcon(Icons.cloud_upload, Colors.blue);
        break;
      case SyncStatus.downloading:
        iconWidget = _buildProgressIcon(Icons.cloud_download, Colors.green);
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

  Widget _buildProgressIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Color.from(alpha: 1.0, red: 1.0, green: 0.0, blue: 0.0),
              ),
            ),
          ),
        ],
      ),
    );
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
