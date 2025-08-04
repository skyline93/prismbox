// lib/api/services/auth_service.dart
import 'package:dio/dio.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/auth_models.dart';
import 'package:mobile/api/dio_client.dart';

class AuthService {
  final Dio _dio;
  final SecureStorageService _storageService;
  final baseUrl = DioClient.getBaseUrl();

  AuthService(this._dio, this._storageService);

  Future<void> login(UserLoginInput input) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/login',
        data: input.toJson(),
      );
      final loginData = UserLoginSuccessData.fromJson(response.data['data']);

      await _storageService.saveTokens(
        accessToken: loginData.accessToken,
        refreshToken: loginData.refreshToken,
      );
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? '网络错误，请稍后重试';
    }
  }

  Future<void> logout() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken != null) {
      try {
        // 使用一个独立的Dio实例来登出，避免登出请求本身因token问题被拦截
        final logoutDio = Dio();
        logoutDio.post(
          '$baseUrl/auth/logout',
          data: {'refresh_token': refreshToken},
        );
      } catch (_) {
        // 忽略错误
      }
    }
    await _storageService.clearTokens();
  }

  // 注册逻辑保持不变
  Future<UserRegisterSuccessData> register(UserRegisterInput input) async {
    try {
      final response = await _dio.post(
        '$baseUrl/auth/register',
        data: input.toJson(),
      );
      return UserRegisterSuccessData.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? '注册失败';
    }
  }

  Future<GetProfileSuccessData> getProfile() async {
    try {
      final response = await _dio.get('$baseUrl/auth/profile');
      return GetProfileSuccessData.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? '获取用户信息失败';
    }
  }
}
