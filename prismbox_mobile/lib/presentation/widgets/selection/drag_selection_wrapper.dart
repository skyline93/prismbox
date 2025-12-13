// lib/presentation/widgets/selection/drag_selection_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';

/// 拖动选择包装器
/// 在 CustomScrollView 级别添加拖动选择功能
class DragSelectionWrapper extends StatefulWidget {
  /// 子组件（通常是 CustomScrollView）
  final Widget child;

  /// 时间线分组列表
  final List<TimelineSection> sections;

  /// 每行显示的列数
  final int crossAxisCount;

  /// 子项之间的间距
  final double crossAxisSpacing;

  /// 主轴间距
  final double mainAxisSpacing;

  /// 子项的宽高比
  final double childAspectRatio;

  /// 是否启用拖动选择
  final bool enabled;

  /// 选择切换回调
  final void Function(BaseAsset asset)? onSelectionToggle;

  const DragSelectionWrapper({
    super.key,
    required this.child,
    required this.sections,
    required this.crossAxisCount,
    this.crossAxisSpacing = 2.0,
    this.mainAxisSpacing = 2.0,
    this.childAspectRatio = 1.0,
    this.enabled = true,
    this.onSelectionToggle,
  });

  @override
  State<DragSelectionWrapper> createState() => _DragSelectionWrapperState();
}

class _DragSelectionWrapperState extends State<DragSelectionWrapper> {
  bool _isDragging = false;
  Offset? _dragStartPosition;
  int? _dragStartSectionIndex;
  int? _dragStartAssetIndex;
  final Set<String> _dragSelectedAssetIds = {};

  /// 根据全局位置查找对应的资产
  BaseAsset? _findAssetAtPosition(Offset globalPosition) {
    // 遍历所有分组，查找包含该位置的资产
    for (final section in widget.sections) {
      // 这里需要获取每个分组的 RenderBox
      // 由于 SliverGrid 是虚拟化的，我们需要使用不同的方法
      // 暂时返回 null，后续优化
    }
    return null;
  }

  /// 计算矩形选择区域内的所有资产
  Set<BaseAsset> _calculateSelectionRange(
    TimelineSection section,
    int startIndex,
    int endIndex,
  ) {
    if (startIndex == endIndex) {
      if (startIndex >= 0 && startIndex < section.assets.length) {
        return {section.assets[startIndex]};
      }
      return {};
    }

    final startRow = startIndex ~/ widget.crossAxisCount;
    final startCol = startIndex % widget.crossAxisCount;
    final endRow = endIndex ~/ widget.crossAxisCount;
    final endCol = endIndex % widget.crossAxisCount;

    final minRow = startRow < endRow ? startRow : endRow;
    final maxRow = startRow > endRow ? startRow : endRow;
    final minCol = startCol < endCol ? startCol : endCol;
    final maxCol = startCol > endCol ? startCol : endCol;

    final selectedAssets = <BaseAsset>{};
    for (int row = minRow; row <= maxRow; row++) {
      for (int col = minCol; col <= maxCol; col++) {
        final index = row * widget.crossAxisCount + col;
        if (index >= 0 && index < section.assets.length) {
          selectedAssets.add(section.assets[index]);
        }
      }
    }

    return selectedAssets;
  }

  void _handlePanStart(DragStartDetails details) {
    if (!widget.enabled) return;

    setState(() {
      _isDragging = true;
      _dragStartPosition = details.globalPosition;
      _dragSelectedAssetIds.clear();
    });

    HapticFeedback.lightImpact();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDragging || !widget.enabled) return;

    // 这里需要根据拖动位置计算应该选中哪些资产
    // 由于 SliverGrid 是虚拟化的，实现比较复杂
    // 暂时不实现，后续优化
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
      _dragStartSectionIndex = null;
      _dragStartAssetIndex = null;
      _dragSelectedAssetIds.clear();
    });
  }

  void _handlePanCancel() {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
      _dragStartPosition = null;
      _dragStartSectionIndex = null;
      _dragStartAssetIndex = null;
      _dragSelectedAssetIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onPanStart: _handlePanStart,
      onPanUpdate: _handlePanUpdate,
      onPanEnd: _handlePanEnd,
      onPanCancel: _handlePanCancel,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

