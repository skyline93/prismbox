// lib/presentation/pages/collections/favorite_timeline_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/presentation/pages/photos/controllers/timeline_delete_handler.dart';
import 'package:prismbox/presentation/pages/photos/controllers/timeline_drag_selection_controller.dart';
import 'package:prismbox/presentation/pages/photos/controllers/timeline_scroll_position_manager.dart';
import 'package:prismbox/presentation/pages/photos/controllers/timeline_upload_handler.dart';
import 'package:prismbox/presentation/pages/photos/listeners/timeline_event_listeners.dart';
import 'package:prismbox/presentation/pages/photos/mixins/timeline_pinch_gesture_handler.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/timeline/selectable_timeline_sliver_list.dart';
import 'package:prismbox/presentation/widgets/selection/selection_bottom_sheet.dart';
import 'package:prismbox/presentation/widgets/selection/drag_selection_region.dart'
    show DragSelectionRegion;
import 'package:prismbox/presentation/widgets/timeline/timeline_empty_state_view.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_error_view.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_permission_denied_view.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_selection_app_bar.dart';
import 'package:prismbox/presentation/widgets/backup/backup_status_indicator.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_filter_button.dart';
import 'package:prismbox/presentation/widgets/user/user_profile_indicator.dart';
import 'package:prismbox/providers/navigation/timeline_scroll_to_top_provider.dart';
import 'package:prismbox/providers/navigation/timeline_grid_columns_provider.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';

/// 最近添加时间线页面
///
/// 显示最近添加的媒体资源（按更新时间排序），支持本地/远程切换
@RoutePage()
class RecentlyAddedTimelinePage extends ConsumerStatefulWidget {
  const RecentlyAddedTimelinePage({super.key});

  @override
  ConsumerState<RecentlyAddedTimelinePage> createState() =>
      _RecentlyAddedTimelinePageState();
}

