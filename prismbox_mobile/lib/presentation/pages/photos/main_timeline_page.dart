import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/features/remote_sync/providers/remote_sync_providers.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/timeline/selectable_timeline_sliver_list.dart';
import 'package:prismbox/presentation/widgets/selection/selection_bottom_sheet.dart';
import 'package:prismbox/presentation/widgets/selection/drag_selection_region.dart'
    show DragSelectionRegion, AssetIndex, ScrollDirection;
import 'package:prismbox/presentation/widgets/backup/backup_status_indicator.dart';
import 'package:prismbox/presentation/widgets/user/user_profile_indicator.dart';
import 'package:prismbox/providers/navigation/timeline_scroll_to_top_provider.dart';
import 'package:prismbox/providers/navigation/timeline_grid_columns_provider.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';
import 'package:prismbox/providers/photo_filter/photo_filter_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
import 'package:prismbox/services/encrypted_space/providers/encrypted_space_providers.dart';
import 'package:prismbox/presentation/widgets/encrypted_space/password_verify_dialog.dart';

/// 照片时间线页面
///
/// 显示系统相册中的媒体资源
@RoutePage()
class MainTimelinePage extends ConsumerStatefulWidget {
  const MainTimelinePage({super.key});

  @override
  ConsumerState<MainTimelinePage> createState() => _MainTimelinePageState();
}

