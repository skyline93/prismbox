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
  final Set<String> _dragSelectedAssetIds = {};

  void _handlePanStart(DragStartDetails details) {
    if (!widget.enabled) return;

    setState(() {
      _isDragging = true;
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
      _dragSelectedAssetIds.clear();
    });
  }

  void _handlePanCancel() {
    if (!_isDragging) return;

    setState(() {
      _isDragging = false;
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

