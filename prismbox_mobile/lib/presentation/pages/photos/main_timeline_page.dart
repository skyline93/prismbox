import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/models/timeline_section.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/local_sync/providers/timeline_provider.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/presentation/widgets/timeline/timeline_sliver_list.dart';
import 'package:prismbox/providers/navigation/timeline_scroll_to_top_provider.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';

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
    );

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: false,
            title: const Text('照片'),
            actions: [
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
          // 展开内容 Sliver 列表
          ...contentSlivers,
        ],
      ),
    );
  }

  /// 构建内容 Sliver 列表
  List<Widget> _buildContentSlivers(
    BuildContext context,
    AsyncValue<PhotoPermissionState> permissionAsync,
    AsyncValue<List<TimelineSection>> timelineSectionsAsync,
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
            return assetEntityLoaderAsync.when(
              data: (assetEntityLoader) {
                return TimelineSliverListBuilder(
                  sections: sections,
                  crossAxisCount: 5,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1.0,
                  assetEntityLoader: assetEntityLoader,
                  onTap: (asset, index) {
                    // 导航到媒体查看器
                    final assetIds = allAssets.map((a) => a.id).toList();
                    context.router.push(
                      MediaViewerRoute(
                        initialAssetId: asset.id,
                        assetIds: assetIds,
                      ),
                    );
                  },
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
}
