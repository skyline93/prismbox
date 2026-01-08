// lib/presentation/widgets/posts/post_media_selection_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/presentation/widgets/timeline/selectable_timeline_sliver_list.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_empty_state_view.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_error_view.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';

/// 帖子媒体选择底部抽屉
/// 使用时间线组件在上滑抽屉中显示媒体选择界面
class PostMediaSelectionBottomSheet extends ConsumerStatefulWidget {
  /// 最大选择数量（默认 9）
  final int maxSelection;

  /// 已选中的资产 ID 列表（用于初始化选择状态）
  final Set<String> initialSelectedIds;

  /// 选择完成回调
  final void Function(List<String> selectedAssetIds)? onSelectionComplete;

  const PostMediaSelectionBottomSheet({
    super.key,
    this.maxSelection = 9,
    this.initialSelectedIds = const {},
    this.onSelectionComplete,
  });

  @override
  ConsumerState<PostMediaSelectionBottomSheet> createState() =>
      _PostMediaSelectionBottomSheetState();
}

class _PostMediaSelectionBottomSheetState
    extends ConsumerState<PostMediaSelectionBottomSheet> {
  late final DraggableScrollableController _scrollController;
  AssetSelectionNotifier? _selectionNotifier; // 保存 notifier 引用，避免在 dispose 中使用 ref

  @override
  void initState() {
    super.initState();
    _scrollController = DraggableScrollableController();

    // 初始化选择状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // 检查 widget 是否仍然挂载
      
      _selectionNotifier = ref.read(assetSelectionProvider.notifier);
      if (widget.initialSelectedIds.isNotEmpty) {
        _selectionNotifier?.activate();
        for (final id in widget.initialSelectedIds) {
          if (mounted) {
            _selectionNotifier?.toggle(id);
          }
        }
      } else {
        _selectionNotifier?.activate();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // 注意：不在 dispose 中调用 deactivate()，因为：
    // 1. 取消和确定按钮已经调用了 deactivate()
    // 2. 在 dispose 中修改 provider 会违反 Riverpod 规则
    // 3. 如果用户通过滑动关闭，PopScope 会处理清理
    super.dispose();
  }

  /// 获取 selection notifier（如果未初始化则从 ref 获取）
  AssetSelectionNotifier _getSelectionNotifier() {
    return _selectionNotifier ?? ref.read(assetSelectionProvider.notifier);
  }

  @override
  Widget build(BuildContext context) {
    final minHeight = 0.12;
    final initialHeight = 0.3;
    final maxHeight = 0.9;

    // 监听选择状态
    final selectionState = ref.watch(assetSelectionProvider);
    final selectedCount = selectionState.count;

    // 监听权限状态
    final permissionAsync = ref.watch(photoPermissionNotifierProvider);

    // 监听时间线数据
    final timelineSectionsAsync = permissionAsync.when(
      data: (permissionState) {
        if (permissionState is PhotoPermissionGranted) {
          return ref.watch(timelineSectionsProvider(pageId: 'post_selection'));
        }
        return const AsyncValue<List<TimelineSection>>.data([]);
      },
      loading: () => const AsyncValue<List<TimelineSection>>.loading(),
      error: (error, stackTrace) =>
          AsyncValue<List<TimelineSection>>.error(error, stackTrace),
    );

    // 获取 AssetEntityLoader
    final assetEntityLoaderAsync = ref.watch(assetEntityLoaderProvider);

    return PopScope(
      // 处理用户通过返回按钮或滑动关闭抽屉的情况
      onPopInvoked: (didPop) {
        if (didPop) {
          // 抽屉已关闭，清理选择状态
          // 使用 Future.microtask 确保在 widget 树构建完成后执行
          Future.microtask(() {
            _getSelectionNotifier().deactivate();
          });
        }
      },
      child: DraggableScrollableSheet(
        initialChildSize: initialHeight,
        minChildSize: minHeight,
        maxChildSize: maxHeight,
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
          child: Column(
            children: [
              // 顶部：拖拽手柄和标题栏
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _CustomDraggingHandle(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '选择图片',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                _getSelectionNotifier().deactivate();
                                Navigator.of(context).pop();
                              },
                              child: const Text('取消'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: selectedCount > 0
                                  ? () {
                                      final selectedIds = selectionState.selectedIds.toList();
                                      widget.onSelectionComplete?.call(selectedIds);
                                      // 使用保存的 notifier 引用或从 ref 获取
                                      _getSelectionNotifier().deactivate();
                                      Navigator.of(context).pop(selectedIds);
                                    }
                                  : null,
                              child: Text('确定 ($selectedCount/${widget.maxSelection})'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 时间线内容
              Expanded(
                child: assetEntityLoaderAsync.when(
                  data: (assetEntityLoader) {
                    return timelineSectionsAsync.when(
                      data: (sections) {
                        if (sections.isEmpty) {
                          return const TimelineEmptyStateView();
                        }

                        return CustomScrollView(
                          controller: scrollController,
                          slivers: [
                            ...SelectableTimelineSliverListBuilder(
                              sections: sections,
                              selectionActive: true,
                              selectedIds: selectionState.selectedIds,
                              crossAxisCount: 4,
                              crossAxisSpacing: 2.0,
                              mainAxisSpacing: 2.0,
                              childAspectRatio: 1.0,
                              assetEntityLoader: assetEntityLoader,
                              onSelectionToggle: (asset) {
                                // 检查是否超过最大选择数量
                                if (!selectionState.isSelected(asset.id) &&
                                    selectedCount >= widget.maxSelection) {
                                  HapticFeedback.mediumImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('最多只能选择 ${widget.maxSelection} 张图片'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                HapticFeedback.lightImpact();
                                // 使用保存的 notifier 引用或从 ref 获取
                                _getSelectionNotifier().toggle(asset.id);
                              },
                            ).build(),
                            // 底部安全区域
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: MediaQuery.of(context).padding.bottom,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stackTrace) => TimelineErrorView(
                        errorMessage: error.toString(),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => TimelineErrorView(
                    errorMessage: error.toString(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      ),
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

