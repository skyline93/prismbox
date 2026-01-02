// test/services/pin/pin_token_encryption_service_test.dart

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/services/pin/pin_token_encryption_service.dart';

void main() {
  group('PinTokenEncryptionService', () {
    late PinTokenEncryptionService service;

    setUp(() {
      service = PinTokenEncryptionService();
    });

    group('encryptToken', () {
      test('应该成功加密令牌', () {
        const token = 'test-token-123';
        final key = Uint8List.fromList(List.generate(32, (i) => i));

        final encrypted = service.encryptToken(
          token: token,
          key: key,
        );

        expect(encrypted, isNotEmpty);
        expect(encrypted, isNot(equals(token)));
      });

      test('相同输入应该产生不同的加密结果（由于随机IV）', () async {
        const token = 'test-token-123';
        final key = Uint8List.fromList(List.generate(32, (i) => i));

        final encrypted1 = service.encryptToken(
          token: token,
          key: key,
        );
        
        // 等待一小段时间确保时间戳不同
        await Future.delayed(const Duration(milliseconds: 10));
        
        final encrypted2 = service.encryptToken(
          token: token,
          key: key,
        );

        // 由于使用了随机IV，每次加密结果应该不同
        expect(encrypted1, isNot(equals(encrypted2)));
      });
    });

    group('decryptToken', () {
      test('应该成功解密加密的令牌', () {
        const token = 'test-token-123';
        final key = Uint8List.fromList(List.generate(32, (i) => i));

        final encrypted = service.encryptToken(
          token: token,
          key: key,
        );
        final decrypted = service.decryptToken(
          encryptedToken: encrypted,
          key: key,
        );

        expect(decrypted, equals(token));
      });

      test('使用错误的密钥应该抛出异常', () {
        const token = 'test-token-123';
        final correctKey = Uint8List.fromList(List.generate(32, (i) => i));
        final wrongKey = Uint8List.fromList(List.generate(32, (i) => i + 1));

        final encrypted = service.encryptToken(
          token: token,
          key: correctKey,
        );

        expect(
          () => service.decryptToken(
            encryptedToken: encrypted,
            key: wrongKey,
          ),
          throwsException,
        );
      });

      test('无效的加密令牌格式应该抛出异常', () {
        final key = Uint8List.fromList(List.generate(32, (i) => i));

        expect(
          () => service.decryptToken(
            encryptedToken: 'invalid-format',
            key: key,
          ),
          throwsException,
        );
      });
    });

    group('加密解密循环', () {
      test('应该能够加密和解密各种长度的令牌', () {
        final testTokens = [
          'short',
          'medium-length-token',
          'very-long-token-' + 'x' * 100,
          'token-with-special-chars-!@#\$%^&*()',
          'token-with-unicode-测试-🚀',
        ];

        final key = Uint8List.fromList(List.generate(32, (i) => i));

        for (final token in testTokens) {
          final encrypted = service.encryptToken(
            token: token,
            key: key,
          );
          final decrypted = service.decryptToken(
            encryptedToken: encrypted,
            key: key,
          );

          expect(decrypted, equals(token), reason: 'Failed for token: $token');
        }
      });
    });
  });
}

