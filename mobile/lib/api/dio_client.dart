// lib/api/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/models/auth_models.dart';
import '../../core/storage/secure_storage_service.dart';
import 'package:mobile/auth/notifiers/auth_notifier.dart';
import 'package:mobile/config/app_config.dart';

class DioClient {
  final Dio dio;
  final Ref _ref;

  Future<void>? _refreshTokenFuture;
  final Dio _tokenDio = Dio();

  final String baseUrl = DioClient.getBaseUrl();

  DioClient(this.dio, this._ref) {
    dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(milliseconds: 15000)
      ..options.receiveTimeout = const Duration(milliseconds: 15000)
      ..options.responseType = ResponseType.json
      ..interceptors.add(LogInterceptor(responseBody: true, requestBody: true))
      ..interceptors.add(_createAuthInterceptor());
  }

  static String getBaseUrl() {
    return "${ApiConfig.defaultServerAddr}/api/v1";
  }

  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final storage = _ref.read(secureStorageServiceProvider);
        final accessToken = await storage.getAccessToken();

        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        if (e.response?.statusCode == 401 &&
            !e.requestOptions.path.contains('refresh')) {
          print("接口需要认证");
          // 使用 _refreshTokenFuture 作为“锁”
          _refreshTokenFuture ??= _performTokenRefresh();

          try {
            // 等待刷新操作完成
            await _refreshTokenFuture;

            // 刷新完成后，用新的 Token 重试原始请求
            final newAccessToken = await _ref
                .read(secureStorageServiceProvider)
                .getAccessToken();
            e.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final response = await dio.fetch(e.requestOptions);
            return handler.resolve(response);
          } catch (error) {
            // 如果刷新过程中发生错误（包括刷新失败），则拒绝原始请求
            return handler.reject(e);
          }
        }
        print("未知异常>>>>>>>>>>>>>>>>{$e}");
        return handler.next(e);
      },
    );
  }

  /// 执行 Token 刷新，并处理成功或失败的情况。
  Future<void> _performTokenRefresh() async {
    print("--> Interceptor: Starting token refresh...");
    try {
      final storage = _ref.read(secureStorageServiceProvider);
      final refreshToken = await storage.getRefreshToken();
      if (refreshToken == null) {
        print("No refresh token found");
        throw 'No refresh token found';
      }

      final response = await _tokenDio.post(
        '$baseUrl/auth/refresh',
        data: RefreshTokenInput(refreshToken: refreshToken).toJson(),
      );

      final newData = RefreshTokenSuccessData.fromJson(response.data['data']);
      final newAccessToken = newData.accessToken;

      await storage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: refreshToken,
      );
      print("--> Interceptor: Token refreshed successfully.");
    } catch (e) {
      print("--> Interceptor: Failed to refresh token. Logging out. Error: $e");
      // 刷新失败，执行登出
      await _ref.read(authNotifierProvider.notifier).logout();
      // 抛出错误，以便等待的请求知道刷新失败了
      rethrow;
    } finally {
      // 无论成功或失败，最后都将 _refreshTokenFuture 设为 null，以便下次可以再次触发刷新
      _refreshTokenFuture = null;
      print("--> Interceptor: Token refresh process finished.");
    }
  }
}
