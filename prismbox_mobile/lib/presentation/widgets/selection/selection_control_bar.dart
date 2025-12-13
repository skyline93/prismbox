// lib/presentation/widgets/selection/selection_control_bar.dart

import 'package:flutter/material.dart';
import 'package:prismbox/presentation/widgets/selection/selection_top_bar.dart';
import 'package:prismbox/presentation/widgets/selection/selection_bottom_bar.dart';

/// 选择控制栏组合组件
/// 组合顶部栏和底部栏
class SelectionControlBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onUpload;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final bool isAllSelected;

  const SelectionControlBar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onUpload,
    this.onSelectAll,
    this.onDeselectAll,
    required this.isAllSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelectionTopBar(
          selectedCount: selectedCount,
          onClose: onClose,
        ),
        SelectionBottomBar(
          selectedCount: selectedCount,
          onUpload: onUpload,
          onSelectAll: onSelectAll,
          onDeselectAll: onDeselectAll,
          isAllSelected: isAllSelected,
        ),
      ],
    );
  }
}

