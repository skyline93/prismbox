import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/providers/photo_filter/photo_filter_provider.dart';

/// 时间线筛选按钮组件
///
/// 显示当前筛选模式，点击可循环切换筛选模式
/// 支持的模式：全部 → 已备份 → 未备份 → 仅云端 → 全部
class TimelineFilterButton extends ConsumerWidget {
  const TimelineFilterButton({super.key});

  // 性能优化：提取样式常量，避免在 build 中重复创建
  static const _borderRadius = BorderRadius.all(Radius.circular(16));
  static const _borderWidth = 1.0;
  static const _buttonWidth = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterMode = ref.watch(photoFilterModeProvider);
    final filterNotifier = ref.read(photoFilterModeProvider.notifier);

    // 根据模式选择文字和样式
    String text;
    Color? backgroundColor;
    Color? textColor;

    switch (filterMode) {
      case PhotoFilterModeEnum.all:
        text = '全部';
        backgroundColor = null; // 使用默认背景
        textColor = null; // 使用默认文字颜色
        break;
      case PhotoFilterModeEnum.backedUp:
        text = '已备份';
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
        textColor = Theme.of(context).colorScheme.onPrimaryContainer;
        break;
      case PhotoFilterModeEnum.notBackedUp:
        text = '未备份';
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
        textColor = Theme.of(context).colorScheme.onErrorContainer;
        break;
      case PhotoFilterModeEnum.remoteOnly:
        text = '仅云端';
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
        textColor = Theme.of(context).colorScheme.onSecondaryContainer;
        break;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        // 循环切换到下一个模式
        // 注意：由于 timelineSectionsProvider 已经 watch 了 photoFilterModeProvider，
        // 所以当筛选模式改变时，provider 会自动重新计算，无需手动 invalidate
        filterNotifier.cycle();
      },
      child: Container(
        // 固定宽度，确保四种模式下按钮大小一致
        width: _buttonWidth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: _borderRadius,
          border: backgroundColor == null
              ? Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: _borderWidth,
                )
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
