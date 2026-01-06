// lib/presentation/widgets/selection/selection_top_bar.dart

import 'package:flutter/material.dart';

/// 选择顶部栏
/// 显示选中数量和关闭按钮
class SelectionTopBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;

  const SelectionTopBar({
    super.key,
    required this.selectedCount,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '已选择 $selectedCount 张照片',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onClose,
            tooltip: '取消选择',
          ),
        ],
      ),
    );
  }
}

