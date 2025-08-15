// lib/data/services/dio_client.dart

import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart';
import 'package:injectable/injectable.dart';
import '../models/auth/auth_model.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'package:mobile/config/app_config.dart';

@lazySingleton
class DioClient {
  final Dio dio;
  final SecureStorageService _storage;
  Function? onAuthFailure;

  final Lock _refreshTokenLock = Lock();
  final Dio _tokenDio = Dio();

  final String baseUrl = DioClient.getBaseUrl();

  DioClient(this._storage) : dio = Dio() {
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

  Future<void> _onRequest(options, handler) async {
    final accessToken = await _storage.getAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  Future<void> _onError(DioException e, handler) async {
    if (e.response?.statusCode == 401 &&
        !e.requestOptions.path.contains('refresh')) {
      print("接口需要认证");

      await _refreshTokenLock.synchronized(() async {
        final newAccessToken = await _storage.getAccessToken();
        final oldAccessToken = e.requestOptions.headers['Authorization']
            ?.replaceAll('Bearer ', '');

        if (newAccessToken != null && newAccessToken != oldAccessToken) {
          return;
        }

        await _performTokenRefresh();
      });

      try {
        final newAccessToken = await _storage.getAccessToken();
        e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final response = await dio.fetch(e.requestOptions);
        return handler.resolve(response);
      } on DioException catch (err) {
        // 如果重試時仍然出錯，則拒絕
        return handler.reject(err);
      }
    }

    print("未知异常>>>>>>>>>>>>>>>>{$e}");
    return handler.next(e);
  }

  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(onRequest: _onRequest, onError: _onError);
  }

  /// 執行 Token 刷新，並處理成功或失敗的情況。
  Future<void> _performTokenRefresh() async {
    print("--> Interceptor: Starting token refresh...");
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw 'No refresh token found';
      }

      final response = await _tokenDio.post(
        '$baseUrl/auth/refresh',
        data: RefreshTokenInput(refreshToken: refreshToken).toJson(),
      );

      final newData = RefreshTokenSuccessData.fromJson(response.data['data']);
      await _storage.saveTokens(
        accessToken: newData.accessToken,
        refreshToken: refreshToken,
      );
      print("--> Interceptor: Token refreshed successfully.");
    } catch (e) {
      print("--> Interceptor: Failed to refresh token. Logging out. Error: $e");

      onAuthFailure?.call();
      rethrow;
    }
  }
}
