// lib/presentation/pages/trash/trash_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/data/database/connection.dart';
import 'package:prismbox/features/trash/providers/trash_providers.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/presentation/pages/photos/controllers/timeline_drag_selection_controller.dart';
import 'package:prismbox/presentation/pages/photos/controllers/timeline_scroll_position_manager.dart';
import 'package:prismbox/presentation/pages/photos/mixins/timeline_pinch_gesture_handler.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/services/trash/trash_purge_service.dart';
import 'package:prismbox/services/trash/trash_restore_service.dart';
import 'package:prismbox/services/trash/trash_storage_service.dart';
import 'package:prismbox/presentation/widgets/selection/drag_selection_region.dart'
    show DragSelectionRegion;
import 'package:prismbox/presentation/widgets/selection/trash_selection_bottom_sheet.dart';
import 'package:prismbox/presentation/widgets/timeline/selectable_timeline_sliver_list.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_error_view.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_selection_app_bar.dart';
import 'package:prismbox/providers/navigation/timeline_grid_columns_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';

/// 回收站页面
/// 显示已删除的媒体资源，支持恢复和永久删除
@RoutePage()
class TrashPage extends ConsumerStatefulWidget {
  const TrashPage({super.key});

  @override
  ConsumerState<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends ConsumerState<TrashPage>
    with TimelinePinchGestureHandler {
  final ScrollController _scrollController = ScrollController();
  late final TimelineDragSelectionController _dragSelectionController;
  late final TimelineScrollPositionManager _scrollPositionManager;

  @override
  WidgetRef get ref => super.ref;

  @override
  void initState() {
    super.initState();
    _dragSelectionController = TimelineDragSelectionController(
      ref: ref,
      scrollController: _scrollController,
    );
    _scrollPositionManager = TimelineScrollPositionManager(
      scrollController: _scrollController,
      mounted: () => mounted,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 监听选择状态变化
    ref.listen<AssetSelectionState>(assetSelectionProvider, (previous, next) {
      if (previous != null &&
          !previous.isActive &&
          next.isActive &&
          _scrollPositionManager.hasSavedOffset) {
        _scrollPositionManager.restoreScrollOffset();
      }
    });

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

    // 获取回收站数据
    final trashSectionsAsync = ref.watch(trashSectionsProvider);
    final filterModeNotifier = ref.read(trashFilterModeProvider.notifier);

    // 构建内容 Sliver 列表
    final contentSlivers = _buildContentSlivers(
      context,
      trashSectionsAsync,
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
              onScroll: isSelectionActive
                  ? _dragSelectionController.handleDragScroll
                  : null,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // AppBar
                  if (isSelectionActive)
                    const TimelineSelectionAppBar()
                  else
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      snap: false,
                      title: Row(
                        children: [
                          const Text('回收站'),
                          const SizedBox(width: 12),
                          // 过滤按钮
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref
                                  .read(trashFilterModeProvider.notifier)
                                  .cycle();
                            },
                            child: Container(
                              width: 64,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(16),
                                ),
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.3),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                filterModeNotifier.displayText,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 回收站内容
                  ...contentSlivers,

                  // 选择模式下添加底部 padding
                  if (isSelectionActive)
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom:
                            MediaQuery.of(context).size.height * 0.12 +
                            MediaQuery.of(context).padding.bottom,
                      ),
                    ),
                ],
              ),
            ),

            // 选择底部抽屉（多选模式下显示）
            if (isSelectionActive)
              TrashSelectionBottomSheet(
                selectedCount: selectionCount,
                onRestore: _getRestoreCallback(ref, trashSectionsAsync),
                onPurge: _getPurgeCallback(ref, trashSectionsAsync),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建内容 Sliver 列表
  List<Widget> _buildContentSlivers(
    BuildContext context,
    AsyncValue<List<TimelineSection>> trashSectionsAsync,
    bool selectionActive,
    Set<String> selectedIds,
  ) {
    final gridColumns = ref.watch(timelineGridColumnsProvider);
    return trashSectionsAsync.when(
      data: (sections) {
        if (sections.isEmpty) {
          return [
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '回收站为空',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        // 收集所有资产 ID（用于导航到媒体查看器）
        final allAssets = <BaseAsset>[];
        for (final section in sections) {
          allAssets.addAll(section.assets);
        }

        // 获取 AssetEntityLoader
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
                  ref.read(assetSelectionProvider.notifier).toggle(asset.id);
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
                errorMessage: '加载失败: ${error.toString()}',
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

  /// 获取恢复回调函数
  VoidCallback? _getRestoreCallback(
    WidgetRef ref,
    AsyncValue<List<TimelineSection>> trashSectionsAsync,
  ) {
    return () {
      final selectedIds = ref.read(
        assetSelectionProvider.select((s) => s.selectedIds),
      );

      if (selectedIds.isEmpty) {
        return;
      }

      trashSectionsAsync.whenData((sections) {
        final selectedAssets = <BaseAsset>[];
        for (final section in sections) {
          for (final asset in section.assets) {
            if (selectedIds.contains(asset.id)) {
              selectedAssets.add(asset);
            }
          }
        }

        if (selectedAssets.isNotEmpty) {
          _handleRestore(context, ref, selectedAssets);
        }
      });
    };
  }

  /// 获取永久删除回调函数
  VoidCallback? _getPurgeCallback(
    WidgetRef ref,
    AsyncValue<List<TimelineSection>> trashSectionsAsync,
  ) {
    return () {
      final selectedIds = ref.read(
        assetSelectionProvider.select((s) => s.selectedIds),
      );

      if (selectedIds.isEmpty) {
        return;
      }

      trashSectionsAsync.whenData((sections) {
        final selectedAssets = <BaseAsset>[];
        for (final section in sections) {
          for (final asset in section.assets) {
            if (selectedIds.contains(asset.id)) {
              selectedAssets.add(asset);
            }
          }
        }

        if (selectedAssets.isNotEmpty) {
          _handlePurge(context, ref, selectedAssets);
        }
      });
    };
  }

  /// 处理恢复操作
  Future<void> _handleRestore(
    BuildContext context,
    WidgetRef ref,
    List<BaseAsset> selectedAssets,
  ) async {
    try {
      final database = await DatabaseConnection.getInstance();
      final apiService = ApiService();
      final localDao = database.localAssetDao;
      final remoteDao = database.remoteAssetDao;

      final restoreService = TrashRestoreService(
        localDao: localDao,
        remoteDao: remoteDao,
        apiService: apiService,
      );

      // 分离本地和远程资产
      final localAssets = selectedAssets.whereType<LocalAsset>().toList();
      final remoteAssets = selectedAssets.whereType<RemoteAsset>().toList();

      final localIds = localAssets.map((a) => a.id).toList();
      final remoteIds = remoteAssets.map((a) => a.id).toList();

      final successCount = await restoreService.restoreAssets(
        localAssetIds: localIds.isNotEmpty ? localIds : null,
        remoteAssetIds: remoteIds.isNotEmpty ? remoteIds : null,
      );

      // 刷新回收站数据
      // 同时 invalidate 依赖链上的所有 provider，确保数据完全刷新
      ref.invalidate(trashAssetsProvider);
      ref.invalidate(trashSectionsProvider);

      // 退出选择模式
      ref.read(assetSelectionProvider.notifier).deactivate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已恢复 $successCount 个资源'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 处理永久删除操作
  Future<void> _handlePurge(
    BuildContext context,
    WidgetRef ref,
    List<BaseAsset> selectedAssets,
  ) async {
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认永久删除'),
        content: Text(
          selectedAssets.length == 1
              ? '确定要永久删除这个资源吗？此操作无法恢复。'
              : '确定要永久删除这 ${selectedAssets.length} 个资源吗？此操作无法恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('永久删除'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      final database = await DatabaseConnection.getInstance();
      final apiService = ApiService();
      final trashStorage = TrashStorageService();
      final localDao = database.localAssetDao;
      final remoteDao = database.remoteAssetDao;

      final purgeService = TrashPurgeService(
        localDao: localDao,
        remoteDao: remoteDao,
        trashStorage: trashStorage,
        apiService: apiService,
      );

      // 分离本地和远程资产
      final localAssets = selectedAssets.whereType<LocalAsset>().toList();
      final remoteAssets = selectedAssets.whereType<RemoteAsset>().toList();

      final localIds = localAssets.map((a) => a.id).toList();
      final remoteIds = remoteAssets.map((a) => a.id).toList();

      final successCount = await purgeService.purgeAssets(
        localAssetIds: localIds.isNotEmpty ? localIds : null,
        remoteAssetIds: remoteIds.isNotEmpty ? remoteIds : null,
      );

      // 刷新回收站数据
      // 同时 invalidate 依赖链上的所有 provider，确保数据完全刷新
      ref.invalidate(trashAssetsProvider);
      ref.invalidate(trashSectionsProvider);

      // 退出选择模式
      ref.read(assetSelectionProvider.notifier).deactivate();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已永久删除 $successCount 个资源'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('永久删除失败: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
