import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prismbox/core/storage/secure_storage_service.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/presentation/routing/app_router.dart';
import 'package:prismbox/providers/infrastructure/api_service_provider.dart';
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
      final secureStorage = SecureStorageService();
      final accessToken = await secureStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        // 没有 token，跳转到登录页
        _log.info('No access token found. Navigating to login.');
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.router.replaceAll([const LoginRoute()]);
        }
        return;
      }

      // 有 token，验证有效性
      final apiService = ref.read(apiServiceProvider);
      await apiService.setAccessToken(accessToken);

      try {
        // 尝试 ping 服务器验证 token
        await apiService.pingServer();
        // token 有效，跳转到主页面
        _log.info('Access token valid. Navigating to home.');
        if (mounted && !_hasNavigated) {
          _hasNavigated = true;
          context.router.replaceAll([const TabShellRoute()]);
        }
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          // token 无效，清除并跳转到登录页
          _log.warning('Access token invalid (401). Navigating to login.');
          await apiService.clearAccessToken();
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            context.router.replaceAll([const LoginRoute()]);
          }
        } else {
          // 其他错误，也跳转到登录页
          _log.warning('Server ping failed. Navigating to login.');
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            context.router.replaceAll([const LoginRoute()]);
          }
        }
      } catch (e) {
        // 网络错误等，跳转到登录页
        _log.warning('Error checking auth: $e. Navigating to login.');
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

