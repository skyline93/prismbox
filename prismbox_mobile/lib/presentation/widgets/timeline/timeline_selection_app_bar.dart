import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';

/// 时间线选择模式 AppBar
///
/// 显示选择模式下的 SliverAppBar，包含关闭按钮、选中数量显示和全选按钮
class TimelineSelectionAppBar extends ConsumerWidget {
  const TimelineSelectionAppBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionCount = ref.watch(
      assetSelectionProvider.select((s) => s.count),
    );
    final timelineSectionsAsync = ref.watch(timelineSectionsProvider);
    final isAllSelected = _isAllSelected(ref, timelineSectionsAsync);

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      automaticallyImplyLeading: false,
      leading: SizedBox(
        width: 120, // 限制 leading 区域的最大宽度
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 使用 InkWell + Icon 替代 IconButton，更紧凑
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  ref.read(assetSelectionProvider.notifier).deactivate();
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            // 使用 Expanded 确保文本可以适应剩余空间并防止溢出
            Expanded(
              child: Text(
                '${selectionCount}张',
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
      actions: [
        // 全选按钮（带"全选"文字，风格与单选框一致）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              if (isAllSelected) {
                _handleDeselectAll(ref);
              } else {
                _handleSelectAll(ref);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAllSelected
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 24,
                  color: isAllSelected
                      ? const Color(0xFF4285F4) // 谷歌蓝
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '全选',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      elevation: 0,
    );
  }

  /// 检查是否全选
  bool _isAllSelected(
    WidgetRef ref,
    AsyncValue<List<TimelineSection>> timelineSectionsAsync,
  ) {
    final selectedIds = ref.read(
      assetSelectionProvider.select((s) => s.selectedIds),
    );

    return timelineSectionsAsync.when(
      data: (sections) {
        final allAssetIds = <String>[];
        for (final section in sections) {
          allAssetIds.addAll(section.assets.map((a) => a.id));
        }
        return selectedIds.length == allAssetIds.length &&
            allAssetIds.every((id) => selectedIds.contains(id));
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// 处理全选
  void _handleSelectAll(WidgetRef ref) {
    final timelineSectionsAsync = ref.read(timelineSectionsProvider);
    timelineSectionsAsync.whenData((sections) {
      final allAssetIds = <String>[];
      for (final section in sections) {
        allAssetIds.addAll(section.assets.map((a) => a.id));
      }
      ref.read(assetSelectionProvider.notifier).selectAll(allAssetIds);
    });
  }

  /// 处理取消全选
  void _handleDeselectAll(WidgetRef ref) {
    ref.read(assetSelectionProvider.notifier).clear();
  }
}
