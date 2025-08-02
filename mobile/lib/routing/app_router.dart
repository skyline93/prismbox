import 'package:auto_route/auto_route.dart';
import 'package:mobile/ui/main/page/splash_page.dart';
import 'package:mobile/ui/main/page/main_navigation_page.dart';
import 'package:mobile/ui/media/page/media_page.dart';
import 'package:mobile/ui/album/page/album_page.dart';
import 'package:mobile/ui/library/page/library_page.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: "/splash"),
    AutoRoute(page: NavigationRoute.page, path: "/navigation", initial: true),
    AutoRoute(page: MediaRoute.page, path: "/media"),
    AutoRoute(page: AlbumRoute.page, path: "/album"),
    AutoRoute(page: LibraryRoute.page, path: "/library"),
  ];
}
