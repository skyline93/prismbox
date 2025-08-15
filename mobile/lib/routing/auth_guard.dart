// lib/router/auth_guard.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart';
import 'package:mobile/auth/auth_state.dart';
import 'package:mobile/providers.dart';

class AuthGuard extends AutoRouteGuard {
  final Ref ref;

  AuthGuard(this.ref);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    // 这里我们不直接读取状态，而是监听它，以便在状态改变时（例如，从initial到unauthenticated）作出反应
    // 但对于Guard，一次性读取通常足够
    final authState = ref.read(authNotifierProvider);

    if (authState == const AuthState.authenticated()) {
      // 如果已认证，继续导航
      resolver.next(true);
    } else {
      // 否则，重定向到登录页
      // 使用 replaceAll 防止用户返回到受保护的页面
      router.replaceAll([const LoginRoute()]);
    }
  }
}
