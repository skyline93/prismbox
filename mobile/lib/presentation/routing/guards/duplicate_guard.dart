import 'package:auto_route/auto_route.dart';

/// 重复导航守卫
/// 防止重复导航到同一页面，避免导航栈混乱
class DuplicateGuard extends AutoRouteGuard {
  const DuplicateGuard();

  @override
  void onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) {
    final targetRoute = resolver.route;
    final currentRoute = router.current;

    // 如果目标路由与当前路由相同，阻止导航
    if (currentRoute != null && // ignore: unnecessary_null_comparison
        targetRoute.name == currentRoute.name &&
        targetRoute.path == currentRoute.path) {
      resolver.next(false);
      return;
    }

    resolver.next(true);
  }
}