class _MainTimelinePageState extends ConsumerState<MainTimelinePage> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<bool>? _dataSourceSwitchSubscription;
  StreamSubscription<String>? _uploadCompleteSubscription;
  StreamSubscription? _remoteSyncCompleteSubscription;
  StreamSubscription? _checksumMatchCompleteSubscription;

  /// 拖动选择相关状态
  AssetIndex? _dragAnchorIndex;
  bool _isDragging = false;
  final Set<String> _draggedAssetIds = {};

  /// 保存长按进入选择模式时的滚动位置
  double? _savedScrollOffset;

  /// 捏合手势相关状态
  int _lastColumnCount = 4;
  DateTime? _lastUpdateTime;

  // 性能优化：提取样式对象为静态常量，避免在 build 中重复创建
  static const _filterButtonBorderRadius = BorderRadius.all(Radius.circular(16));
  static const _filterButtonBorderWidth = 1.0;

  @override
  void initState() {
    super.initState();
    // 监听数据源切换
    _listenDataSourceSwitch();
    // 监听上传完成通知
    _listenUploadComplete();
    // 监听远程同步完成通知
    _listenRemoteSyncComplete();
    // 监听 checksum 匹配完成通知
    _listenChecksumMatchComplete();
  }

  @override
  void dispose() {
    _dataSourceSwitchSubscription?.cancel();
    _uploadCompleteSubscription?.cancel();
    _remoteSyncCompleteSubscription?.cancel();
    _checksumMatchCompleteSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听数据源切换通知
  /// 当同步完成后，如果数据库数据可用，会自动切换到数据库数据源
  void _listenDataSourceSwitch() {
    ref
        .read(syncCoordinatorProvider.future)
        .then((coordinator) {
          debugPrint('✅ 数据源切换监听已启动');
          _dataSourceSwitchSubscription = coordinator.dataSourceSwitchStream
              .listen(
                (shouldSwitch) {
                  if (shouldSwitch && mounted) {
                    debugPrint('✅ 收到数据源切换通知，刷新时间线数据');
                    // 刷新时间线数据，触发数据源切换
                    ref.invalidate(timelineSectionsProvider);
                    // 可选：显示提示信息（静默切换，不打扰用户）
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(
                    //     content: Text('数据已同步完成'),
                    //     duration: Duration(seconds: 2),
                    //   ),
                    // );
                  }
                },
                onError: (error) {
                  // 记录错误但不影响功能
                  debugPrint('❌ 数据源切换监听错误: $error');
                },
              );
        })
        .catchError((error) {
          debugPrint('❌ 启动数据源切换监听失败: $error');
        });
  }

  /// 监听上传完成通知
  /// 当资产上传成功并更新数据库后，刷新时间线数据以更新上传状态图标
  void _listenUploadComplete() {
    ref
        .read(uploadOrchestratorProvider.future)
        .then((orchestrator) {
          debugPrint('✅ 上传完成监听已启动');
          _uploadCompleteSubscription = orchestrator.uploadCompleteStream.listen(
            (assetId) async {
              if (mounted) {
                debugPrint('✅ 收到上传完成通知: assetId=$assetId，刷新时间线数据');
                // 短暂延迟，确保数据库事务已提交
                await Future.delayed(const Duration(milliseconds: 200));
                if (mounted) {
                  // 同时 invalidate timelineAssetsProvider 和 timelineSectionsProvider
                  // 确保数据完全刷新
                  ref.invalidate(timelineAssetsProvider());
                  ref.invalidate(timelineSectionsProvider);
                  debugPrint('✅ 已刷新时间线数据');
                }
              }
            },
            onError: (error) {
              // 记录错误但不影响功能
              debugPrint('❌ 上传完成监听错误: $error');
            },
          );
        })
        .catchError((error) {
          debugPrint('❌ 启动上传完成监听失败: $error');
        });
  }

  /// 监听远程同步完成通知
  /// 当远程同步完成后，刷新时间线数据以更新上传状态图标
  void _listenRemoteSyncComplete() {
    ref
        .read(remoteSyncCoordinatorProvider.future)
        .then((coordinator) {
          debugPrint('✅ 远程同步完成监听已启动');
          _remoteSyncCompleteSubscription = coordinator.remoteSyncCompleteStream.listen(
            (result) async {
              if (mounted && result.addedCount > 0) {
                debugPrint('✅ 收到远程同步完成通知: 新增 ${result.addedCount} 个资产，刷新时间线数据');
                // 短暂延迟，确保数据库事务已提交
                await Future.delayed(const Duration(milliseconds: 200));
                if (mounted) {
                  // 刷新时间线数据，确保 LocalAsset 对象获取到最新的 remoteAssetId
                  ref.invalidate(timelineAssetsProvider());
                  ref.invalidate(timelineSectionsProvider);
                  debugPrint('✅ 已刷新时间线数据');
                }
              }
            },
            onError: (error) {
              // 记录错误但不影响功能
              debugPrint('❌ 远程同步完成监听错误: $error');
            },
          );
        })
        .catchError((error) {
          debugPrint('❌ 启动远程同步完成监听失败: $error');
        });
  }

  /// 监听 checksum 匹配完成通知
  /// 当 checksum 匹配完成后，刷新时间线数据以更新上传状态图标
  void _listenChecksumMatchComplete() {
    ref
        .read(syncCoordinatorProvider.future)
        .then((coordinator) {
          debugPrint('✅ Checksum 匹配完成监听已启动');
          _checksumMatchCompleteSubscription = coordinator.checksumMatchCompleteStream.listen(
            (_) async {
              if (mounted) {
                debugPrint('✅ 收到 checksum 匹配完成通知，刷新时间线数据');
                // 短暂延迟，确保数据库事务已提交
                await Future.delayed(const Duration(milliseconds: 200));
                if (mounted) {
                  // 刷新时间线数据，确保 LocalAsset 对象获取到最新的 remoteAssetId
                  ref.invalidate(timelineAssetsProvider());
                  ref.invalidate(timelineSectionsProvider);
                  debugPrint('✅ 已刷新时间线数据');
                }
              }
            },
            onError: (error) {
              // 记录错误但不影响功能
              debugPrint('❌ Checksum 匹配完成监听错误: $error');
            },
          );
        })
        .catchError((error) {
          debugPrint('❌ 启动 Checksum 匹配完成监听失败: $error');
        });
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
          _savedScrollOffset != null &&
          _scrollController.hasClients) {
        // 使用多个 postFrameCallback 确保布局完全稳定
        // Sliver 列表重新构建需要多个布局周期才能完全稳定
        Future.microtask(() {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // 等待第二个 frame 确保 Sliver 布局完全稳定
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // 再等待一个 frame 确保所有布局计算完成
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted &&
                    _scrollController.hasClients &&
                    _savedScrollOffset != null) {
                  // 确保滚动位置在有效范围内
                  final maxScrollExtent =
                      _scrollController.position.maxScrollExtent;
                  final targetOffset = _savedScrollOffset!.clamp(
                    0.0,
                    maxScrollExtent,
                  );
                  _scrollController.jumpTo(targetOffset);
                  _savedScrollOffset = null; // 清除保存的位置
                }
              });
            });
          });
        });
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
    final gridColumns = ref.watch(timelineGridColumnsProvider);

    // 监听权限状态
    final permissionAsync = ref.watch(photoPermissionNotifierProvider);

    // 只有在权限已授予时才加载时间线分组数据
    final timelineSectionsAsync = permissionAsync.when(
      data: (permissionState) {
        if (permissionState is PhotoPermissionGranted) {
          return ref.watch(timelineSectionsProvider);
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
        onScaleStart: isSelectionActive
            ? null
            : (details) {
                _lastColumnCount = gridColumns;
                _lastUpdateTime = null;
              },
        onScaleUpdate: isSelectionActive
            ? null
            : (details) {
                final scale = details.scale;
                final currentColumns = ref.read(timelineGridColumnsProvider);

                // 使用累积的缩放值来计算目标列数
                // scale > 1.0 表示放大（减少列数），scale < 1.0 表示缩小（增加列数）
                final targetColumns = _calculateTargetColumns(
                  scale,
                  _lastColumnCount,
                );

                // 只有当目标列数与当前列数不同时才更新
                if (targetColumns != currentColumns &&
                    targetColumns >= 2 &&
                    targetColumns <= 8) {
                  // 添加防抖机制，避免过于频繁的更新（最小间隔 50ms）
                  final now = DateTime.now();
                  if (_lastUpdateTime == null ||
                      now.difference(_lastUpdateTime!).inMilliseconds > 50) {
                    ref
                        .read(timelineGridColumnsProvider.notifier)
                        .setColumns(targetColumns);
                    HapticFeedback.selectionClick();
                    _lastUpdateTime = now;
                  }
                }
              },
        onScaleEnd: isSelectionActive
            ? null
            : (details) {
                _lastColumnCount = ref.read(timelineGridColumnsProvider);
                _lastUpdateTime = null;
              },
        child: Stack(
          children: [
            DragSelectionRegion(
              onStart: isSelectionActive ? _handleDragStart : null,
              onAssetEnter: isSelectionActive
                  ? _handleDragAssetEnter
                  : null,
              onEnd: isSelectionActive ? _handleDragEnd : null,
              onScrollStart: isSelectionActive
                  ? _handleDragScrollStart
                  : null,
              onScroll: isSelectionActive ? _handleDragScroll : null,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // AppBar（多选模式下显示选择栏，否则显示正常 AppBar）
                  if (isSelectionActive)
                    SliverAppBar(
                      floating: true,
                      pinned: true,
                      snap: false,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer,
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
                                  ref
                                      .read(assetSelectionProvider.notifier)
                                      .deactivate();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 24,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
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
                              if (_isAllSelected(ref, timelineSectionsAsync)) {
                                _handleDeselectAll(ref);
                              } else {
                                _handleSelectAll(ref);
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isAllSelected(ref, timelineSectionsAsync)
                                      ? Icons.check_circle_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 24,
                                  color:
                                      _isAllSelected(ref, timelineSectionsAsync)
                                      ? const Color(0xFF4285F4) // 谷歌蓝
                                      : Theme.of(context).colorScheme.onSurface
                                            .withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _isAllSelected(ref, timelineSectionsAsync)
                                        ? '全选'
                                        : '全选',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
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
                    )
                  else
                    SliverAppBar(
                      floating: true,
                      pinned: true, // 与选择模式保持一致，避免布局变化导致滚动位置变动
                      snap: false,
                      title: Row(
                        children: [
                          const Text('照片'),
                          const SizedBox(width: 12),
                          // 筛选模式按钮（放在标题右侧）
                          _buildFilterButton(context, ref),
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
                    ),

                  // 时间线内容
                  ...contentSlivers,

                  // 选择模式下添加底部 padding，避免内容被底部抽屉栏遮挡
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
              SelectionBottomSheet(
                selectedCount: selectionCount,
                onUpload: () => _handleUpload(context, ref),
                onAddToEncryptedSpace: () => _handleAddToEncryptedSpace(context, ref),
                isAllSelected: _isAllSelected(ref, timelineSectionsAsync),
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
              child: _buildPermissionDeniedUI(context, permissionState),
            ),
          ];
        }

        // 权限已授予，显示时间线分组数据
        return timelineSectionsAsync.when(
          data: (sections) {
            if (sections.isEmpty) {
              return [
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无照片',
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
                      if (_scrollController.hasClients) {
                        _savedScrollOffset = _scrollController.offset;
                      }
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
                  child: Center(
                    child: Text(
                      '加载 AssetEntityLoader 失败: ${error.toString()}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.red),
                    ),
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
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '加载失败',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.invalidate(timelineSectionsProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('重试'),
                    ),
                  ],
                ),
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
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
      error: (error, stackTrace) => [
        SliverFillRemaining(
          child: Center(
            child: Text(
              '权限检查失败: ${error.toString()}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建权限被拒绝的UI
  Widget _buildPermissionDeniedUI(
    BuildContext context,
    PhotoPermissionState permissionState,
  ) {
    final isPermanentlyDenied =
        permissionState is PhotoPermissionPermanentlyDenied;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            Text(
              '需要相册权限',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              isPermanentlyDenied
                  ? '相册权限已被拒绝。请在系统设置中授予相册访问权限。'
                  : '需要相册权限才能查看您的照片。请授予相册访问权限。',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final permissionNotifier = ref.read(
                  photoPermissionNotifierProvider.notifier,
                );
                await permissionNotifier.requestPermission();
              },
              icon: const Icon(Icons.lock_open),
              label: const Text('授予权限'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理上传
  Future<void> _handleUpload(BuildContext context, WidgetRef ref) async {
    final selectedIds = ref.read(assetSelectionProvider.select((s) => s.selectedIds));
    if (selectedIds.isEmpty) return;

    try {
      // 获取用户ID
      final authService = await ref.read(authServiceProvider.future);
      final profile = await authService.getProfile();
      final userId = profile.id.toString();

      // 获取备份服务
      final backupService = await ref.read(backupServiceProvider.future);

      // 启动上传
      await backupService.startManualBackup(
        userId: userId,
        assetIds: selectedIds.toList(),
        skipDeduplication: false,
      );

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已开始上传 ${selectedIds.length} 张照片'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 退出选择模式
        ref.read(assetSelectionProvider.notifier).deactivate();
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 处理添加到加密空间
  Future<void> _handleAddToEncryptedSpace(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final selectedIds = ref.read(assetSelectionProvider.select((s) => s.selectedIds));
    if (selectedIds.isEmpty) return;

    // 保存 context 的引用，避免在异步操作后使用过期的 context
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    try {
      // 显示加载提示
      messenger.showSnackBar(
        SnackBar(
          content: Text('正在添加 ${selectedIds.length} 张照片到加密空间...'),
          duration: const Duration(seconds: 1),
        ),
      );

      // 获取加密空间服务和访问控制服务
      final encryptedSpaceService = await ref.read(
        encryptedSpaceServiceProvider.future,
      );
      final accessControlService = await ref.read(
        albumAccessControlServiceProvider.future,
      );

      // 获取或创建加密空间相册
      final albumId = await encryptedSpaceService.getOrCreateEncryptedSpaceAlbum();

      // 检查是否已解锁
      final isUnlocked = accessControlService.isAlbumUnlocked(albumId);

      if (!isUnlocked) {
        // 未解锁，显示密码验证对话框
        // 在显示对话框前再次检查 mounted
        if (!mounted) return;
        final verified = await PasswordVerifyDialog.show(
          context,
          albumId: albumId,
          encryptedSpaceService: encryptedSpaceService,
          accessControlService: accessControlService,
        );

        if (verified != true) {
          // 用户取消或验证失败
          if (mounted) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('已取消添加到加密空间'),
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        // 验证成功后解锁相册
        // 由于密码验证对话框已经验证了密码并保存了会话令牌，
        // 这里不需要再次进行生物识别验证
        try {
          await accessControlService.unlockAlbum(albumId, useBiometric: false);
        } catch (e) {
          // 解锁失败，记录错误但继续执行
          // 如果解锁失败，会在添加资产时再次检查
        }
      }

      // 添加资产到加密空间
      await encryptedSpaceService.addAssetsToEncryptedSpace(
        albumId: albumId,
        assetIds: selectedIds.toList(),
      );

      // 显示成功提示
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('已成功添加 ${selectedIds.length} 张照片到加密空间'),
            duration: const Duration(seconds: 2),
          ),
        );

        // 刷新时间线数据，让照片页面不再显示这些资产
        ref.invalidate(timelineAssetsProvider());
        ref.invalidate(timelineSectionsProvider);

        // 退出选择模式
        ref.read(assetSelectionProvider.notifier).deactivate();
      }
    } catch (e) {
      // 显示错误提示
      if (mounted) {
        String errorMessage = '添加到加密空间失败';
        if (e.toString().contains('Session token not found')) {
          errorMessage = '请先解锁加密空间';
        } else if (e.toString().contains('密码')) {
          errorMessage = '密码验证失败，请重试';
        } else {
          errorMessage = '添加到加密空间失败: ${e.toString()}';
        }

        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

  /// 检查是否全选
  bool _isAllSelected(
    WidgetRef ref,
    AsyncValue<List<TimelineSection>> timelineSectionsAsync,
  ) {
    final selectedIds = ref.read(assetSelectionProvider.select((s) => s.selectedIds));

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
    final selectedIds = ref.read(assetSelectionProvider.select((s) => s.selectedIds));
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

  /// 处理拖动开始
  void _handleDragStart(AssetIndex index) {
    final timelineSectionsAsync = ref.read(timelineSectionsProvider);
    timelineSectionsAsync.whenData((sections) {
      if (index.sectionIndex >= 0 && index.sectionIndex < sections.length) {
        final section = sections[index.sectionIndex];
        if (index.assetIndex >= 0 && index.assetIndex < section.assets.length) {
          final asset = section.assets[index.assetIndex];

          setState(() {
            _isDragging = true;
            _dragAnchorIndex = index;
            _draggedAssetIds.clear();
          });

          // 选中起始项
          final selectedIds = ref.read(assetSelectionProvider.select((s) => s.selectedIds));
          if (!selectedIds.contains(asset.id)) {
            ref.read(assetSelectionProvider.notifier).toggle(asset.id);
          }
          _draggedAssetIds.add(asset.id);
        }
      }
    });
  }

  /// 处理拖动进入资产
  void _handleDragAssetEnter(AssetIndex index) {
    if (_dragAnchorIndex == null || !_isDragging) return;

    final timelineSectionsAsync = ref.read(timelineSectionsProvider);
    timelineSectionsAsync.whenData((sections) {
      if (index.sectionIndex >= 0 && index.sectionIndex < sections.length) {
        final section = sections[index.sectionIndex];
        if (index.assetIndex >= 0 && index.assetIndex < section.assets.length) {
          // 计算选择范围（从起始索引到当前索引）
          final startIndex = _dragAnchorIndex!;
          final endIndex = index;

          // 如果起始和结束在同一分组
          if (startIndex.sectionIndex == endIndex.sectionIndex) {
            final startSection = sections[startIndex.sectionIndex];
            final startAssetIndex = startIndex.assetIndex;
            final endAssetIndex = endIndex.assetIndex;

            // 使用当前的网格列数
            final crossAxisCount = ref.read(timelineGridColumnsProvider);
            final startRow = startAssetIndex ~/ crossAxisCount;
            final endRow = endAssetIndex ~/ crossAxisCount;
            final startCol = startAssetIndex % crossAxisCount;
            final endCol = endAssetIndex % crossAxisCount;

            // 计算行数和列数的变化
            final rowDiff = (endRow - startRow).abs();
            final colDiff = (endCol - startCol).abs();

            final selectedAssets = <String>{};

            // 判断拖动方向：如果主要是向下拖动（行数变化大于列数变化），则选中整行
            if (rowDiff > colDiff) {
              // 向下拖动：选中整行，但起始行从起始列开始，结束行到结束列为止
              final minRow = startRow < endRow ? startRow : endRow;
              final maxRow = startRow > endRow ? startRow : endRow;
              final isDownward = startRow < endRow;

              for (int row = minRow; row <= maxRow; row++) {
                int startColForRow;
                int endColForRow;

                if (row == minRow && row == maxRow) {
                  // 只有一行：从起始列到结束列
                  startColForRow = (startCol < endCol ? startCol : endCol)
                      .toInt();
                  endColForRow = (startCol > endCol ? startCol : endCol)
                      .toInt();
                } else if (row == minRow) {
                  // 起始行：从起始列到行尾
                  if (isDownward) {
                    startColForRow = startCol;
                    endColForRow = crossAxisCount - 1;
                  } else {
                    startColForRow = endCol;
                    endColForRow = crossAxisCount - 1;
                  }
                } else if (row == maxRow) {
                  // 结束行：从行首到结束列
                  if (isDownward) {
                    startColForRow = 0;
                    endColForRow = endCol;
                  } else {
                    startColForRow = 0;
                    endColForRow = startCol;
                  }
                } else {
                  // 中间行：选中整行
                  startColForRow = 0;
                  endColForRow = crossAxisCount - 1;
                }

                for (int col = startColForRow; col <= endColForRow; col++) {
                  final assetIndex = row * crossAxisCount + col;
                  if (assetIndex >= 0 &&
                      assetIndex < startSection.assets.length) {
                    selectedAssets.add(
                      startSection.assets[assetIndex.toInt()].id,
                    );
                  }
                }
              }
            } else {
              // 横向拖动：保持矩形选择
              final minRow = startRow < endRow ? startRow : endRow;
              final maxRow = startRow > endRow ? startRow : endRow;
              final minCol = startCol < endCol ? startCol : endCol;
              final maxCol = startCol > endCol ? startCol : endCol;

              for (int row = minRow; row <= maxRow; row++) {
                for (int col = minCol; col <= maxCol; col++) {
                  final assetIndex = row * crossAxisCount + col;
                  if (assetIndex >= 0 &&
                      assetIndex < startSection.assets.length) {
                    selectedAssets.add(
                      startSection.assets[assetIndex.toInt()].id,
                    );
                  }
                }
              }
            }

            // 清除之前的拖动选择
            final selectedIds = ref.read(assetSelectionProvider.select((s) => s.selectedIds));
            for (final assetId in _draggedAssetIds) {
              if (!selectedAssets.contains(assetId) &&
                  selectedIds.contains(assetId)) {
                ref.read(assetSelectionProvider.notifier).toggle(assetId);
              }
            }

            // 添加新的拖动选择
            for (final assetId in selectedAssets) {
              if (!_draggedAssetIds.contains(assetId) &&
                  !selectedIds.contains(assetId)) {
                ref.read(assetSelectionProvider.notifier).toggle(assetId);
              }
            }

            setState(() {
              _draggedAssetIds.clear();
              _draggedAssetIds.addAll(selectedAssets);
            });
          }
        }
      }
    });
  }

  /// 处理拖动结束
  void _handleDragEnd() {
    setState(() {
      _isDragging = false;
      _dragAnchorIndex = null;
      _draggedAssetIds.clear();
    });
  }

  /// 处理拖动滚动开始
  void _handleDragScrollStart() {
    // 可以在这里添加滚动开始的处理逻辑
  }

  /// 处理拖动滚动
  void _handleDragScroll(ScrollDirection direction) {
    if (_scrollController.hasClients) {
      final offset = direction == ScrollDirection.forward ? 175.0 : -175.0;
      _scrollController.animateTo(
        _scrollController.offset + offset,
        duration: const Duration(milliseconds: 125),
        curve: Curves.easeOut,
      );
    }
  }

  /// 根据缩放值计算目标列数
  ///
  /// 使用平滑的映射函数，让手势更丝滑
  /// [scale]: 当前的缩放值（1.0 为基准）
  /// [baseColumns]: 手势开始时的列数
  int _calculateTargetColumns(double scale, int baseColumns) {
    // 缩放阈值：每个列数变化对应约 0.2 的缩放变化
    // 这样可以让手势更敏感，同时保持平滑
    const scaleThreshold = 0.2;

    // 计算相对于基准的缩放变化
    final scaleChange = scale - 1.0;

    // 计算应该变化的列数（使用四舍五入）
    final columnDelta = (scaleChange / scaleThreshold).round();

    // 计算目标列数
    var targetColumns = baseColumns - columnDelta; // 放大时减少列数

    // 限制在有效范围内
    targetColumns = targetColumns.clamp(2, 8);

    return targetColumns;
  }

  /// 构建筛选按钮的装饰样式
  /// 性能优化：提取为方法，避免在 build 中重复创建 BoxDecoration
  BoxDecoration _buildFilterButtonDecoration(
    BuildContext context,
    Color? backgroundColor,
  ) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: _filterButtonBorderRadius,
      border: backgroundColor == null
          ? Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: _filterButtonBorderWidth,
            )
          : null,
    );
  }

  /// 构建筛选模式按钮
  ///
  /// 显示当前筛选模式，点击可循环切换：全部 -> 已备份 -> 未备份 -> 全部
  /// 使用简洁的文字按钮样式，四种模式下按钮大小保持一致
  Widget _buildFilterButton(BuildContext context, WidgetRef ref) {
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
        width: 64,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: _buildFilterButtonDecoration(context, backgroundColor),
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
