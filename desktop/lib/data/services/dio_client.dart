import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:synchronized/synchronized.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../core/config/app_config.dart';
import '../datasources/remote/models/auth_model.dart';
import 'secure_storage_service.dart';

// @lazySingleton  -> Removed injectable, will be handled by Riverpod
class DioClient {
  final Dio dio;
  final Dio fileDio;
  final SecureStorageService _storage;

  Function? onAuthFailure;
  final Lock _refreshTokenLock = Lock();
  final Dio _tokenDio = Dio();
  final String baseUrl = DioClient.getBaseUrl();

  DioClient(this._storage) : dio = Dio(), fileDio = Dio() {
    // ---- 1. Configure regular API Dio instance (dio) ----
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(minutes: 30);
    dio.options.responseType = ResponseType.json;
    dio.interceptors.addAll([
      _createAuthInterceptor(),
      RetryInterceptor(
        dio: dio,
        logPrint: log,
        retries: 3,
        retryDelays: const [
          Duration(seconds: 1),
          Duration(seconds: 3),
          Duration(seconds: 5),
        ],
        // retryableExtraStatuses: const {10060}, // Example for specific statuses
        retryEvaluator: (error, attempt) {
          return DioException.connectionTimeout == error.type ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout;
        },
      ),
      LogInterceptor(responseBody: true, requestBody: true),
    ]);

    // ---- 2. Configure file transfer Dio instance (fileDio) ----
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
        // retryableExtraStatuses: const {10060}, // Example for specific statuses
        retryEvaluator: (error, attempt) {
          return DioException.connectionTimeout == error.type ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout;
        },
      ),
      LogInterceptor(
        requestHeader: true,
        responseHeader: true,
        requestBody: false,
        responseBody: false,
      ),
    ]);

    // ---- 3. Configure token refresh Dio instance (_tokenDio) ----
    _tokenDio.options.baseUrl = baseUrl;
  }

  static String getBaseUrl() {
    return "${ApiConfig.defaultServerAddr}/api/v1";
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

      try {
        await _refreshTokenLock.synchronized(() async {
          final currentToken = await _storage.getAccessToken();
          final requestToken = e.requestOptions.headers['Authorization']
              ?.replaceAll('Bearer ', '');

          if (currentToken == null || currentToken != requestToken) {
            log("Token already refreshed by another request or cleared.");
            // Token was already refreshed, we can just retry the original request
          } else {
            await _performTokenRefresh();
          }
        });

        final newAccessToken = await _storage.getAccessToken();
        if (newAccessToken != null) {
          e.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
          final response = e.requestOptions.extra['dio_instance'] == 'file'
              ? await fileDio.fetch(e.requestOptions)
              : await dio.fetch(e.requestOptions);
          return handler.resolve(response);
        } else {
          throw DioException(
            requestOptions: e.requestOptions,
            error: "Failed to get new token after refresh",
          );
        }
      } catch (err) {
        log("Refresh token failed or request retry failed. Error: $err");
        // Propagate the error to be handled by the caller
        return handler.next(e);
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
