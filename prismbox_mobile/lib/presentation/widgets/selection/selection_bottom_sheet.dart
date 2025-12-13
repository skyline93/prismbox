// lib/presentation/widgets/selection/selection_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 选择底部抽屉
/// 使用 DraggableScrollableSheet 实现可拖拽的底部抽屉
class SelectionBottomSheet extends ConsumerStatefulWidget {
  final int selectedCount;
  final VoidCallback onUpload;
  final bool isAllSelected;

  const SelectionBottomSheet({
    super.key,
    required this.selectedCount,
    required this.onUpload,
    required this.isAllSelected,
  });

  @override
  ConsumerState<SelectionBottomSheet> createState() => _SelectionBottomSheetState();
}

class _SelectionBottomSheetState extends ConsumerState<SelectionBottomSheet> {
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
    return DraggableScrollableSheet(
      initialChildSize: 0.24,
      minChildSize: 0.24,
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
                  children: <Widget>[
                    const SizedBox(height: 12),
                    _CustomDraggingHandle(),
                    const SizedBox(height: 12),
                    // 操作按钮
                    SizedBox(
                      height: 120,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        children: [
                          // 上传按钮
                          _ControlBoxButton(
                            iconData: Icons.cloud_upload,
                            label: '上传',
                            onPressed: widget.selectedCount > 0 ? widget.onUpload : null,
                          ),
                        ],
                      ),
                    ),
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

  const _ControlBoxButton({
    required this.iconData,
    required this.label,
    this.onPressed,
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
          Icon(iconData, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w400),
            maxLines: 3,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

