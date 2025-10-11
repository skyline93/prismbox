// lib/data/services/dio_client.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart';
import 'package:injectable/injectable.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/data/models/auth/auth_model.dart';
import 'package:mobile/config/app_config.dart';

@lazySingleton
class DioClient {
  /// 用于常规API请求的Dio实例
  final Dio dio;

  /// 专门用于文件传输（上传/下载）的Dio实例
  final Dio fileDio;

  final SecureStorageService _storage;

  /// 当认证失败（如RefreshToken过期）时触发的回调
  Function? onAuthFailure;

  final Lock _refreshTokenLock = Lock();

  /// 专门用于刷新Token的Dio实例，避免拦截器循环
  final Dio _tokenDio = Dio();

  DioClient(this._storage) : dio = Dio(), fileDio = Dio() {
    // ---- 1. 配置常规API的Dio实例 (dio) ----
    dio.options.baseUrl = ApiConfig.baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(minutes: 30);
    dio.options.responseType = ResponseType.json;
    dio.interceptors.addAll([
      _createAuthInterceptor(), // 认证拦截器，处理Token
      RetryInterceptor(
        dio: dio,
        logPrint: log,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
          Duration(seconds: 5),
        ],
        retryEvaluator: (error, attempt) {
          const retryableDioTypes = {
            DioExceptionType.connectionTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.receiveTimeout,
          };

          if (retryableDioTypes.contains(error.type)) {
            return true;
          }

          if (error.type == DioExceptionType.badResponse) {
            final statusCode = error.response?.statusCode;
            if (statusCode != null &&
                defaultRetryableStatuses.contains(statusCode)) {
              return true;
            }
          }

          return false;
        },
      ),
      LogInterceptor(responseBody: true, requestBody: true), // 日志拦截器
    ]);

    // ---- 2. 配置用于文件传输的Dio实例 (fileDio) ----
    // fileDio.options.baseUrl = baseUrl;  // 文件上传下载通常使用完整URL，不设置baseUrl
    fileDio.options.connectTimeout = const Duration(seconds: 60);
    fileDio.options.receiveTimeout = const Duration(minutes: 30);
    fileDio.interceptors.addAll([
      _createAuthInterceptor(),
      RetryInterceptor(
        dio: fileDio,
        logPrint: log,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
          Duration(seconds: 5),
        ],
        retryEvaluator: (error, attempt) {
          const retryableDioTypes = {
            DioExceptionType.connectionTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.receiveTimeout,
          };

          if (retryableDioTypes.contains(error.type)) {
            return true;
          }

          if (error.type == DioExceptionType.badResponse) {
            final statusCode = error.response?.statusCode;
            if (statusCode != null &&
                defaultRetryableStatuses.contains(statusCode)) {
              return true;
            }
          }

          return false;
        },
      ),
      LogInterceptor(
        requestHeader: true,
        responseHeader: true,
        requestBody: false,
        responseBody: false,
      ),
    ]);

    // ---- 3. 配置用于刷新Token的Dio实例 (_tokenDio) ----
    _tokenDio.options.baseUrl = ApiConfig.baseUrl;
  }

  InterceptorsWrapper _createAuthInterceptor() {
    return InterceptorsWrapper(onRequest: _onRequest, onError: _onError);
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: "No Internet Connection",
          type: DioExceptionType.connectionError,
        ),
      );
    }

    final accessToken = await _storage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  Future<void> _onError(DioException e, ErrorInterceptorHandler handler) async {
    if (e.response?.statusCode == 401 &&
        !e.requestOptions.path.contains('refresh')) {
      log("Token expired, attempting to refresh...");

      await _refreshTokenLock.synchronized(() async {
        final currentToken = await _storage.getAccessToken();
        final requestToken = e.requestOptions.headers['Authorization']
            ?.replaceAll('Bearer ', '');
        if (currentToken != null && currentToken != requestToken) {
          log("Token already refreshed by another request.");
          return;
        }
        await _performTokenRefresh();
      });

      try {
        final newAccessToken = await _storage.getAccessToken();
        if (newAccessToken != null) {
          e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final response = e.requestOptions.extra['dio_instance'] == 'file'
              ? await fileDio.fetch(e.requestOptions)
              : await dio.fetch(e.requestOptions);
          return handler.resolve(response);
        }
        throw DioException(
          requestOptions: e.requestOptions,
          error: "Failed to get new token after refresh",
        );
      } on DioException catch (err) {
        return handler.reject(err);
      }
    }
    return handler.next(e);
  }

  Future<void> _performTokenRefresh() async {
    log("--> Interceptor: Starting token refresh...");
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        throw 'No refresh token found';
      }
      final response = await _tokenDio.post(
        '/auth/refresh',
        data: RefreshTokenInput(refreshToken: refreshToken).toJson(),
      );
      final newData = RefreshTokenSuccessData.fromJson(response.data['data']);
      await _storage.saveTokens(
        accessToken: newData.accessToken,
        refreshToken: refreshToken,
      );
      log("--> Interceptor: Token refreshed successfully.");
    } catch (e) {
      log("--> Interceptor: Failed to refresh token. Logging out. Error: $e");
      await _storage.clearTokens();
      onAuthFailure?.call();
      rethrow;
    }
  }
}
