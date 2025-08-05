// ignore_for_file: unused_field

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/config/app_config.dart';

class ApiService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Ref _ref;

  ApiService({required FlutterSecureStorage secureStorage, required ref})
    : _secureStorage = secureStorage,
      _ref = ref {
    _dio = Dio(
      BaseOptions(
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
      ),
    );
  }

  Dio get dio => _dio;

  Future<String> getServerAddr() async {
    final savedServerAddr = await _secureStorage.read(key: 'server_addr');
    if (savedServerAddr != null && savedServerAddr.isNotEmpty) {
      return savedServerAddr;
    }
    return ApiConfig.defaultServerAddr;
  }

  Future<void> setServerAddr(String addr) async {
    await _secureStorage.write(key: 'server_addr', value: addr.trim());
  }

  Future<String> getApiBaseUrl() async {
    String serverAddr = await getServerAddr();
    return '$serverAddr/api/${ApiConfig.apiVersion}';
  }

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);

      if (response.data != null && response.data['data'] != null) {
        final data = response.data['data'];
        if (fromJson != null) {
          return fromJson(data);
        }
        return data as T;
      }
      throw Exception('Invalid response format');
    } catch (e) {
      throw _handleApiError(e);
    }
  }

  Exception _handleApiError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null &&
          error.response?.data['message'] != null) {
        return Exception(error.response?.data['message']);
      }
      return Exception('网络请求失败: ${error.message}');
    }
    return Exception('API请求失败: $error');
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService(secureStorage: const FlutterSecureStorage(), ref: ref);
});
