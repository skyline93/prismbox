// lib/data/services/auth_service.dart

import 'package:dio/dio.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/auth/auth_model.dart';
import 'package:mobile/config/app_config.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final Dio _dio;
  final SecureStorageService _storageService;
  final baseUrl = ApiConfig.baseUrl;

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

  // 2. 新增 loginWithApple 方法
  Future<void> loginWithApple() async {
    // 1. 从 Apple 获取凭证
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      // webAuthenticationOptions: WebAuthenticationOptions(
      //   // 替换为你在 Apple Developer Portal 配置的 Service ID
      //   clientId: 'com.yourdomain.app.signin',
      //   // 替换为你在 Service ID 中配置的回调 URL
      // redirectUri: Uri.parse(
      //   '${ApiConfig.defaultServerAddr}/auth/apple/login',
      // ),
      // ),
    );

    // 2. 构造请求体
    final appleInput = AppleLoginInput(
      identityToken: credential.identityToken!,
      fullName: credential.givenName != null || credential.familyName != null
          ? FullName(
              givenName: credential.givenName,
              familyName: credential.familyName,
            )
          : null,
    );

    // 3. 调用后端新 API
    try {
      final response = await _dio.post(
        '$baseUrl/auth/apple/login',
        data: appleInput.toJson(),
      );
      final loginData = UserLoginSuccessData.fromJson(response.data['data']);

      // 4. 保存 Token
      await _storageService.saveTokens(
        accessToken: loginData.accessToken,
        refreshToken: loginData.refreshToken,
      );
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Apple 登录失败';
    }
  }

  // 3. 新增 setPassword 方法
  Future<void> setPassword(String password) async {
    try {
      final input = SetPasswordInput(password: password);
      await _dio.post(
        '$baseUrl/auth/password/set', // 确保这是你的后端端点
        data: input.toJson(),
      );
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? '密码设置失败';
    }
  }

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