class _RecentlyAddedTimelinePageState
    extends ConsumerState<RecentlyAddedTimelinePage>
    with TimelinePinchGestureHandler {
  final ScrollController _scrollController = ScrollController();

  // 控制器实例
  late final TimelineEventListeners _eventListeners;
  late final TimelineDragSelectionController _dragSelectionController;
  late final TimelineScrollPositionManager _scrollPositionManager;
  late final TimelineUploadHandler _uploadHandler;
  late final TimelineDeleteHandler _deleteHandler;

  @override
  WidgetRef get ref => super.ref;

  @override
  void initState() {
    super.initState();

    // 初始化控制器
    _eventListeners = TimelineEventListeners(ref: ref, mounted: () => mounted);
    _dragSelectionController = TimelineDragSelectionController(
      ref: ref,
      scrollController: _scrollController,
      pageId: 'recentlyAdded',
    );
    _scrollPositionManager = TimelineScrollPositionManager(
      scrollController: _scrollController,
      mounted: () => mounted,
    );
    _uploadHandler = TimelineUploadHandler(
      context: context,
      ref: ref,
      mounted: () => mounted,
    );
    _deleteHandler = TimelineDeleteHandler(
      context: context,
      ref: ref,
      mounted: () => mounted,
    );

    // 启动事件监听
    _eventListeners.start();
  }

  @override
  void dispose() {
    _eventListeners.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听滚动到顶部
    ref.listen<bool>(timelineScrollToTopProvider, (previous, next) {
      if (next && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 监听选择状态变化
    ref.listen<AssetSelectionState>(assetSelectionProvider, (previous, next) {
      if (previous != null &&
          !previous.isActive &&
          next.isActive &&
          _scrollPositionManager.hasSavedOffset) {
        _scrollPositionManager.restoreScrollOffset();
      }
    });

    // 性能优化：使用 select 精准订阅
    final isSelectionActive = ref.watch(
      assetSelectionProvider.select((s) => s.isActive),
    );
    final selectedIds = ref.watch(
      assetSelectionProvider.select((s) => s.selectedIds),
    );
    final selectionCount = ref.watch(
      assetSelectionProvider.select((s) => s.count),
    );

    // 监听网格列数变化
    ref.watch(timelineGridColumnsProvider);

    // 监听权限状态
    final permissionAsync = ref.watch(photoPermissionNotifierProvider);

    // 只有在权限已授予时才加载时间线分组数据（使用 'favorite' 页面 ID）
    final timelineSectionsAsync = permissionAsync.when(
      data: (permissionState) {
        if (permissionState is PhotoPermissionGranted) {
          return ref.watch(timelineSectionsProvider(pageId: 'recentlyAdded'));
        }
        return const AsyncValue<List<TimelineSection>>.data([]);
      },
      loading: () => const AsyncValue<List<TimelineSection>>.loading(),
      error: (error, stackTrace) =>
          AsyncValue<List<TimelineSection>>.error(error, stackTrace),
    );

    // 构建内容 Sliver 列表
    final contentSlivers = _buildContentSlivers(
      context,
      permissionAsync,
      timelineSectionsAsync,
      isSelectionActive,
      selectedIds,
    );

    return Scaffold(
      body: GestureDetector(
        onScaleStart: isSelectionActive ? null : (_) => onPinchScaleStart(),
        onScaleUpdate: isSelectionActive
            ? null
            : (details) => onPinchScaleUpdate(details),
        onScaleEnd: isSelectionActive ? null : (_) => onPinchScaleEnd(),
        child: Stack(
          children: [
            DragSelectionRegion(
              onStart: isSelectionActive
                  ? _dragSelectionController.handleDragStart
                  : null,
              onAssetEnter: isSelectionActive
                  ? _dragSelectionController.handleDragAssetEnter
                  : null,
              onEnd: isSelectionActive
                  ? _dragSelectionController.handleDragEnd
                  : null,
              onScrollStart: null,
              onScroll: isSelectionActive
                  ? _dragSelectionController.handleDragScroll
                  : null,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // AppBar（多选模式下显示选择栏，否则显示正常 AppBar）
                  if (isSelectionActive)
                    const TimelineSelectionAppBar(pageId: 'recentlyAdded')
                  else
                    _buildAppBar(context, ref),

                  // 时间线内容
                  ...contentSlivers,

                  // 选择模式下添加底部 padding
                  if (isSelectionActive)
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).size.height * 0.16 +
                            MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                ],
              ),
            ),

            // 选择底部抽屉
            if (isSelectionActive)
              SelectionBottomSheet(
                selectedCount: selectionCount,
                onUpload: _uploadHandler.handleUpload,
                onDelete: _getDeleteCallback(ref, timelineSectionsAsync),
                isAllSelected: _isAllSelected(ref, timelineSectionsAsync),
                showDeleteButton: _shouldShowDeleteButton(ref),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建 AppBar
  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: false,
      title: Row(
        children: [
          const Text('最近添加'),
          const SizedBox(width: 12),
          // 筛选模式按钮（本地/远程切换）
          const TimelineFilterButton(),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: BackupStatusIndicator(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: UserProfileIndicator(),
        ),
      ],
    );
  }

  /// 构建内容 Sliver 列表
  List<Widget> _buildContentSlivers(
    BuildContext context,
    AsyncValue<PhotoPermissionState> permissionAsync,
    AsyncValue<List<TimelineSection>> timelineSectionsAsync,
    bool selectionActive,
    Set<String> selectedIds,
  ) {
    final gridColumns = ref.watch(timelineGridColumnsProvider);
    return permissionAsync.when(
      data: (permissionState) {
        if (permissionState is! PhotoPermissionGranted) {
          return [
            SliverFillRemaining(
              child: TimelinePermissionDeniedView(
                permissionState: permissionState,
              ),
            ),
          ];
        }

        return timelineSectionsAsync.when(
          data: (sections) {
            if (sections.isEmpty) {
              return [
                const SliverFillRemaining(child: TimelineEmptyStateView()),
              ];
            }

            final allAssets = <BaseAsset>[];
            for (final section in sections) {
              allAssets.addAll(section.assets);
            }

            final assetEntityLoaderAsync = ref.watch(assetEntityLoaderProvider);

            return assetEntityLoaderAsync.when(
              data: (assetEntityLoader) {
                return SelectableTimelineSliverListBuilder(
                  sections: sections,
                  selectionActive: selectionActive,
                  selectedIds: selectedIds,
                  crossAxisCount: gridColumns,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1.0,
                  assetEntityLoader: assetEntityLoader,
                  onTap: selectionActive
                      ? null
                      : (asset, index) {
                          final assetIds = allAssets.map((a) => a.id).toList();
                          context.router.push(
                            MediaViewerRoute(
                              initialAssetId: asset.id,
                              assetIds: assetIds,
                            ),
                          );
                        },
                  onSelectionToggle: selectionActive
                      ? (asset) {
                          HapticFeedback.lightImpact();
                          ref
                              .read(assetSelectionProvider.notifier)
                              .toggle(asset.id);
                        }
                      : null,
                  onLongPress: (asset) {
                    if (!selectionActive) {
                      _scrollPositionManager.saveScrollOffset();
                      HapticFeedback.mediumImpact();
                      ref.read(assetSelectionProvider.notifier).activate();
                      ref
                          .read(assetSelectionProvider.notifier)
                          .toggle(asset.id);
                    }
                  },
                  onSectionToggle: selectionActive
                      ? (section) {
                          HapticFeedback.lightImpact();
                          _handleSectionToggle(ref, section);
                        }
                      : null,
                ).build();
              },
              loading: () => [
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, stackTrace) => [
                SliverFillRemaining(
                  child: TimelineErrorView(
                    errorMessage:
                        '加载 AssetEntityLoader 失败: ${error.toString()}',
                    title: '加载失败',
                  ),
                ),
              ],
            );
          },
          loading: () => [
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
          error: (error, stackTrace) => [
            SliverFillRemaining(
              child: TimelineErrorView(
                errorMessage: error.toString(),
                title: '加载失败',
              ),
            ),
          ],
        );
      },
      loading: () => [
        SliverFillRemaining(
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      error: (error, stackTrace) => [
        SliverFillRemaining(
          child: TimelineErrorView(
            errorMessage: '权限检查失败: ${error.toString()}',
            title: '权限检查失败',
          ),
        ),
      ],
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

  /// 处理分组切换
  void _handleSectionToggle(WidgetRef ref, TimelineSection section) {
    final selectedIds = ref.read(
      assetSelectionProvider.select((s) => s.selectedIds),
    );
    final sectionAssetIds = section.assets.map((a) => a.id).toSet();

    final isAllSelected =
        sectionAssetIds.isNotEmpty &&
        sectionAssetIds.every((id) => selectedIds.contains(id));

    if (isAllSelected) {
      for (final assetId in sectionAssetIds) {
        if (selectedIds.contains(assetId)) {
          ref.read(assetSelectionProvider.notifier).toggle(assetId);
        }
      }
    } else {
      for (final assetId in sectionAssetIds) {
        if (!selectedIds.contains(assetId)) {
          ref.read(assetSelectionProvider.notifier).toggle(assetId);
        }
      }
    }
  }

  /// 判断是否应该显示删除按钮
  bool _shouldShowDeleteButton(WidgetRef ref) {
    return true;
  }

  /// 获取删除回调函数
  VoidCallback? _getDeleteCallback(
    WidgetRef ref,
    AsyncValue<List<TimelineSection>> timelineSectionsAsync,
  ) {
    return () {
      final selectedIds = ref.read(
        assetSelectionProvider.select((s) => s.selectedIds),
      );

      if (selectedIds.isEmpty) {
        return;
      }

      timelineSectionsAsync.whenData((sections) {
        final selectedAssets = <BaseAsset>[];
        for (final section in sections) {
          for (final asset in section.assets) {
            if (selectedIds.contains(asset.id)) {
              selectedAssets.add(asset);
            }
          }
        }

        if (selectedAssets.isNotEmpty) {
          _deleteHandler.handleDelete(selectedAssets);
        }
      });
    };
  }
}
