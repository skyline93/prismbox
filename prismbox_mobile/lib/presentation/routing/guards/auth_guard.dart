import 'package:auto_route/auto_route.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/storage/secure_storage_service.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/presentation/routing/app_router.dart';

/// 认证守卫
/// 检查用户是否已登录，验证访问令牌有效性
class AuthGuard extends AutoRouteGuard {
  final ApiService _apiService;
  final SecureStorageService _secureStorage;
  final _log = Logger('AuthGuard');

  AuthGuard(this._apiService)
      : _secureStorage = SecureStorageService();

  @override
  void onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    // 先允许导航，后续验证失败则重定向
    resolver.next(true);

    try {
      // 检查存储中的访问令牌
      final accessToken = await _secureStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        _log.warning('No access token found. Redirecting to login.');
        router.replaceAll([const LoginRoute()]);
        return;
      }

      // 同步 ApiService 中的 token
      final storedToken = _apiService.getAccessToken();
      if (storedToken != accessToken) {
        await _apiService.setAccessToken(accessToken);
      }

      // 验证服务器连接（替代 validateAccessToken 方法）
      // 通过 ping 服务器来验证 token 有效性
      try {
        await _apiService.pingServer();
      } on ApiException catch (e) {
        // 如果是 401 错误，说明 token 无效
        if (e.statusCode == 401) {
          _log.warning('Token validation failed (401). Redirecting to login.');
          await _apiService.clearAccessToken();
          router.replaceAll([const LoginRoute()]);
          return;
        }
        // 其他 API 错误（如 500 等）不影响导航，继续执行
        _log.fine('Server ping failed with API error, but continuing navigation: $e');
      } catch (e) {
        // 网络错误等其他异常不影响导航，继续执行
        _log.fine('Server ping failed, but continuing navigation: $e');
      }
    } catch (e) {
      _log.severe('Error validating access token: $e');
      // 验证失败时重定向到登录页
      router.replaceAll([const LoginRoute()]);
    }
  }
}

