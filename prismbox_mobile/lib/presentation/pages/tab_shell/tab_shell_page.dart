import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/features/local_sync/providers/local_sync_providers.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/app/read_only_mode_provider.dart';
import 'package:prismbox/providers/navigation/search_input_focus_provider.dart';
import 'package:prismbox/providers/navigation/timeline_scroll_to_top_provider.dart';
import 'package:prismbox/providers/permission/photo_permission_provider.dart';
import 'package:prismbox/providers/selection/asset_selection_provider.dart';

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
  bool _hasRequestedPermission = false;
  bool _hasStartedSync = false;
  final _log = Logger('TabShellPage');

  @override
  void initState() {
    super.initState();
    // 添加生命周期监听器
    WidgetsBinding.instance.addObserver(this);
    
    // 页面渲染完成后请求权限并启动自动同步
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPhotoPermission();
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
      final coordinator = await ref.read(syncCoordinatorProvider.future);
      coordinator.checkAndSyncOnResume();
    } catch (e, stackTrace) {
      _log.warning('应用恢复时同步检查失败', e, stackTrace);
    }
  }

  /// 请求相册权限
  Future<void> _requestPhotoPermission() async {
    if (_hasRequestedPermission) return;
    _hasRequestedPermission = true;

    // 延迟一下，确保页面完全加载
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // 请求权限
    final permissionNotifier = ref.read(
      photoPermissionNotifierProvider.notifier,
    );
    await permissionNotifier.requestPermission();
  }

  /// 启动自动同步
  /// 根据设计文档，应用启动后延迟 2 秒启动后台同步任务
  Future<void> _startAutoSync() async {
    if (_hasStartedSync) return;
    _hasStartedSync = true;

    // 延迟一下，确保权限已请求和页面完全加载
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      _log.info('启动本地媒体同步服务');
      final coordinator = await ref.read(syncCoordinatorProvider.future);
      coordinator.startAutoSyncOnLaunch();
      _log.info('本地媒体同步服务已启动');
    } catch (e, stackTrace) {
      // 记录错误但不阻塞 UI
      _log.warning('启动自动同步失败', e, stackTrace);
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
        const SearchRoute(),
        const AlbumsRoute(),
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
            Icons.album_outlined,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.album,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: '相册',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.library_books_outlined,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.library_books,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: '资料库',
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
            Icons.album_outlined,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.album,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: const Text('相册'),
        ),
        NavigationRailDestination(
          icon: Icon(
            Icons.library_books_outlined,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.library_books,
            color: isReadOnlyMode ? Colors.grey : null,
          ),
          label: const Text('资料库'),
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
        case 1: // Search
          // 聚焦搜索输入框
          ref.read(searchInputFocusProvider.notifier).focus();
          break;
      }
    } else {
      // 切换到新标签
      router.setActiveIndex(index);

      // 按需刷新数据
      // 注意：以下 Provider 需要在对应模块实现后取消注释
      switch (index) {
        case 2: // Albums
          // TODO: 实现相册模块后，取消注释以下代码
          // ref.refresh(albumsProvider);
          break;
        case 3: // Library
          // TODO: 实现资料库模块后，取消注释以下代码
          // ref.refresh(libraryProvider);
          break;
      }
    }
  }
}
