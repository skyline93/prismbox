import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/pages/albums/albums_page.dart';
import 'package:prismbox/presentation/pages/library/library_page.dart';
import 'package:prismbox/presentation/pages/login/login_page.dart';
import 'package:prismbox/presentation/pages/register/register_page.dart';
import 'package:prismbox/presentation/pages/permission/permission_page.dart';
import 'package:prismbox/presentation/pages/photos/main_timeline_page.dart';
import 'package:prismbox/presentation/pages/search/search_page.dart';
import 'package:prismbox/presentation/pages/splash/splash_page.dart';
import 'package:prismbox/presentation/pages/tab_shell/tab_shell_page.dart';
import 'package:prismbox/presentation/pages/viewer/media_viewer_page.dart';
import 'package:prismbox/presentation/routing/guards/auth_guard.dart';
import 'package:prismbox/presentation/routing/guards/duplicate_guard.dart';
import 'package:prismbox/presentation/routing/guards/permission_guard.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';

part 'app_router.gr.dart';

/// AppRouter Provider
/// 使用 Provider 创建 AppRouter 实例，确保 Ref 类型正确
final appRouterProvider = Provider<AppRouter>((ref) {
  return AppRouter(ref);
});

/// 应用路由配置
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends _$AppRouter {
  final Ref ref;
  late final AuthGuard _authGuard;
  late final DuplicateGuard _duplicateGuard;
  late final PermissionGuard _permissionGuard;

  AppRouter(this.ref) {
    _authGuard = AuthGuard(ref);
    _duplicateGuard = const DuplicateGuard();
    _permissionGuard = PermissionGuard(ref);
  }

  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
        // 初始页面（无守卫）
        AutoRoute(
          page: SplashRoute.page,
          path: '/splash',
          initial: true,
        ),

        // 登录页面（无守卫）
        AutoRoute(
          page: LoginRoute.page,
          path: '/login',
        ),

        // 注册页面（无守卫）
        AutoRoute(
          page: RegisterRoute.page,
          path: '/register',
        ),

        // 权限引导页面（需要认证但不强制）
        AutoRoute(
          page: PermissionRoute.page,
          path: '/permission',
          guards: [_authGuard],
        ),

        // TabShell 容器（需要认证）
        CustomRoute(
          page: TabShellRoute.page,
          path: '/home',
          guards: [_authGuard, _duplicateGuard],
          children: [
            AutoRoute(
              page: MainTimelineRoute.page,
              path: 'photos', // 子路由路径不能以 "/" 开头
              guards: [_authGuard],
            ),
            AutoRoute(
              page: SearchRoute.page,
              path: 'search', // 子路由路径不能以 "/" 开头
              guards: [_authGuard],
              maintainState: false, // 不保持状态
            ),
            AutoRoute(
              page: AlbumsRoute.page,
              path: 'albums', // 子路由路径不能以 "/" 开头
              guards: [_authGuard],
            ),
            AutoRoute(
              page: LibraryRoute.page,
              path: 'library', // 子路由路径不能以 "/" 开头
              guards: [_authGuard],
            ),
          ],
          transitionsBuilder: TransitionsBuilders.fadeIn,
        ),

        // 媒体查看器（需要认证和权限）
        AutoRoute(
          page: MediaViewerRoute.page,
          path: '/media/:assetId',
          guards: [_authGuard, _permissionGuard],
        ),
      ];
}

