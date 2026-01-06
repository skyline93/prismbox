// test/services/pin/pin_key_derivation_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/services/pin/pin_key_derivation_service.dart';
import 'package:prismbox/services/pin/pin_service_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PinKeyDerivationService', () {
    late PinKeyDerivationService service;
    late PinServiceConfig config;

    setUp(() {
      config = PinServiceConfig(
        storageKeyPrefix: 'test_',
        resourceTypeName: 'test_resource',
      );
      service = PinKeyDerivationService(config: config);
    });

    group('deriveKey', () {
      test('应该从PIN派生密钥', () async {
        const resourceId = 'test-resource-1';
        const password = '123456';

        final key = await service.deriveKey(
          resourceId: resourceId,
          password: password,
        );

        expect(key, isNotNull);
        expect(key.length, equals(32)); // 256位 = 32字节
      });

      test('相同PIN应该派生相同的密钥', () async {
        const resourceId = 'test-resource-1';
        const password = '123456';

        final key1 = await service.deriveKey(
          resourceId: resourceId,
          password: password,
        );
        final key2 = await service.deriveKey(
          resourceId: resourceId,
          password: password,
        );

        expect(key1, equals(key2));
      });

      test('不同PIN应该派生不同的密钥', () async {
        const resourceId = 'test-resource-1';
        const password1 = '123456';
        const password2 = '654321';

        final key1 = await service.deriveKey(
          resourceId: resourceId,
          password: password1,
        );
        final key2 = await service.deriveKey(
          resourceId: resourceId,
          password: password2,
        );

        expect(key1, isNot(equals(key2)));
      });

      test('不同资源ID应该派生不同的密钥（即使PIN相同）', () async {
        const password = '123456';
        const resourceId1 = 'test-resource-1';
        const resourceId2 = 'test-resource-2';

        final key1 = await service.deriveKey(
          resourceId: resourceId1,
          password: password,
        );
        final key2 = await service.deriveKey(
          resourceId: resourceId2,
          password: password,
        );

        expect(key1, isNot(equals(key2)));
      });
    });

    group('saveDerivedKey and getCachedDerivedKey', () {
      test('应该能够保存和获取缓存的密钥', () async {
        const resourceId = 'test-resource-1';
        const password = '123456';

        final key = await service.deriveKey(
          resourceId: resourceId,
          password: password,
        );

        await service.saveDerivedKey(
          resourceId: resourceId,
          key: key,
        );

        final cachedKey = await service.getCachedDerivedKey(resourceId);

        expect(cachedKey, isNotNull);
        expect(cachedKey, equals(key));
      });

      test('未缓存的密钥应该返回null', () async {
        const resourceId = 'test-resource-2';

        final cachedKey = await service.getCachedDerivedKey(resourceId);

        expect(cachedKey, isNull);
      });
    });

    group('deleteDerivedKey', () {
      test('应该能够删除缓存的密钥', () async {
        const resourceId = 'test-resource-1';
        const password = '123456';

        final key = await service.deriveKey(
          resourceId: resourceId,
          password: password,
        );

        await service.saveDerivedKey(
          resourceId: resourceId,
          key: key,
        );

        // 验证密钥已缓存
        final cachedBefore = await service.getCachedDerivedKey(resourceId);
        expect(cachedBefore, isNotNull);

        // 删除密钥
        await service.deleteDerivedKey(resourceId);

        // 验证密钥已删除
        final cachedAfter = await service.getCachedDerivedKey(resourceId);
        expect(cachedAfter, isNull);
      });
    });
  });
}

