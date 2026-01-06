// lib/services/pin/pin_auth_service.dart

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/services/pin/pin_service_config.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// PIN认证服务
/// 负责与后端API交互，处理PIN码的设置、验证和更改
class PinAuthService {
  final PinServiceConfig _config;
  final ApiService _apiService;
  final String _apiEndpointPrefix;
  final Logger _log = Logger('PinAuthService');

  PinAuthService({
    required PinServiceConfig config,
    required ApiService apiService,
    required String apiEndpointPrefix,
  }) : _config = config,
       _apiService = apiService,
       _apiEndpointPrefix = apiEndpointPrefix;

  /// 设置PIN码
  Future<void> setPin({required String resourceId, required String pin}) async {
    try {
      await _apiService.dio.post(
        '$_apiEndpointPrefix/$resourceId/password',
        data: {'password': pin},
      );

      _log.info('PIN set for ${_config.resourceTypeName}: $resourceId');
    } on DioException catch (e) {
      _log.severe(
        'Failed to set PIN for ${_config.resourceTypeName}: $resourceId',
        e,
      );
      rethrow;
    }
  }

  /// 验证PIN码并获取会话令牌
  Future<PinVerificationResult> verifyPin({
    required String resourceId,
    required String pin,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '$_apiEndpointPrefix/$resourceId/verify-password',
        data: {'password': pin},
      );

      // 响应拦截器已自动提取 data 字段，response.data 已经是业务数据
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final expiresAt = DateTime.parse(data['expires_at'] as String);

      _log.info('PIN verified for ${_config.resourceTypeName}: $resourceId');

      return PinVerificationResult(token: token, expiresAt: expiresAt);
    } on DioException catch (e) {
      _log.severe(
        'Failed to verify PIN for ${_config.resourceTypeName}: $resourceId',
        e,
      );
      rethrow;
    }
  }

  /// 更改PIN码
  /// 需要提供旧PIN进行验证
  Future<void> changePin({
    required String resourceId,
    required String oldPin,
    required String newPin,
  }) async {
    try {
      await _apiService.dio.post(
        '$_apiEndpointPrefix/$resourceId/password/change',
        data: {'old_password': oldPin, 'new_password': newPin},
      );

      _log.info('PIN changed for ${_config.resourceTypeName}: $resourceId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('旧密码错误');
      }
      _log.severe(
        'Failed to change PIN for ${_config.resourceTypeName}: $resourceId',
        e,
      );
      rethrow;
    }
  }

  /// 检查PIN是否已设置
  /// 通过尝试调用验证API，如果返回"PIN not set"错误，说明未设置
  /// 如果返回其他错误（如"Invalid PIN"），说明PIN已设置，只是输入错误
  Future<bool> checkIfPinIsSet({required String resourceId}) async {
    try {
      // 尝试验证一个无效的PIN
      // 如果返回"PIN not set"错误，说明PIN未设置
      // 如果返回"Invalid PIN"错误，说明PIN已设置，只是输入错误
      await _apiService.dio.post(
        '$_apiEndpointPrefix/$resourceId/verify-password',
        data: {'password': '000000'}, // 使用一个无效的PIN
      );
      // 如果验证成功（不应该发生），说明PIN已设置
      return true;
    } on DioException catch (e) {
      // 检查错误消息或状态码
      if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data?.toString().toLowerCase() ?? '';
        // 如果错误消息包含"PIN not set"或"not set for this album"，说明PIN未设置
        if (errorMessage.contains('pin not set') ||
            errorMessage.contains('not set for this album') ||
            errorMessage.contains('password not set')) {
          return false; // PIN未设置
        }
      }
      // 其他错误（如"Invalid PIN"、400等）说明PIN已设置，只是输入错误或格式错误
      return true;
    } catch (e) {
      // 未知错误，默认假设PIN已设置（保守策略）
      _log.warning('Failed to check if PIN is set, assuming it is set', e);
      return true;
    }
  }
}

/// PIN验证结果
class PinVerificationResult {
  final String token;
  final DateTime expiresAt;

  PinVerificationResult({required this.token, required this.expiresAt});
}
