// lib/presentation/widgets/selection/selection_bottom_bar.dart

import 'package:flutter/material.dart';

/// 选择底部操作栏
/// 提供上传、全选等操作按钮
class SelectionBottomBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onUpload;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeselectAll;
  final bool isAllSelected;

  const SelectionBottomBar({
    super.key,
    required this.selectedCount,
    required this.onUpload,
    this.onSelectAll,
    this.onDeselectAll,
    required this.isAllSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 全选/取消全选按钮
            if (onSelectAll != null && onDeselectAll != null)
              IconButton(
                icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all),
                onPressed: isAllSelected ? onDeselectAll : onSelectAll,
                tooltip: isAllSelected ? '取消全选' : '全选',
              ),
            
            // 上传按钮
            Expanded(
              child: ElevatedButton.icon(
                onPressed: selectedCount > 0 ? onUpload : null,
                icon: const Icon(Icons.cloud_upload),
                label: Text('上传 ($selectedCount)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

