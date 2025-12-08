// lib/presentation/pages/splash/splash_page.dart

import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/auth/auth_state_provider.dart';
import 'package:logging/logging.dart';

/// 启动页面
/// 检查认证状态并导航到相应页面
@RoutePage()
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  final _log = Logger('SplashPage');
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // 延迟一下，让启动画面显示一会儿
    Future.delayed(const Duration(milliseconds: 500), () {
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (_hasNavigated) return;
    
    try {
      // 直接读取认证状态，不重复调用 initialize
      // AuthNotifier 的 build() 方法已经会初始化
      final authState = await ref.read(authNotifierProvider.future);

      if (authState is AuthStateAuthenticated) {
        // 已认证，跳转到主页
        _log.info('User authenticated. Navigating to home.');
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.router.replaceAll([const TabShellRoute()]);
        }
      } else {
        // 未认证，跳转到登录页
        _log.info('User not authenticated. Navigating to login.');
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.router.replaceAll([const LoginRoute()]);
        }
      }
    } catch (e) {
      _log.severe('Error in splash navigation: $e');
      // 出错时跳转到登录页
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        context.router.replaceAll([const LoginRoute()]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_library,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'PrismBox',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
