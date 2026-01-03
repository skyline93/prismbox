// lib/presentation/widgets/selection/trash_selection_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 回收站选择底部抽屉
/// 扩展 SelectionBottomSheet，添加恢复和永久删除按钮
class TrashSelectionBottomSheet extends ConsumerStatefulWidget {
  final int selectedCount;
  final VoidCallback? onRestore;
  final VoidCallback? onPurge;

  const TrashSelectionBottomSheet({
    super.key,
    required this.selectedCount,
    this.onRestore,
    this.onPurge,
  });

  @override
  ConsumerState<TrashSelectionBottomSheet> createState() =>
      _TrashSelectionBottomSheetState();
}

class _TrashSelectionBottomSheetState
    extends ConsumerState<TrashSelectionBottomSheet> {
  late final DraggableScrollableController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = DraggableScrollableController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minHeight = 0.12;
    final initialHeight = 0.12;

    return DraggableScrollableSheet(
      initialChildSize: initialHeight,
      minChildSize: minHeight,
      maxChildSize: 0.5,
      snap: true,
      controller: _scrollController,
      builder: (context, scrollController) {
        return Card(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          surfaceTintColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          elevation: 6.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          margin: EdgeInsets.zero,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const SizedBox(height: 8),
                    _CustomDraggingHandle(),
                    const SizedBox(height: 8),
                    // 操作按钮
                    SizedBox(
                      height: 80,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          // 恢复按钮
                          _ControlBoxButton(
                            iconData: Icons.restore,
                            label: '恢复',
                            onPressed: widget.selectedCount > 0 &&
                                    widget.onRestore != null
                                ? widget.onRestore
                                : null,
                          ),
                          // 永久删除按钮
                          _ControlBoxButton(
                            iconData: Icons.delete_forever,
                            label: '永久删除',
                            onPressed: widget.selectedCount > 0 &&
                                    widget.onPurge != null
                                ? widget.onPurge
                                : null,
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 自定义拖拽手柄
class _CustomDraggingHandle extends StatelessWidget {
  const _CustomDraggingHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 30,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
    );
  }
}

/// 控制按钮
class _ControlBoxButton extends StatelessWidget {
  final IconData iconData;
  final String label;
  final VoidCallback? onPressed;
  final bool isDestructive;

  const _ControlBoxButton({
    required this.iconData,
    required this.label,
    this.onPressed,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final minWidth = MediaQuery.of(context).size.width / 4.5;

    return MaterialButton(
      padding: const EdgeInsets.all(10),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      onPressed: onPressed != null
          ? () {
              HapticFeedback.lightImpact();
              onPressed!();
            }
          : null,
      minWidth: minWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 24,
            color: isDestructive && onPressed != null
                ? Colors.red
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
              color: isDestructive && onPressed != null
                  ? Colors.red
                  : null,
            ),
            maxLines: 3,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

