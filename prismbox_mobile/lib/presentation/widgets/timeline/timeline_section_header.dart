// lib/presentation/widgets/timeline/timeline_section_header.dart

import 'package:flutter/material.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';

/// 时间线分组标题组件
/// 
/// 显示时间段的标题信息，可选显示照片数量
class TimelineSectionHeader extends StatelessWidget {
  /// 时间线分组数据
  final TimelineSection section;

  /// 是否显示照片数量
  final bool showAssetCount;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 背景颜色
  final Color? backgroundColor;

  const TimelineSectionHeader({
    super.key,
    required this.section,
    this.showAssetCount = true,
    this.padding,
    this.backgroundColor,
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
        ],
      ),
    );
  }
}

