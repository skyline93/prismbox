import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
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
import 'package:prismbox/presentation/widgets/timeline/timeline_normal_app_bar.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_permission_denied_view.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_selection_app_bar.dart';
import 'package:prismbox/providers/navigation/timeline_scroll_to_top_provider.dart';
import 'package:prismbox/providers/navigation/timeline_grid_columns_provider.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';

/// 照片时间线页面
///
/// 显示系统相册中的媒体资源
@RoutePage()
class MainTimelinePage extends ConsumerStatefulWidget {
  const MainTimelinePage({super.key});

  @override
  ConsumerState<MainTimelinePage> createState() => _MainTimelinePageState();
}

class _MainTimelinePageState extends ConsumerState<MainTimelinePage>
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
    // 性能优化说明：ref.listen 必须在 build 方法中调用，这是 Riverpod 的设计要求
    // Riverpod 会自动处理重复注册的问题，所以这里不会导致性能问题
    ref.listen<bool>(timelineScrollToTopProvider, (previous, next) {
      if (next && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 监听选择状态变化，当进入选择模式时恢复滚动位置
    // 由于 Sliver 列表重新构建需要多个布局周期，使用多个 postFrameCallback 确保布局完全稳定
    // 注意：ref.listen 必须在 build 方法中调用，这是 Riverpod 的设计要求
    ref.listen<AssetSelectionState>(assetSelectionProvider, (previous, next) {
      // 当从非激活状态变为激活状态时，恢复之前保存的滚动位置
      if (previous != null &&
          !previous.isActive &&
          next.isActive &&
          _scrollPositionManager.hasSavedOffset) {
        _scrollPositionManager.restoreScrollOffset();
      }
    });

    // 性能优化：使用 select 精准订阅，只订阅需要的字段，避免整个状态变化时重建
    final isSelectionActive = ref.watch(
      assetSelectionProvider.select((s) => s.isActive),
    );
    final selectedIds = ref.watch(
      assetSelectionProvider.select((s) => s.selectedIds),
    );
    final selectionCount = ref.watch(
      assetSelectionProvider.select((s) => s.count),
    );

    // 监听网格列数变化（用于触发重建，实际值在 _buildContentSlivers 中使用）
    ref.watch(timelineGridColumnsProvider);

    // 监听权限状态
    final permissionAsync = ref.watch(photoPermissionNotifierProvider);

    // 只有在权限已授予时才加载时间线分组数据
    final timelineSectionsAsync = permissionAsync.when(
      data: (permissionState) {
        if (permissionState is PhotoPermissionGranted) {
          return ref.watch(timelineSectionsProvider(pageId: 'main'));
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
        // 使用捏合手势来调整列数
        // 注意：只在非选择模式下启用，避免与拖动选择冲突
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
              onScrollStart: null, // 可以在这里添加滚动开始的处理逻辑
              onScroll: isSelectionActive
                  ? _dragSelectionController.handleDragScroll
                  : null,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // AppBar（多选模式下显示选择栏，否则显示正常 AppBar）
                  if (isSelectionActive)
                    const TimelineSelectionAppBar(pageId: 'main')
                  else
                    const TimelineNormalAppBar(),

                  // 时间线内容
                  ...contentSlivers,

                  // 选择模式下添加底部 padding，避免内容被底部抽屉栏遮挡
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

            // 选择底部抽屉（多选模式下显示）
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

  /// 构建内容 Sliver 列表
  List<Widget> _buildContentSlivers(
    BuildContext context,
    AsyncValue<PhotoPermissionState> permissionAsync,
    AsyncValue<List<TimelineSection>> timelineSectionsAsync,
    bool selectionActive,
    Set<String> selectedIds,
  ) {
    // 获取当前网格列数
    final gridColumns = ref.watch(timelineGridColumnsProvider);
    return permissionAsync.when(
      data: (permissionState) {
        // 如果权限未授予，显示权限提示
        if (permissionState is! PhotoPermissionGranted) {
          return [
            SliverFillRemaining(
              child: TimelinePermissionDeniedView(
                permissionState: permissionState,
              ),
            ),
          ];
        }

        // 权限已授予，显示时间线分组数据
        return timelineSectionsAsync.when(
          data: (sections) {
            if (sections.isEmpty) {
              return [
                const SliverFillRemaining(child: TimelineEmptyStateView()),
              ];
            }

            // 收集所有资产 ID（用于导航到媒体查看器）
            final allAssets = <BaseAsset>[];
            for (final section in sections) {
              allAssets.addAll(section.assets);
            }

            // 获取 AssetEntityLoader
            final assetEntityLoaderAsync = ref.watch(assetEntityLoaderProvider);

            // 构建时间线分组列表的 Sliver
            // 统一使用 SelectableTimelineSliverListBuilder，支持长按进入多选模式
            return assetEntityLoaderAsync.when(
              data: (assetEntityLoader) {
                return SelectableTimelineSliverListBuilder(
                  sections: sections,
                  selectionActive: selectionActive,
                  selectedIds: selectedIds,
                  crossAxisCount: gridColumns, // 使用 provider 的值
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1.0,
                  assetEntityLoader: assetEntityLoader,
                  onTap: selectionActive
                      ? null // 多选模式下不处理点击（由 onSelectionToggle 处理）
                      : (asset, index) {
                          // 正常模式下导航到媒体查看器
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
                          // 多选模式下切换选中状态
                          HapticFeedback.lightImpact();
                          ref
                              .read(assetSelectionProvider.notifier)
                              .toggle(asset.id);
                        }
                      : null,
                  onLongPress: (asset) {
                    // 长按进入多选模式（如果还未激活）
                    if (!selectionActive) {
                      // 保存当前滚动位置（作为保险措施，因为两个 AppBar 配置已一致）
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
                          // 选择/取消选择整个分组
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
        // 使用骨架屏效果，而不是简单的加载指示器
        // 这样可以让用户感觉页面已经在加载内容，而不是完全空白
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

  /// 处理分组切换（选择/取消选择整个分组）
  void _handleSectionToggle(WidgetRef ref, TimelineSection section) {
    final selectedIds = ref.read(
      assetSelectionProvider.select((s) => s.selectedIds),
    );
    final sectionAssetIds = section.assets.map((a) => a.id).toSet();

    // 检查该分组是否全部选中
    final isAllSelected =
        sectionAssetIds.isNotEmpty &&
        sectionAssetIds.every((id) => selectedIds.contains(id));

    if (isAllSelected) {
      // 取消选择该分组的所有照片
      for (final assetId in sectionAssetIds) {
        if (selectedIds.contains(assetId)) {
          ref.read(assetSelectionProvider.notifier).toggle(assetId);
        }
      }
    } else {
      // 选择该分组的所有照片
      for (final assetId in sectionAssetIds) {
        if (!selectedIds.contains(assetId)) {
          ref.read(assetSelectionProvider.notifier).toggle(assetId);
        }
      }
    }
  }

  /// 判断是否应该显示删除按钮
  /// 根据当前过滤模式决定
  bool _shouldShowDeleteButton(WidgetRef ref) {
    // 所有过滤模式都支持删除
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

      // 从时间线数据中获取选中的资产
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
