// lib/presentation/widgets/media/media_grid_view.dart

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/features/media_loading/image_provider_factory.dart';
import 'package:prismbox/presentation/widgets/media/favorite_indicator.dart';
import 'package:prismbox/presentation/widgets/media/media_image_widget.dart';

/// 媒体网格 Sliver（用于 CustomScrollView）
/// 支持可见性检测和预加载相邻图片
class MediaGridSliver extends StatefulWidget {
  /// 资产列表
  final List<BaseAsset> assets;

  /// 每行显示的列数
  final int crossAxisCount;

  /// 子项之间的间距
  final double crossAxisSpacing;

  /// 主轴间距
  final double mainAxisSpacing;

  /// 子项的宽高比
  final double childAspectRatio;

  /// 服务器 URL
  final String? serverUrl;

  /// 点击回调
  final void Function(BaseAsset asset, int index)? onTap;

  /// 预加载范围（前后各预加载多少张图片）
  final int preloadRange;

  /// AssetEntity 加载器（可选，用于延迟获取）
  final AssetEntityLoader? assetEntityLoader;

  const MediaGridSliver({
    super.key,
    required this.assets,
    this.crossAxisCount = 4,
    this.crossAxisSpacing = 2.0,
    this.mainAxisSpacing = 2.0,
    this.childAspectRatio = 1.0,
    this.serverUrl,
    this.onTap,
    this.preloadRange = 2,
    this.assetEntityLoader,
  });

  @override
  State<MediaGridSliver> createState() => _MediaGridSliverState();
}

class _MediaGridSliverState extends State<MediaGridSliver> {
  /// 可见的索引集合
  final Set<int> _visibleIndices = {};

  /// 预加载的 Provider 集合
  final Map<int, ImageProvider> _preloadedProviders = {};

  @override
  void dispose() {
    // 清理预加载的 Provider
    _preloadedProviders.clear();
    super.dispose();
  }

  /// 处理可见性变化
  void _onVisibilityChanged(int index, VisibilityInfo visibilityInfo) {
    final isVisible = visibilityInfo.visibleFraction > 0;

    setState(() {
      if (isVisible) {
        _visibleIndices.add(index);
        _preloadAdjacentImages(index);
      } else {
        _visibleIndices.remove(index);
        _cancelPreload(index);
      }
    });
  }

  /// 预加载相邻图片
  void _preloadAdjacentImages(int index) {
    final startIndex = (index - widget.preloadRange).clamp(
      0,
      widget.assets.length - 1,
    );
    final endIndex = (index + widget.preloadRange).clamp(
      0,
      widget.assets.length - 1,
    );

    for (int i = startIndex; i <= endIndex; i++) {
      if (i != index && !_preloadedProviders.containsKey(i)) {
        final asset = widget.assets[i];
        final provider = getThumbnailImageProvider(
          asset,
          size: const Size(200, 200),
          serverUrl: widget.serverUrl,
        );

        if (provider != null) {
          _preloadedProviders[i] = provider;
          // 预加载图片
          precacheImage(provider, context);
        }
      }
    }
  }

  /// 取消预加载
  void _cancelPreload(int index) {
    final startIndex = (index - widget.preloadRange).clamp(
      0,
      widget.assets.length - 1,
    );
    final endIndex = (index + widget.preloadRange).clamp(
      0,
      widget.assets.length - 1,
    );

    // 检查这些索引是否还在可见范围内
    bool shouldCancel = true;
    for (int i = startIndex; i <= endIndex; i++) {
      if (_visibleIndices.contains(i)) {
        shouldCancel = false;
        break;
      }
    }

    if (shouldCancel) {
      // 清理预加载的 Provider（实际取消由 ImageProvider 的取消机制处理）
      for (int i = startIndex; i <= endIndex; i++) {
        _preloadedProviders.remove(i);
      }
    }
  }

  /// 构建子项 widget
  Widget _buildItem(BuildContext context, int index) {
    final asset = widget.assets[index];

    return VisibilityDetector(
      key: Key('media_$index'),
      onVisibilityChanged: (info) => _onVisibilityChanged(index, info),
      child: GestureDetector(
        onTap: () => widget.onTap?.call(asset, index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaImageWidget(
              asset: asset,
              isThumbnail: true,
              serverUrl: widget.serverUrl,
              assetEntityLoader: widget.assetEntityLoader,
            ),
            // 收藏指示器（左下角）
            FavoriteIndicator(isFavorite: asset.isFavorite),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildItem(context, index),
        childCount: widget.assets.length,
      ),
    );
  }
}

/// 媒体网格视图
/// 支持可见性检测和预加载相邻图片
class MediaGridView extends StatefulWidget {
  /// 资产列表
  final List<BaseAsset> assets;

