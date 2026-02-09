import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/pages/albums/albums_page.dart';
import 'package:prismbox/presentation/pages/collections/favorite_timeline_page.dart';
import 'package:prismbox/presentation/pages/collections/recently_added_timeline_page.dart';
import 'package:prismbox/presentation/pages/collections/video_timeline_page.dart';
import 'package:prismbox/presentation/pages/collections/raw_timeline_page.dart';
import 'package:prismbox/presentation/pages/collections/live_timeline_page.dart';
import 'package:prismbox/presentation/pages/library/library_page.dart';
import 'package:prismbox/presentation/pages/login/login_page.dart';
import 'package:prismbox/presentation/pages/register/register_page.dart';
import 'package:prismbox/presentation/pages/permission/permission_page.dart';
import 'package:prismbox/presentation/pages/photos/main_timeline_page.dart';
import 'package:prismbox/presentation/pages/splash/splash_page.dart';
import 'package:prismbox/presentation/pages/tab_shell/tab_shell_page.dart';
import 'package:prismbox/presentation/pages/viewer/media_viewer_page.dart';
import 'package:prismbox/presentation/pages/backup/backup_settings_page.dart';
import 'package:prismbox/presentation/pages/backup/backup_management_page.dart';
import 'package:prismbox/presentation/pages/backup/upload_detail_page.dart';
import 'package:prismbox/presentation/pages/settings/settings_page.dart';
import 'package:prismbox/presentation/pages/settings/preferences_page.dart';
import 'package:prismbox/presentation/pages/settings/language_page.dart';
import 'package:prismbox/presentation/pages/trash/trash_page.dart';
import 'package:prismbox/presentation/pages/groups/create_group_page.dart';
import 'package:prismbox/presentation/pages/groups/group_feed_page.dart';
import 'package:prismbox/presentation/pages/groups/group_list_page.dart';
import 'package:prismbox/presentation/pages/groups/group_detail_page.dart';
import 'package:prismbox/presentation/pages/groups/group_members_page.dart';
import 'package:prismbox/presentation/pages/groups/group_settings_page.dart';
import 'package:prismbox/presentation/pages/posts/create_post_page.dart';
import 'package:prismbox/presentation/pages/posts/post_detail_page.dart';
import 'package:prismbox/presentation/routing/guards/auth_guard.dart';
import 'package:prismbox/presentation/routing/guards/duplicate_guard.dart';
import 'package:prismbox/presentation/routing/guards/permission_guard.dart';

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
    AutoRoute(page: SplashRoute.page, path: '/splash', initial: true),

    // 登录页面（无守卫）
    AutoRoute(page: LoginRoute.page, path: '/login'),

    // 注册页面（无守卫）
    AutoRoute(page: RegisterRoute.page, path: '/register'),

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
          page: AlbumsRoute.page,
          path: 'albums', // 子路由路径不能以 "/" 开头
          guards: [_authGuard],
        ),
        AutoRoute(
          page: GroupFeedRoute.page,
          path: 'groups', // Tab 默认进入 Feed 页
          guards: [_authGuard],
        ),
      ],
      transitionsBuilder: TransitionsBuilders.fadeIn,
    ),

    // 媒体查看器（需要认证和权限）。opaque: false 使路由透明，下滑时背景渐变可透出下层时间线。
    // 使用 fadeIn 退场，与 Immich 一致：松手后仅淡出，无整页滑动，避免卡顿。
    AutoRoute(
      page: MediaViewerRoute.page,
      path: '/media/:assetId',
      guards: [_authGuard, _permissionGuard],
      type: RouteType.custom(
        customRouteBuilder: <T>(context, child, page) => PageRouteBuilder<T>(
          fullscreenDialog: page.fullscreenDialog,
          settings: page,
          pageBuilder: (_, __, ___) => child,
          opaque: false,
          transitionsBuilder: TransitionsBuilders.fadeIn,
        ),
      ),
    ),

    // 备份设置页面（需要认证）
    AutoRoute(
      page: BackupSettingsRoute.page,
      path: '/backup/settings',
      guards: [_authGuard],
    ),

    // 备份管理页面（需要认证）
    AutoRoute(
      page: BackupManagementRoute.page,
      path: '/backup/management',
      guards: [_authGuard],
    ),

    // 上传详情页面（需要认证）
    AutoRoute(
      page: UploadDetailRoute.page,
      path: '/backup/upload-detail',
      guards: [_authGuard],
    ),

    // 设置页面（需要认证）
    AutoRoute(
      page: SettingsRoute.page,
      path: '/settings',
      guards: [_authGuard],
    ),

    // 偏好设置页面（需要认证）
    AutoRoute(
      page: PreferencesRoute.page,
      path: '/settings/preferences',
      guards: [_authGuard],
    ),

    // 语言设置页面（需要认证）
    AutoRoute(
      page: LanguageRoute.page,
      path: '/settings/language',
      guards: [_authGuard],
    ),

    // 回收站页面（需要认证）
    AutoRoute(page: TrashRoute.page, path: '/trash', guards: [_authGuard]),

    // 收藏时间线页面（需要认证）
    AutoRoute(
      page: FavoriteTimelineRoute.page,
      path: '/collections/favorite',
      guards: [_authGuard],
    ),

    // 视频时间线页面（需要认证）
    AutoRoute(
      page: VideoTimelineRoute.page,
      path: '/collections/video',
      guards: [_authGuard],
    ),

    // 最近添加时间线页面（需要认证）
    AutoRoute(
      page: RecentlyAddedTimelineRoute.page,
      path: '/collections/recently-added',
      guards: [_authGuard],
    ),

    // RAW 时间线页面（需要认证）
    AutoRoute(
      page: RawTimelineRoute.page,
      path: '/collections/raw',
      guards: [_authGuard],
    ),

    // Live Photo 时间线页面（需要认证）
    AutoRoute(
      page: LiveTimelineRoute.page,
      path: '/collections/live',
      guards: [_authGuard],
    ),

    // 圈子列表页面（需要认证）- 供 Feed 页「我的圈子」跳转
    AutoRoute(
      page: GroupListRoute.page,
      path: '/groups/list',
      guards: [_authGuard],
    ),

    // 创建圈子页面（需要认证）
    AutoRoute(
      page: CreateGroupRoute.page,
      path: '/groups/create',
      guards: [_authGuard],
    ),

    // 成员管理页面（需要认证）- 放在详情页之前，因为路径更具体
    AutoRoute(
      page: GroupMembersRoute.page,
      path: '/groups/:groupUuid/members',
      guards: [_authGuard],
    ),

    // 圈子设置页面（需要认证）- 放在详情页之前，因为路径更具体
    AutoRoute(
      page: GroupSettingsRoute.page,
      path: '/groups/:groupUuid/settings',
      guards: [_authGuard],
    ),

    // 圈子详情页面（需要认证）
    AutoRoute(
      page: GroupDetailRoute.page,
      path: '/groups/:groupUuid',
      guards: [_authGuard],
    ),

    // 创建帖子页面（需要认证）
    AutoRoute(
      page: CreatePostRoute.page,
      path: '/groups/:groupUuid/posts/create',
      guards: [_authGuard],
    ),

    // 帖子详情页面（需要认证）
    AutoRoute(
      page: PostDetailRoute.page,
      path: '/groups/:groupUuid/posts/:postId',
      guards: [_authGuard],
    ),
  ];
}
