// lib/routing/app_router.dart

import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/ui/main/page/main_navigation_page.dart';
import 'package:mobile/ui/media/pages/media_page.dart';
import 'package:mobile/ui/album/page/album_page.dart';
import 'package:mobile/ui/main/page/login_page.dart';
import 'package:mobile/ui/main/page/register_page.dart';
import 'package:mobile/ui/main/page/splash_page.dart';
import 'package:mobile/ui/gallery/pages/gallery_page.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/data/datasources/local_db/enums.dart';
import 'package:mobile/ui/album/page/album_detail_page.dart';

import 'package:mobile/ui/group/pages/group_list_page.dart';
import 'package:mobile/ui/group/pages/create_group_page.dart';
import 'package:mobile/ui/group/pages/group_feed_page.dart';
import 'package:mobile/ui/group/pages/group_members_page.dart';
import 'package:mobile/ui/group/pages/group_settings_page.dart';
import 'package:mobile/ui/group/pages/group_post_detail_page.dart';

import 'package:mobile/domain/entities/group_feed_item_entity.dart';

part 'app_router.gr.dart';

final appRouterProvider = Provider<AppRouter>((ref) {
  return AppRouter(ref);
});

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends _$AppRouter {
  final Ref ref;

  AppRouter(this.ref);

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: "/splash", initial: true),
    AutoRoute(page: LoginRoute.page, path: "/login"),
    AutoRoute(page: RegisterRoute.page, path: "/register"),
    AutoRoute(page: NavigationRoute.page, path: "/navigation"),
    AutoRoute(page: MediaRoute.page, path: "/media"),
    AutoRoute(page: GalleryRoute.page, path: '/gallery'),
    AutoRoute(page: AlbumRoute.page, path: "/albums"),
    AutoRoute(page: AlbumDetailRoute.page, path: "/album-detail"),

    AutoRoute(page: GroupListRoute.page, path: "/groups"),
    AutoRoute(page: CreateGroupRoute.page, path: "/groups/create"),
    AutoRoute(page: GroupFeedRoute.page, path: "/groups/:uuid"),
    AutoRoute(page: GroupMembersRoute.page, path: "/groups/:uuid/members"),
    AutoRoute(page: GroupSettingsRoute.page, path: "/groups/:uuid/settings"),
    AutoRoute(page: GroupPostDetailRoute.page, path: '/group/:uuid/post'),
  ];
}
