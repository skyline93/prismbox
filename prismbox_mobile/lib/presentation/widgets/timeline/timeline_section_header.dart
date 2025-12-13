// lib/presentation/widgets/timeline/timeline_section_header.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';

/// 时间线分组标题组件
/// 
/// 显示时间段的标题信息，可选显示照片数量
/// 在选择模式下，可以显示复选框来选择整个分组
class TimelineSectionHeader extends StatelessWidget {
  /// 时间线分组数据
  final TimelineSection section;

  /// 是否显示照片数量
  final bool showAssetCount;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 背景颜色
  final Color? backgroundColor;

  /// 是否启用选择模式
  final bool selectionActive;

  /// 该分组是否全部选中
  final bool isSectionAllSelected;

  /// 选择整个分组的回调
  final VoidCallback? onSectionToggle;

  const TimelineSectionHeader({
    super.key,
    required this.section,
    this.showAssetCount = true,
    this.padding,
    this.backgroundColor,
    this.selectionActive = false,
    this.isSectionAllSelected = false,
    this.onSectionToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePadding = padding ??
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        );

    return Container(
      padding: effectivePadding,
      color: backgroundColor ?? theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          Text(
            section.displayTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showAssetCount) ...[
            const Spacer(),
            Text(
              '${section.assets.length} 张',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
          // 选择模式下的复选框
          if (selectionActive && onSectionToggle != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isSectionAllSelected
                    ? Icons.check_circle_rounded
                    : Icons.check_circle_outline_rounded,
                size: 24,
                color: isSectionAllSelected
                    ? const Color(0xFF4285F4) // 谷歌蓝
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                onSectionToggle?.call();
              },
              tooltip: isSectionAllSelected ? '取消选择该日期' : '选择该日期所有照片',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

