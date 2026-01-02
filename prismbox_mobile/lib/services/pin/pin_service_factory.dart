// lib/services/pin/pin_service_factory.dart

import 'package:prismbox/services/pin/pin_service_config.dart';
import 'package:prismbox/services/pin/pin_auth_service.dart';
import 'package:prismbox/services/pin/pin_session_service.dart';
import 'package:prismbox/services/pin/pin_key_derivation_service.dart';
import 'package:prismbox/services/pin/pin_token_encryption_service.dart';
import 'package:prismbox/services/pin/pin_access_control_service.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/biometric/biometric_auth_service.dart';

/// PIN服务工厂
/// 用于创建配置好的PIN服务实例
class PinServiceFactory {
  /// 创建加密空间专用的PIN服务配置
  static PinServiceConfig createEncryptedSpaceConfig() {
    return PinServiceConfig(
      storageKeyPrefix: 'encrypted_space_',
      resourceTypeName: 'album',
      defaultSessionTimeout: const Duration(minutes: 30),
    );
  }

  /// 创建PIN认证服务
  static PinAuthService createAuthService({
    required PinServiceConfig config,
    ApiService? apiService,
    String? apiEndpointPrefix,
  }) {
    return PinAuthService(
      config: config,
      apiService: apiService ?? ApiService(),
      apiEndpointPrefix: apiEndpointPrefix ?? '/api/v1/albums',
    );
  }

  /// 创建PIN会话服务
  static PinSessionService createSessionService({
    required PinServiceConfig config,
    PinKeyDerivationService? keyDerivationService,
    PinTokenEncryptionService? tokenEncryptionService,
  }) {
    return PinSessionService(
      config: config,
      keyDerivationService:
          keyDerivationService ?? PinKeyDerivationService(config: config),
      tokenEncryptionService:
          tokenEncryptionService ?? PinTokenEncryptionService(),
    );
  }

  /// 创建PIN密钥派生服务
  static PinKeyDerivationService createKeyDerivationService({
    required PinServiceConfig config,
  }) {
    return PinKeyDerivationService(config: config);
  }

  /// 创建PIN令牌加密服务
  static PinTokenEncryptionService createTokenEncryptionService() {
    return PinTokenEncryptionService();
  }

  /// 创建PIN访问控制服务
  static PinAccessControlService createAccessControlService({
    required PinServiceConfig config,
    PinSessionService? sessionService,
    BiometricAuthService? biometricAuth,
  }) {
    return PinAccessControlService(
      config: config,
      sessionService: sessionService ?? createSessionService(config: config),
      biometricAuth: biometricAuth ?? BiometricAuthService(),
    );
  }

  /// 创建完整的PIN服务套件（用于加密空间）
  static PinServiceSuite createEncryptedSpaceSuite({
    ApiService? apiService,
    BiometricAuthService? biometricAuth,
  }) {
    final config = createEncryptedSpaceConfig();
    final keyDerivationService = createKeyDerivationService(config: config);
    final tokenEncryptionService = createTokenEncryptionService();
    final sessionService = createSessionService(
      config: config,
      keyDerivationService: keyDerivationService,
      tokenEncryptionService: tokenEncryptionService,
    );
    final authService = createAuthService(
      config: config,
      apiService: apiService,
    );
    final accessControlService = createAccessControlService(
      config: config,
      sessionService: sessionService,
      biometricAuth: biometricAuth,
    );

    return PinServiceSuite(
      config: config,
      authService: authService,
      sessionService: sessionService,
      keyDerivationService: keyDerivationService,
      tokenEncryptionService: tokenEncryptionService,
      accessControlService: accessControlService,
    );
  }
}

/// PIN服务套件
/// 包含所有PIN相关服务的组合
class PinServiceSuite {
  final PinServiceConfig config;
  final PinAuthService authService;
  final PinSessionService sessionService;
  final PinKeyDerivationService keyDerivationService;
  final PinTokenEncryptionService tokenEncryptionService;
  final PinAccessControlService accessControlService;

  PinServiceSuite({
    required this.config,
    required this.authService,
    required this.sessionService,
    required this.keyDerivationService,
    required this.tokenEncryptionService,
    required this.accessControlService,
  });
}
