import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:mobile/ui/main/page/splash_page.dart';
import 'package:mobile/ui/main/page/main_navigation_page.dart';
import 'package:mobile/ui/media/page/media_page.dart';
import 'package:mobile/ui/album/page/album_page.dart';
import 'package:mobile/ui/library/page/library_page.dart';
import 'package:mobile/ui/library/page/server_config_page.dart';
import 'package:mobile/ui/pages/home_page.dart';
import 'package:mobile/ui/pages/login_page.dart';
import 'package:mobile/routing/auth_guard.dart';
import 'package:mobile/ui/pages/splash_page.dart';

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
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
      guards: [AuthGuard(ref)], // 传入 ref 来创建 Guard
    ),
    // AutoRoute(page: NavigationRoute.page, path: "/navigation", initial: true),
    // AutoRoute(page: MediaRoute.page, path: "/media"),
    // AutoRoute(page: AlbumRoute.page, path: "/album"),
    // AutoRoute(page: LibraryRoute.page, path: "/library"),
    // AutoRoute(page: ServerConfigRoute.page, path: "/server_config"),
  ];
}
