// lib/presentation/routing/guards/auth_guard.dart

import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/core/storage/store_key.dart';

/// 认证守卫
/// 检查用户是否已登录，验证访问令牌有效性
/// 优化：先从 Store 快速检查 token，有 token 就允许通过，后台再验证
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
      // 快速检查：先从 Store 读取 token（同步操作，非常快）
      final store = StoreService();
      _log.info('AuthGuard: Store initialized: ${store.isInitialized}');
      
      if (store.isInitialized) {
        final accessToken = store.tryGet<String>(StoreKey.accessToken);

        _log.info('AuthGuard: Token check: accessToken=${accessToken != null && accessToken.isNotEmpty}');

        // 注意：serverUrl 和 serverEndpoint 现在从 app_config.dart 读取，不再存储在 Store 中
        // 所以只需要检查 accessToken 即可
        // 如果有 token，先允许通过，后台再验证
        if (accessToken != null && accessToken.isNotEmpty) {
          _log.info('✅ AuthGuard: Token found. Allowing navigation, verifying in background.');
          // 后台验证，不阻塞导航
          unawaited(_verifyInBackground(router));
          return;
        }
      }

      // 如果没有 token，立即重定向到登录页
      _log.warning('❌ AuthGuard: No token found. Redirecting to login.');
      router.replaceAll([const LoginRoute()]);
    } catch (e, stackTrace) {
      _log.severe('Error in AuthGuard: $e', e, stackTrace);
      // 出错时重定向到登录页
      router.replaceAll([const LoginRoute()]);
    }
  }

  /// 后台验证认证状态（不阻塞导航）
  Future<void> _verifyInBackground(StackRouter router) async {
    try {
      // 异步获取 AuthService
      final authService = await _ref.read(authServiceProvider.future);
      
      // 使用 AuthService 检查认证状态（可能涉及网络请求）
      final isAuthenticated = await authService.isAuthenticated();

      if (!isAuthenticated) {
        _log.warning('Background verification failed. Redirecting to login.');
        // Token 无效，重定向到登录页
        router.replaceAll([const LoginRoute()]);
        return;
      }

      _log.fine('Background verification successful.');
    } catch (e) {
      _log.warning('Background verification error: $e');
      // 验证失败，但不立即重定向（可能是网络问题）
      // 让用户先看到页面，如果后续操作需要认证，再重定向
    }
  }
}
