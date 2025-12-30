// lib/services/encrypted_space/biometric_auth_service.dart

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

/// 生物识别认证服务
/// 提供指纹、面部识别等生物识别认证功能
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final Logger _log = Logger('BiometricAuthService');
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// 检查设备是否支持生物识别
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (e, stackTrace) {
      _log.warning('Failed to check device support', e, stackTrace);
      return false;
    }
  }

  /// 检查是否有可用的生物识别方法
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e, stackTrace) {
      _log.warning('Failed to check biometrics availability', e, stackTrace);
      return false;
    }
  }

  /// 获取可用的生物识别类型列表
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e, stackTrace) {
      _log.warning('Failed to get available biometrics', e, stackTrace);
      return [];
    }
  }

  /// 执行生物识别认证
  /// [reason] 认证原因说明（显示给用户）
  /// 返回true表示认证成功，false表示认证失败或取消
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // 检查设备支持
      if (!await isDeviceSupported()) {
        _log.warning('Biometric authentication not supported on this device');
        return false;
      }

      // 检查是否有可用的生物识别方法
      if (!await canCheckBiometrics()) {
        _log.warning('No biometric methods available');
        return false;
      }

      // 执行认证
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // 仅使用生物识别，不使用设备密码
        ),
      );

      if (result) {
        _log.info('Biometric authentication succeeded');
      } else {
        _log.info('Biometric authentication failed or cancelled');
      }

      return result;
    } on PlatformException catch (e, stackTrace) {
      _log.warning('Biometric authentication error: ${e.code}', e, stackTrace);
      return false;
    } catch (e, stackTrace) {
      _log.severe('Unexpected error during biometric authentication', e, stackTrace);
      return false;
    }
  }

  /// 停止认证（如果正在进行）
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } catch (e, stackTrace) {
      _log.warning('Failed to stop authentication', e, stackTrace);
      return false;
    }
  }
}

