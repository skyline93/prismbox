// test/services/pin/pin_session_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/services/pin/pin_session_service.dart';
import 'package:prismbox/services/pin/pin_key_derivation_service.dart';
import 'package:prismbox/services/pin/pin_token_encryption_service.dart';
import 'package:prismbox/services/pin/pin_service_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinSessionService', () {
    late PinSessionService service;
    late PinServiceConfig config;

    setUp(() {
      config = PinServiceConfig(
        storageKeyPrefix: 'test_',
        resourceTypeName: 'test_resource',
      );
      final keyDerivationService = PinKeyDerivationService(config: config);
      final tokenEncryptionService = PinTokenEncryptionService();
      service = PinSessionService(
        config: config,
        keyDerivationService: keyDerivationService,
        tokenEncryptionService: tokenEncryptionService,
      );
    });

    group('saveSessionToken and getSessionToken', () {
      test('应该能够保存和获取会话令牌', () async {
        const resourceId = 'test-resource-1';
        const token = 'test-token-123';
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        const password = '123456';

        await service.saveSessionToken(
          resourceId: resourceId,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );

        final retrievedToken = await service.getSessionToken(resourceId);

        expect(retrievedToken, equals(token));
      });

      test('过期的令牌应该返回null', () async {
        const resourceId = 'test-resource-2';
        const token = 'test-token-456';
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1)); // 已过期
        const password = '123456';

        await service.saveSessionToken(
          resourceId: resourceId,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );

        final retrievedToken = await service.getSessionToken(resourceId);

        expect(retrievedToken, isNull);
      });

      test('不存在的令牌应该返回null', () async {
        const resourceId = 'non-existent-resource';

        final retrievedToken = await service.getSessionToken(resourceId);

        expect(retrievedToken, isNull);
      });
    });

    group('isSessionTokenValid', () {
      test('有效的令牌应该返回true', () async {
        const resourceId = 'test-resource-1';
        const token = 'test-token-123';
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        const password = '123456';

        await service.saveSessionToken(
          resourceId: resourceId,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );

        final isValid = await service.isSessionTokenValid(resourceId);

        expect(isValid, isTrue);
      });

      test('过期的令牌应该返回false', () async {
        const resourceId = 'test-resource-2';
        const token = 'test-token-456';
        final expiresAt = DateTime.now().subtract(const Duration(hours: 1));
        const password = '123456';

        await service.saveSessionToken(
          resourceId: resourceId,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );

        final isValid = await service.isSessionTokenValid(resourceId);

        expect(isValid, isFalse);
      });
    });

    group('deleteSessionToken', () {
      test('应该能够删除会话令牌', () async {
        const resourceId = 'test-resource-1';
        const token = 'test-token-123';
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        const password = '123456';

        await service.saveSessionToken(
          resourceId: resourceId,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );

        // 验证令牌存在
        final beforeDelete = await service.getSessionToken(resourceId);
        expect(beforeDelete, equals(token));

        // 删除令牌
        await service.deleteSessionToken(resourceId);

        // 验证令牌已删除
        final afterDelete = await service.getSessionToken(resourceId);
        expect(afterDelete, isNull);
      });
    });

    group('getExpiresAt', () {
      test('应该返回正确的过期时间', () async {
        const resourceId = 'test-resource-1';
        const token = 'test-token-123';
        final expiresAt = DateTime.now().add(const Duration(hours: 1));
        const password = '123456';

        await service.saveSessionToken(
          resourceId: resourceId,
          token: token,
          expiresAt: expiresAt,
          password: password,
        );

        final retrievedExpiresAt = await service.getExpiresAt(resourceId);

        expect(retrievedExpiresAt, isNotNull);
        // 允许1秒的误差
        expect(
          retrievedExpiresAt!.difference(expiresAt).inSeconds.abs(),
          lessThan(2),
        );
      });
    });
  });
}