  /// 每行显示的列数
  final int crossAxisCount;

  /// 子项之间的间距
  final double crossAxisSpacing;

  /// 主轴间距
  final double mainAxisSpacing;

  /// 子项的宽高比
  final double childAspectRatio;

  /// 服务器 URL
  final String? serverUrl;

  /// 点击回调
  final void Function(BaseAsset asset, int index)? onTap;

  /// 预加载范围（前后各预加载多少张图片）
  final int preloadRange;

  /// AssetEntity 加载器（可选，用于延迟获取）
  final AssetEntityLoader? assetEntityLoader;

  const MediaGridView({
    super.key,
    required this.assets,
    this.crossAxisCount = 4,
    this.crossAxisSpacing = 2.0,
    this.mainAxisSpacing = 2.0,
    this.childAspectRatio = 1.0,
    this.serverUrl,
    this.onTap,
    this.preloadRange = 2,
    this.assetEntityLoader,
  });

  @override
  State<MediaGridView> createState() => _MediaGridViewState();
}

class _MediaGridViewState extends State<MediaGridView> {
  /// 可见的索引集合
  final Set<int> _visibleIndices = {};

  /// 预加载的 Provider 集合
  final Map<int, ImageProvider> _preloadedProviders = {};

  @override
  void dispose() {
    // 清理预加载的 Provider
    _preloadedProviders.clear();
    super.dispose();
  }

  /// 处理可见性变化
  void _onVisibilityChanged(int index, VisibilityInfo visibilityInfo) {
    final isVisible = visibilityInfo.visibleFraction > 0;

    setState(() {
      if (isVisible) {
        _visibleIndices.add(index);
        _preloadAdjacentImages(index);
      } else {
        _visibleIndices.remove(index);
        _cancelPreload(index);
      }
    });
  }

  /// 预加载相邻图片
  void _preloadAdjacentImages(int index) {
    final startIndex = (index - widget.preloadRange).clamp(
      0,
      widget.assets.length - 1,
    );
    final endIndex = (index + widget.preloadRange).clamp(
      0,
      widget.assets.length - 1,
    );

    for (int i = startIndex; i <= endIndex; i++) {
      if (i != index && !_preloadedProviders.containsKey(i)) {
        final asset = widget.assets[i];
        final provider = getThumbnailImageProvider(
          asset,
          size: const Size(200, 200),
          serverUrl: widget.serverUrl,
        );

        if (provider != null) {
          _preloadedProviders[i] = provider;
          // 预加载图片
          precacheImage(provider, context);
        }
      }
    }
  }

  /// 取消预加载
  void _cancelPreload(int index) {
    final startIndex = (index - widget.preloadRange).clamp(
      0,
      widget.assets.length - 1,
    );
    final endIndex = (index + widget.preloadRange).clamp(
      0,
      widget.assets.length - 1,
    );

    // 检查这些索引是否还在可见范围内
    bool shouldCancel = true;
    for (int i = startIndex; i <= endIndex; i++) {
      if (_visibleIndices.contains(i)) {
        shouldCancel = false;
        break;
      }
    }

    if (shouldCancel) {
      // 清理预加载的 Provider（实际取消由 ImageProvider 的取消机制处理）
      for (int i = startIndex; i <= endIndex; i++) {
        _preloadedProviders.remove(i);
      }
    }
  }

  /// 构建子项 widget
  Widget _buildItem(BuildContext context, int index) {
    final asset = widget.assets[index];

    return VisibilityDetector(
      key: Key('media_$index'),
      onVisibilityChanged: (info) => _onVisibilityChanged(index, info),
      child: GestureDetector(
        onTap: () => widget.onTap?.call(asset, index),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaImageWidget(
              asset: asset,
              isThumbnail: true,
              serverUrl: widget.serverUrl,
              assetEntityLoader: widget.assetEntityLoader,
            ),
            // 收藏指示器（左下角）
            FavoriteIndicator(isFavorite: asset.isFavorite),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: widget.assets.length,
      itemBuilder: (context, index) => _buildItem(context, index),
    );
  }
}
