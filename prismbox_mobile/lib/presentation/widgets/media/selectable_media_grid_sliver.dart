// lib/presentation/widgets/media/selectable_media_grid_sliver.dart

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/services/asset_entity_loader.dart';
import 'package:prismbox/presentation/widgets/media/selectable_media_item.dart';

/// 可选择的媒体网格 Sliver（用于 CustomScrollView）
/// 支持多选模式和选中状态显示
class SelectableMediaGridSliver extends StatefulWidget {
  /// 资产列表
  final List<BaseAsset> assets;

  /// 是否启用选择模式
  final bool selectionActive;

  /// 已选中的资产ID集合
  final Set<String> selectedIds;

  /// 点击回调（正常模式下）
  final void Function(BaseAsset asset, int index)? onTap;

  /// 选择切换回调（多选模式下）
  final void Function(BaseAsset asset)? onSelectionToggle;

  /// 长按回调（用于进入多选模式）
  final void Function(BaseAsset asset)? onLongPress;

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

  /// 预加载范围（前后各预加载多少张图片）
  final int preloadRange;

  /// AssetEntity 加载器（可选，用于延迟获取）
  final AssetEntityLoader? assetEntityLoader;

  const SelectableMediaGridSliver({
    super.key,
    required this.assets,
    required this.selectionActive,
    required this.selectedIds,
    this.onTap,
    this.onSelectionToggle,
    this.onLongPress,
    this.crossAxisCount = 4,
    this.crossAxisSpacing = 2.0,
    this.mainAxisSpacing = 2.0,
    this.childAspectRatio = 1.0,
    this.serverUrl,
    this.preloadRange = 2,
    this.assetEntityLoader,
  });

  @override
  State<SelectableMediaGridSliver> createState() =>
      _SelectableMediaGridSliverState();
}

class _SelectableMediaGridSliverState
    extends State<SelectableMediaGridSliver> {
  /// 可见的索引集合
  final Set<int> _visibleIndices = {};

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
        (context, index) {
          final asset = widget.assets[index];
          final isSelected = widget.selectedIds.contains(asset.id);

          return VisibilityDetector(
            key: Key('selectable_media_$index'),
            onVisibilityChanged: (info) {
              final isVisible = info.visibleFraction > 0;
              setState(() {
                if (isVisible) {
                  _visibleIndices.add(index);
                } else {
                  _visibleIndices.remove(index);
                }
              });
            },
            child: SelectableMediaItem(
              asset: asset,
              isSelected: isSelected,
              selectionActive: widget.selectionActive,
              onTap: widget.selectionActive
                  ? () => widget.onSelectionToggle?.call(asset)
                  : () => widget.onTap?.call(asset, index),
              onLongPress: widget.onLongPress != null
                  ? () => widget.onLongPress?.call(asset)
                  : null,
              serverUrl: widget.serverUrl,
              assetEntityLoader: widget.assetEntityLoader,
            ),
          );
        },
        childCount: widget.assets.length,
      ),
    );
  }
}

