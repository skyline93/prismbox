// lib/services/biometric/biometric_auth_service.dart

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

/// 生物识别认证失败类型
enum BiometricAuthFailure {
  /// 设备不支持生物识别认证
  deviceNotSupported,
  
  /// 无可用的生物识别方法
  noBiometricsAvailable,
  
  /// 用户取消认证
  userCancel,
  
  /// 认证失败（错误的生物识别）
  authenticationFailed,
  
  /// 系统错误
  systemError,
}

/// 生物识别认证结果
class BiometricAuthResult {
  /// 认证是否成功
  final bool success;
  
  /// 失败类型（如果认证失败）
  final BiometricAuthFailure? failure;
  
  /// 使用的生物识别类型（如果认证成功）
  final BiometricType? biometricType;
  
  const BiometricAuthResult({
    required this.success,
    this.failure,
    this.biometricType,
  });
  
  /// 创建成功结果
  factory BiometricAuthResult.success(BiometricType biometricType) {
    return BiometricAuthResult(
      success: true,
      biometricType: biometricType,
    );
  }
  
  /// 创建失败结果
  factory BiometricAuthResult.failure(BiometricAuthFailure failure) {
    return BiometricAuthResult(
      success: false,
      failure: failure,
    );
  }
}

/// 生物识别认证选项
class BiometricAuthOptions {
  /// 仅使用生物识别（不使用设备密码作为fallback）
  final bool biometricOnly;
  
  /// 使用系统错误对话框
  final bool useErrorDialogs;
  
  /// 粘性认证
  final bool stickyAuth;
  
  /// 取消按钮文本（可选）
  final String? cancelButtonText;
  
  const BiometricAuthOptions({
    this.biometricOnly = true,
    this.useErrorDialogs = true,
    this.stickyAuth = true,
    this.cancelButtonText,
  });
}

/// 生物识别认证服务
/// 提供指纹、面部识别等生物识别认证功能
/// 
/// 这是一个通用的服务，不依赖任何特定的业务逻辑，可以被任何需要
/// 生物识别认证的功能模块使用（如加密空间、应用锁、敏感操作验证等）。
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
  /// 
  /// [reason] 认证原因说明（显示给用户）
  /// [options] 认证选项（可选）
  /// 
  /// 返回 [BiometricAuthResult] 包含详细的认证结果信息
  Future<BiometricAuthResult> authenticate({
    required String reason,
    BiometricAuthOptions? options,
  }) async {
    try {
      // 检查设备支持
      if (!await isDeviceSupported()) {
        _log.warning('Biometric authentication not supported on this device');
        return BiometricAuthResult.failure(
          BiometricAuthFailure.deviceNotSupported,
        );
      }

      // 检查是否有可用的生物识别方法
      if (!await canCheckBiometrics()) {
        _log.warning('No biometric methods available');
        return BiometricAuthResult.failure(
          BiometricAuthFailure.noBiometricsAvailable,
        );
      }

      // 获取可用的生物识别类型（用于成功时返回）
      final availableBiometrics = await getAvailableBiometrics();
      final biometricType = availableBiometrics.isNotEmpty
          ? availableBiometrics.first
          : null;

      // 执行认证
      final opts = options ?? const BiometricAuthOptions();
      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: opts.useErrorDialogs,
          stickyAuth: opts.stickyAuth,
          biometricOnly: opts.biometricOnly,
        ),
      );

      if (result) {
        _log.info('Biometric authentication succeeded');
        return BiometricAuthResult.success(
          biometricType ?? BiometricType.strong,
        );
      } else {
        _log.info('Biometric authentication failed or cancelled');
        // 无法区分用户取消和认证失败，默认为用户取消
        return BiometricAuthResult.failure(
          BiometricAuthFailure.userCancel,
        );
      }
    } on PlatformException catch (e, stackTrace) {
      _log.warning('Biometric authentication error: ${e.code}', e, stackTrace);
      
      // 根据错误代码判断失败类型
      BiometricAuthFailure failure;
      switch (e.code) {
        case 'NotAvailable':
          failure = BiometricAuthFailure.noBiometricsAvailable;
          break;
        case 'NotEnrolled':
          failure = BiometricAuthFailure.noBiometricsAvailable;
          break;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          failure = BiometricAuthFailure.authenticationFailed;
          break;
        default:
          failure = BiometricAuthFailure.systemError;
      }
      
      return BiometricAuthResult.failure(failure);
    } catch (e, stackTrace) {
      _log.severe('Unexpected error during biometric authentication', e, stackTrace);
      return BiometricAuthResult.failure(
        BiometricAuthFailure.systemError,
      );
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

