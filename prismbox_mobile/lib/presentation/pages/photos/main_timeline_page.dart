import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/timeline/selectable_timeline_sliver_list.dart';
import 'package:prismbox/presentation/widgets/backup/backup_asset_selection_dialog.dart';
import 'package:prismbox/presentation/widgets/backup/backup_action_sheet.dart';
import 'package:prismbox/presentation/widgets/selection/selection_bottom_sheet.dart';
import 'package:prismbox/providers/navigation/timeline_scroll_to_top_provider.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';

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

  @override
  void initState() {
    super.initState();
    // 监听数据源切换
    _listenDataSourceSwitch();
  }

  @override
  void dispose() {
    _dataSourceSwitchSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听数据源切换通知
  /// 当同步完成后，如果数据库数据可用，会自动切换到数据库数据源
  void _listenDataSourceSwitch() {
    ref.read(syncCoordinatorProvider.future).then((coordinator) {
      debugPrint('✅ 数据源切换监听已启动');
      _dataSourceSwitchSubscription = coordinator.dataSourceSwitchStream.listen(
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
    }).catchError((error) {
      debugPrint('❌ 启动数据源切换监听失败: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    // 在 build 方法中使用 ref.listen
    ref.listen<bool>(timelineScrollToTopProvider, (previous, next) {
      if (next && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // 监听选择状态
    final selectionState = ref.watch(assetSelectionProvider);

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
      selectionState.isActive,
      selectionState.selectedIds,
    );

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // AppBar（多选模式下显示选择栏，否则显示正常 AppBar）
              if (selectionState.isActive)
                SliverAppBar(
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
                      mainAxisSize: MainAxisSize.min,
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
                        // 使用 Flexible 确保文本可以适应剩余空间
                        Flexible(
                          child: Text(
                            '${selectionState.count}张',
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
                      child: TextButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (_isAllSelected(ref, timelineSectionsAsync)) {
                            _handleDeselectAll(ref);
                          } else {
                            _handleSelectAll(ref);
                          }
                        },
                        icon: Icon(
                          _isAllSelected(ref, timelineSectionsAsync)
                              ? Icons.check_circle_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 24,
                          color: _isAllSelected(ref, timelineSectionsAsync)
                              ? const Color(0xFF4285F4) // 谷歌蓝
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        label: Text(
                          _isAllSelected(ref, timelineSectionsAsync) ? '全选' : '全选',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      ),
                    ),
                  ],
                  elevation: 0,
                )
              else
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  title: const Text('照片'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.cloud_upload),
                      tooltip: '备份照片',
                      onPressed: () => _showBackupDialog(context, ref),
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list),
                      onPressed: () {
                        // TODO: 显示筛选对话框
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // 刷新时间线数据
                        ref.invalidate(timelineSectionsProvider);
                      },
                    ),
                  ],
                ),

              // 时间线内容
              ...contentSlivers,
            ],
          ),

          // 选择底部抽屉（多选模式下显示）
          if (selectionState.isActive)
            SelectionBottomSheet(
              selectedCount: selectionState.count,
              onUpload: () => _handleUpload(context, ref),
              isAllSelected: _isAllSelected(ref, timelineSectionsAsync),
            ),
        ],
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
            final allAssets = <LocalAsset>[];
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
                  crossAxisCount: 5,
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
                          ref.read(assetSelectionProvider.notifier).toggle(asset.id);
                        }
                      : null,
                  onLongPress: (asset) {
                    // 长按进入多选模式（如果还未激活）
                    if (!selectionActive) {
                      HapticFeedback.mediumImpact();
                      ref.read(assetSelectionProvider.notifier).activate();
                      ref.read(assetSelectionProvider.notifier).toggle(asset.id);
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
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
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
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

  /// 显示备份对话框
  Future<void> _showBackupDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // 获取所有资产
    final timelineSectionsAsync = ref.read(timelineSectionsProvider);
    final sections = await timelineSectionsAsync.when(
      data: (sections) => sections,
      loading: () => <TimelineSection>[],
      error: (_, __) => <TimelineSection>[],
    );

    if (sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无照片可备份')),
      );
      return;
    }

    // 收集所有资产
    final allAssets = <LocalAsset>[];
    for (final section in sections) {
      allAssets.addAll(section.assets);
    }

    // 显示资产选择对话框
    final selectedIds = await BackupAssetSelectionDialog.show(
      context,
      assets: allAssets,
    );

    if (selectedIds != null && selectedIds.isNotEmpty) {
      // 显示备份操作底部表单
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => BackupActionSheet(
          assetIds: selectedIds,
          onDismiss: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  /// 处理上传
  Future<void> _handleUpload(BuildContext context, WidgetRef ref) async {
    final selectionState = ref.read(assetSelectionProvider);
    if (selectionState.selectedIds.isEmpty) return;

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
        assetIds: selectionState.selectedIds.toList(),
        skipDeduplication: false,
      );

      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已开始上传 ${selectionState.selectedIds.length} 张照片'),
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
    final selectionState = ref.read(assetSelectionProvider);
    
    return timelineSectionsAsync.when(
      data: (sections) {
        final allAssetIds = <String>[];
        for (final section in sections) {
          allAssetIds.addAll(section.assets.map((a) => a.id));
        }
        return selectionState.selectedIds.length == allAssetIds.length &&
            allAssetIds.every((id) => selectionState.selectedIds.contains(id));
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// 处理分组切换（选择/取消选择整个分组）
  void _handleSectionToggle(WidgetRef ref, TimelineSection section) {
    final selectionState = ref.read(assetSelectionProvider);
    final sectionAssetIds = section.assets.map((a) => a.id).toSet();
    
    // 检查该分组是否全部选中
    final isAllSelected = sectionAssetIds.isNotEmpty &&
        sectionAssetIds.every((id) => selectionState.selectedIds.contains(id));
    
    if (isAllSelected) {
      // 取消选择该分组的所有照片
      for (final assetId in sectionAssetIds) {
        if (selectionState.selectedIds.contains(assetId)) {
          ref.read(assetSelectionProvider.notifier).toggle(assetId);
        }
      }
    } else {
      // 选择该分组的所有照片
      for (final assetId in sectionAssetIds) {
        if (!selectionState.selectedIds.contains(assetId)) {
          ref.read(assetSelectionProvider.notifier).toggle(assetId);
        }
      }
    }
  }
}
