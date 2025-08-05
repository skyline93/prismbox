// lib/api/dio_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synchronized/synchronized.dart'; // 導入 synchronized 套件
import '../models/auth/auth_model.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'package:mobile/auth/auth_notifier.dart';
import 'package:mobile/config/app_config.dart';

class DioClient {
  final Dio dio;
  final Ref _ref;

  // 為 token 刷新操作建立一個鎖
  final Lock _refreshTokenLock = Lock();
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

  Future<void> _onRequest(options, handler) async {
    final storage = _ref.read(secureStorageServiceProvider);
    final accessToken = await storage.getAccessToken();

    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  Future<void> _onError(DioException e, handler) async {
    if (e.response?.statusCode == 401 &&
        !e.requestOptions.path.contains('refresh')) {
      print("接口需要认证");

      // 使用 synchronized 鎖定刷新 token 的區塊
      await _refreshTokenLock.synchronized(() async {
        // 在鎖定後再次檢查 token，因為可能在等待鎖的過程中，token 已經被其他請求刷新了
        final storage = _ref.read(secureStorageServiceProvider);
        final newAccessToken = await storage.getAccessToken();

        // 如果當前的 access token 和請求失敗時的 token 不一樣，說明 token 已經被刷新
        final oldAccessToken = e.requestOptions.headers['Authorization']
            ?.replaceAll('Bearer ', '');
        if (newAccessToken != oldAccessToken) {
          return; // 直接返回，後續會用新的 token 重試
        }

        await _performTokenRefresh();
      });

      try {
        // 重試原始請求
        final newAccessToken = await _ref
            .read(secureStorageServiceProvider)
            .getAccessToken();
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

      await storage.saveTokens(
        accessToken: newData.accessToken,
        refreshToken: refreshToken,
      );
      print("--> Interceptor: Token refreshed successfully.");
    } catch (e) {
      print("--> Interceptor: Failed to refresh token. Logging out. Error: $e");
      // 刷新失敗，執行登出
      await _ref.read(authNotifierProvider.notifier).logout();
      // 拋出錯誤，以便等待的請求知道刷新失敗了
      rethrow;
    }
  }
}
