import 'dart:async';
import 'dart:convert';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/features/remote_sync/providers/remote_sync_providers.dart';
import 'package:prismbox/services/backup/providers/backup_providers.dart';
import 'package:prismbox/utils/network_checker.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/app/read_only_mode_provider.dart';
import 'package:prismbox/providers/navigation/search_input_focus_provider.dart';
import 'package:prismbox/providers/navigation/timeline_scroll_to_top_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';
import 'package:prismbox/providers/permission/notification_permission_provider.dart';

/// TabShell 容器页面
/// 管理四个核心标签页的导航
@RoutePage()
class TabShellPage extends ConsumerStatefulWidget {
  const TabShellPage({super.key});

  @override
  ConsumerState<TabShellPage> createState() => _TabShellPageState();
}

class _TabShellPageState extends ConsumerState<TabShellPage>
    with WidgetsBindingObserver {
  bool _hasStartedSync = false;
  final _log = Logger('TabShellPage');

  @override
  void initState() {
    super.initState();
    // 添加生命周期监听器
    WidgetsBinding.instance.addObserver(this);

    // 页面渲染完成后启动自动同步
    // 注意：移除了权限请求，因为 MainTimelinePage 已经在检查权限了
    // 这样可以避免重复请求权限，减少不必要的加载状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoSync();
    });
  }

  @override
  void dispose() {
    // 移除生命周期监听器
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 应用恢复时检查并同步
      _log.info('✅ 应用恢复，检查数据新鲜度');
      _checkAndSyncOnResume();
    } else if (state == AppLifecycleState.paused) {
      _log.info('应用进入后台');
    }
  }

  /// 应用恢复时检查并同步
  Future<void> _checkAndSyncOnResume() async {
    if (!mounted) return;

    try {
      _log.info('✅ 触发应用恢复时的同步检查');

      // 本地同步
      final coordinator = await ref.read(syncCoordinatorProvider.future);
      coordinator.checkAndSyncOnResume();

      // 远程同步
      final userId = await _getCurrentUserId();
      if (userId != null) {
        final remoteCoordinator = await ref.read(
          remoteSyncCoordinatorProvider.future,
        );
        remoteCoordinator.checkAndSyncOnResume(userId: userId);

        // 检查并触发自动备份
        await _checkAndTriggerAutoBackup(userId);
      }
    } catch (e, stackTrace) {
      _log.warning('应用恢复时同步检查失败', e, stackTrace);
    }
  }

  /// 检查并触发自动备份
  Future<void> _checkAndTriggerAutoBackup(String userId) async {
    try {
      final storeService = StoreService();

      // 检查全局自动备份开关
      final globalAutoBackup = storeService.get<bool>(
        StoreKey.autoBackup,
        false,
      );

      if (!globalAutoBackup) {
        _log.info('全局自动备份已禁用，跳过检查');
        return;
      }

      // 检查用户自动备份配置
      final backupService = await ref.read(backupServiceProvider.future);
      final backupStatus = await backupService.getBackupStatus(userId);

      if (backupStatus == null || !backupStatus.enabled) {
        _log.info('用户自动备份已禁用，跳过检查');
        return;
      }

      // 检查触发频率（避免频繁触发）
      final lastTriggerTime = storeService.get<DateTime?>(
        StoreKey.lastAutoBackupTriggerTime,
        null,
      );

      if (lastTriggerTime != null) {
        final timeSinceLastTrigger = DateTime.now().difference(lastTriggerTime);
        if (timeSinceLastTrigger.inMinutes < 5) {
          _log.info('距离上次触发仅 ${timeSinceLastTrigger.inMinutes} 分钟，跳过触发');
          return;
        }
      }

      // 检查网络条件
      final requireWifi = storeService.get<bool>(
        StoreKey.backupRequireWifi,
        true,
      );

      if (requireWifi) {
        // 检查当前网络类型
        final isWifi = await NetworkChecker.isWifiConnected();
        if (!isWifi) {
          _log.info('要求 WiFi 但当前不是 WiFi 网络，跳过触发');
          return;
        }
      }

      // 检查是否有网络连接
      final hasNetwork = await NetworkChecker.hasNetworkConnection();
      if (!hasNetwork) {
        _log.info('无网络连接，跳过触发');
        return;
      }

      // 触发自动备份
      _log.info('应用恢复时触发自动备份');
      await backupService.startAutoBackup(userId);

      // 更新最后触发时间（已在 startAutoBackup 中更新，这里不需要重复更新）
    } catch (e, stackTrace) {
      _log.warning('应用恢复时自动备份检查失败', e, stackTrace);
    }
  }

  /// 启动自动同步
  /// 根据设计文档，应用启动后延迟启动后台同步任务
  Future<void> _startAutoSync() async {
    if (_hasStartedSync) return;
    _hasStartedSync = true;

    // 延迟一下，确保页面完全加载
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      // 请求通知权限（用于后台备份进度通知）
      _log.info('检查并请求通知权限');
      try {
        final notificationNotifier = ref.read(
          notificationPermissionNotifierProvider.notifier,
        );
        await notificationNotifier.hasOrRequestPermission();
        _log.info('通知权限检查完成');
      } catch (e) {
        _log.warning('请求通知权限失败: $e');
        // 不阻塞主流程，继续执行
      }

      // 启动本地媒体同步服务
      _log.info('启动本地媒体同步服务');
      final coordinator = await ref.read(syncCoordinatorProvider.future);
      coordinator.startAutoSyncOnLaunch();
      _log.info('本地媒体同步服务已启动');

      // 启动远程媒体同步服务
      final userId = await _getCurrentUserId();
      if (userId != null) {
        _log.info('启动远程媒体同步服务: userId=$userId');
        final remoteCoordinator = await ref.read(
          remoteSyncCoordinatorProvider.future,
        );
        remoteCoordinator.startAutoSyncOnLaunch(userId: userId);
        _log.info('远程媒体同步服务已启动');
      } else {
        _log.info('未获取到用户ID，跳过远程同步');
      }
    } catch (e, stackTrace) {
      // 记录错误但不阻塞 UI
      _log.warning('启动自动同步失败', e, stackTrace);
    }
  }

  /// 获取当前用户ID
  /// 从 Store 中读取 currentUser（JSON 字符串），解析并返回 id
  Future<String?> _getCurrentUserId() async {
    try {
      final store = StoreService();
      if (!store.isInitialized) {
        _log.warning(
          'StoreService not initialized, cannot get current user ID',
        );
        return null;
      }

      final userJson = store.tryGet<String>(StoreKey.currentUser);
      if (userJson == null || userJson.isEmpty) {
        _log.fine('No current user found in Store');
        return null;
      }

      // 解析 JSON
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final userId = userMap['id'];
      if (userId != null) {
        return userId.toString();
      }

      _log.warning('User JSON does not contain id field');
      return null;
    } catch (e, stackTrace) {
      _log.warning('获取用户ID失败', e, stackTrace);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScreenLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isReadOnlyMode = ref.watch(readOnlyModeProvider);
    // 监听选择模式状态，选择模式下隐藏底部导航栏
    final selectionState = ref.watch(assetSelectionProvider);
    final isSelectionMode = selectionState.isActive;

    return AutoTabsRouter(
      routes: [
        const MainTimelineRoute(),
        const AlbumsRoute(),
        const SearchRoute(),
        const LibraryRoute(),
      ],
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (context, child, animation) =>
          FadeTransition(opacity: animation, child: child),
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);
        return PopScope(
          canPop: tabsRouter.activeIndex == 0,
          onPopInvokedWithResult: (didPop, _) =>
              !didPop ? tabsRouter.setActiveIndex(0) : null,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: isScreenLandscape
                ? Row(
                    children: [
                      _buildNavigationRail(tabsRouter, isReadOnlyMode),
                      const VerticalDivider(width: 1),
                      Expanded(child: child),
                    ],
                  )
                : child,
            bottomNavigationBar: isScreenLandscape || isSelectionMode
                ? null
                : _buildBottomNavigationBar(tabsRouter, isReadOnlyMode),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(TabsRouter router, bool isReadOnlyMode) {
    return NavigationBar(
      selectedIndex: router.activeIndex,
      onDestinationSelected: (index) {
        if (isReadOnlyMode && index > 0) {
          // 只读模式下禁用除照片外的其他标签
          // 显示提示信息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('只读模式下此功能不可用'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _handleNavigation(router, index);
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.photo_library_outlined),
          selectedIcon: Icon(Icons.photo_library),
          label: '照片',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.collections_outlined,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.collections,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: '合集',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.search_outlined,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.search,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: '搜索',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.people_outline,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.people,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: '圈子',
        ),
      ],
    );
  }

  Widget _buildNavigationRail(TabsRouter router, bool isReadOnlyMode) {
    return NavigationRail(
      selectedIndex: router.activeIndex,
      onDestinationSelected: (index) {
        if (isReadOnlyMode && index > 0) {
          // 只读模式下禁用除照片外的其他标签
          // 显示提示信息
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('只读模式下此功能不可用'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _handleNavigation(router, index);
      },
      labelType: NavigationRailLabelType.all,
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.photo_library_outlined),
          selectedIcon: Icon(Icons.photo_library),
          label: Text('照片'),
        ),
        NavigationRailDestination(
          icon: Icon(
            Icons.collections_outlined,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.collections,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: const Text('合集'),
        ),
        NavigationRailDestination(
          icon: Icon(
            Icons.search_outlined,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.search,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: const Text('搜索'),
        ),
        NavigationRailDestination(
          icon: Icon(
            Icons.people_outline,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.people,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: const Text('圈子'),
        ),
      ],
    );
  }

  void _handleNavigation(TabsRouter router, int index) {
    // 标签切换逻辑
    if (router.activeIndex == index) {
      // 点击已激活的标签时的行为
      switch (index) {
        case 0: // Photos
          // 滚动到顶部
          ref.read(timelineScrollToTopProvider.notifier).scrollToTop();
          break;
        case 1: // Collections (合集)
          // 可以添加滚动到顶部逻辑
          break;
        case 2: // Search
          // 聚焦搜索输入框
          ref.read(searchInputFocusProvider.notifier).focus();
          break;
        case 3: // Circle (圈子)
          // 可以添加刷新逻辑
          break;
      }
    } else {
      // 切换到新标签
      router.setActiveIndex(index);

      // 按需刷新数据
      // 注意：以下 Provider 需要在对应模块实现后取消注释
      switch (index) {
        case 1: // Collections (合集)
          // TODO: 实现合集模块后，取消注释以下代码
          // ref.refresh(collectionsProvider);
          break;
        case 3: // Circle (圈子)
          // TODO: 实现圈子模块后，取消注释以下代码
          // ref.refresh(circleProvider);
          break;
      }
    }
  }
}
