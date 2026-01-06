import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 权限守卫
/// 检查特定页面所需的权限
class PermissionGuard extends AutoRouteGuard {
  final Ref ref;

  PermissionGuard(this.ref);

  @override
  void onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // 默认允许导航
    // 如果需要检查特定权限，可以在这里实现
    // 例如：检查图库访问权限等
    
    resolver.next(true);
  }
}

