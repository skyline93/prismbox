// lib/presentation/routing/guards/auth_guard.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';

/// 认证守卫
/// 检查用户是否已登录，验证访问令牌有效性
class AuthGuard extends AutoRouteGuard {
  final Ref _ref;
  final _log = Logger('AuthGuard');

  AuthGuard(this._ref);

  @override
  void onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // 先允许导航，后续验证失败则重定向
    resolver.next(true);

    try {
      // 异步获取 AuthService
      final authServiceFuture = _ref.read(authServiceProvider.future);
      final authService = await authServiceFuture;
      
      // 使用 AuthService 检查认证状态
      final isAuthenticated = await authService.isAuthenticated();

      if (!isAuthenticated) {
        _log.warning('User not authenticated. Redirecting to login.');
        router.replaceAll([const LoginRoute()]);
        return;
      }

      _log.fine('User authenticated. Allowing navigation.');
    } catch (e) {
      _log.severe('Error validating authentication: $e');
      // 验证失败时重定向到登录页
      router.replaceAll([const LoginRoute()]);
    }
  }
}
