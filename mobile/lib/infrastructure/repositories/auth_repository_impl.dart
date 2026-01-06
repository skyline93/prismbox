// lib/infrastructure/repositories/auth_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:prismbox/domain/repositories/auth_repository.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/infrastructure/api/exceptions/api_exception.dart';
import 'package:prismbox/infrastructure/api/models/auth/auth_response_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/login_request_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/register_request_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/register_response_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/refresh_token_response_dto.dart';
import 'package:prismbox/infrastructure/api/models/auth/user_profile_dto.dart';
import 'package:prismbox/infrastructure/api/utils/response_validator.dart';

/// 认证仓库实现
class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;

  AuthRepositoryImpl(this._apiService);

  @override
  Future<AuthResponseDto> login(LoginRequestDto request) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/auth/login',
        data: request.toJson(),
      );

      // ResponseInterceptor 已自动提取 data 字段
      // 使用工具类验证和提取数据
      final data = ResponseValidator.validateAndExtract(response);
      return AuthResponseDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<RegisterResponseDto> register(RegisterRequestDto request) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/auth/register',
        data: request.toJson(),
      );

      // 使用工具类验证和提取数据
      final data = ResponseValidator.validateAndExtract(response);
      return RegisterResponseDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<RefreshTokenResponseDto> refreshToken(String refreshToken) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      // 使用工具类验证和提取数据
      final data = ResponseValidator.validateAndExtract(response);
      return RefreshTokenResponseDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _apiService.dio.post(
        '/api/v1/auth/logout',
        data: {'refresh_token': refreshToken},
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<UserProfileDto> getProfile() async {
    try {
      final response = await _apiService.dio.get('/api/v1/auth/profile');

      // 使用工具类验证和提取数据
      final data = ResponseValidator.validateAndExtract(response);
      return UserProfileDto.fromJson(data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// 处理错误
  ApiException _handleError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode ?? 500;
      final data = e.response!.data;
      String message = '请求失败';

      if (data is Map<String, dynamic>) {
        message = data['message'] as String? ?? message;
      } else if (data is String) {
        message = data;
      }

      return ApiException(statusCode, message);
    }
    return ApiException(503, '网络错误: ${e.message}');
  }
}

