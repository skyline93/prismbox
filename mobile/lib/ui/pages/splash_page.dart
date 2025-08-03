// lib/ui/pages/splash_page.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/notifiers/auth_notifier.dart';
import 'package:mobile/routing/app_router.dart';

@RoutePage()
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听认证状态变化
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenOrNull(
        authenticated: () => context.router.replaceAll([const HomeRoute()]),
        unauthenticated: () => context.router.replaceAll([const LoginRoute()]),
        error: (message) => context.router.replaceAll([const LoginRoute()]),
      );
    });

    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
