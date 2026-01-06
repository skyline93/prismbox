// test/services/pin/pin_access_control_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/services/pin/pin_access_control_service.dart';
import 'package:prismbox/services/pin/pin_session_service.dart';
import 'package:prismbox/services/pin/pin_key_derivation_service.dart';
import 'package:prismbox/services/pin/pin_token_encryption_service.dart';
import 'package:prismbox/services/pin/pin_service_config.dart';
import 'package:prismbox/services/biometric/biometric_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinAccessControlService', () {
    late PinAccessControlService service;
    late PinServiceConfig config;
    late PinSessionService sessionService;

    setUp(() {
      config = PinServiceConfig(
        storageKeyPrefix: 'test_',
        resourceTypeName: 'test_resource',
      );
      final keyDerivationService = PinKeyDerivationService(config: config);
      final tokenEncryptionService = PinTokenEncryptionService();
      sessionService = PinSessionService(
        config: config,
        keyDerivationService: keyDerivationService,
        tokenEncryptionService: tokenEncryptionService,
      );
      service = PinAccessControlService(
        config: config,
        sessionService: sessionService,
        biometricAuth: BiometricAuthService(),
      );
    });

    tearDown(() {
      service.dispose();
    });

    group('isResourceUnlocked', () {
      test('未解锁的资源应该返回false', () {
        const resourceId = 'test-resource-1';

        final isUnlocked = service.isResourceUnlocked(resourceId);

        expect(isUnlocked, isFalse);
      });
    });

    group('unlockResource', () {
      test('应该能够解锁资源（需要有效的会话令牌）', () async {
        const resourceId = 'test-resource-1';
        const token = 'test-token-123';
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        const password = '123456';

        // 先保存会话令牌
        await sessionService.saveSessionToken(
          resourceId: resourceId,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );

        // 解锁资源（不使用生物识别）
        await service.unlockResource(
          resourceId,
          useBiometric: false,
        );

        // 验证资源已解锁
        final isUnlocked = service.isResourceUnlocked(resourceId);
        expect(isUnlocked, isTrue);
      });

      test('没有有效令牌时应该抛出异常', () async {
        const resourceId = 'test-resource-2';

        expect(
          () => service.unlockResource(
            resourceId,
            useBiometric: false,
          ),
          throwsException,
        );
      });
    });

    group('lockResource', () {
      test('应该能够锁定资源', () async {
        const resourceId = 'test-resource-1';
        const token = 'test-token-123';
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        const password = '123456';

        // 先保存会话令牌并解锁
        await sessionService.saveSessionToken(
          resourceId: resourceId,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );
        await service.unlockResource(resourceId, useBiometric: false);

        // 验证资源已解锁
        expect(service.isResourceUnlocked(resourceId), isTrue);

        // 锁定资源
        service.lockResource(resourceId);

        // 验证资源已锁定
        expect(service.isResourceUnlocked(resourceId), isFalse);
      });
    });

    group('lockAllOnBackground', () {
      test('应该锁定所有已解锁的资源', () async {
        const resourceId1 = 'test-resource-1';
        const resourceId2 = 'test-resource-2';
        const token = 'test-token-123';
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        const password = '123456';

        // 解锁两个资源
        await sessionService.saveSessionToken(
          resourceId: resourceId1,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );
        await sessionService.saveSessionToken(
          resourceId: resourceId2,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );

        await service.unlockResource(resourceId1, useBiometric: false);
        await service.unlockResource(resourceId2, useBiometric: false);

        // 验证两个资源都已解锁
        expect(service.isResourceUnlocked(resourceId1), isTrue);
        expect(service.isResourceUnlocked(resourceId2), isTrue);

        // 锁定所有资源
        service.lockAllOnBackground();

        // 验证两个资源都已锁定
        expect(service.isResourceUnlocked(resourceId1), isFalse);
        expect(service.isResourceUnlocked(resourceId2), isFalse);
      });
    });

    group('dispose', () {
      test('应该能够清理资源', () {
        service.dispose();

        // 验证服务可以正常使用（不会抛出异常）
        expect(service.isResourceUnlocked('test-resource'), isFalse);
      });
    });
  });
}

