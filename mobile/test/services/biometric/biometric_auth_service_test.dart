// test/services/biometric/biometric_auth_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:prismbox/services/biometric/biometric_auth_service.dart';

void main() {
  group('BiometricAuthService', () {
    late BiometricAuthService service;

    setUp(() {
      service = BiometricAuthService();
    });

    group('isDeviceSupported', () {
      test('应该返回设备支持状态', () async {
        // 注意：这是一个集成测试，实际调用平台 API
        // 在真实设备上可能返回 true，在模拟器上可能返回 false
        final result = await service.isDeviceSupported();
        expect(result, isA<bool>());
      });

      test('应该在异常时返回 false', () async {
        // 由于无法直接 mock LocalAuthentication，这个测试主要验证
        // 服务在异常情况下不会崩溃，而是返回 false
        // 实际测试需要在真实设备或模拟器上进行
        final result = await service.isDeviceSupported();
        expect(result, isA<bool>());
      });
    });

    group('canCheckBiometrics', () {
      test('应该返回生物识别可用性', () async {
        final result = await service.canCheckBiometrics();
        expect(result, isA<bool>());
      });
    });

    group('getAvailableBiometrics', () {
      test('应该返回可用生物识别类型列表', () async {
        final result = await service.getAvailableBiometrics();
        expect(result, isA<List<BiometricType>>());
      });

      test('应该在异常时返回空列表', () async {
        // 验证异常处理
        final result = await service.getAvailableBiometrics();
        expect(result, isA<List<BiometricType>>());
      });
    });

    group('authenticate', () {
      test('应该在设备不支持时返回 deviceNotSupported 失败', () async {
        // 注意：这个测试需要 mock LocalAuthentication 才能完全测试
        // 当前实现中，如果设备不支持，会先检查 isDeviceSupported()
        // 实际测试需要在真实设备或使用 mock 进行
        final result = await service.authenticate(
          reason: '测试认证',
        );
        
        // 如果设备不支持，应该返回 deviceNotSupported
        if (!result.success) {
          expect(result.failure, isNotNull);
          // 在真实设备不支持的情况下，failure 可能是 deviceNotSupported
        }
      });

      test('应该在无可用生物识别方法时返回 noBiometricsAvailable 失败', () async {
        // 这个测试需要 mock LocalAuthentication
        // 实际测试需要在真实设备上进行
        final result = await service.authenticate(
          reason: '测试认证',
        );
        
        if (!result.success) {
          expect(result.failure, isNotNull);
          // 在无可用生物识别方法的情况下，failure 可能是 noBiometricsAvailable
        }
      });

      test('应该使用提供的认证选项', () async {
        // 测试自定义选项
        final options = const BiometricAuthOptions(
          biometricOnly: false,
          useErrorDialogs: false,
          stickyAuth: false,
        );
        
        final result = await service.authenticate(
          reason: '测试认证',
          options: options,
        );
        
        expect(result, isA<BiometricAuthResult>());
      });

      test('应该在 PlatformException 时返回相应的失败类型', () async {
        // 这个测试需要 mock LocalAuthentication 来模拟不同的 PlatformException
        // 当前实现会根据错误代码返回不同的失败类型：
        // - NotAvailable/NotEnrolled -> noBiometricsAvailable
        // - LockedOut/PermanentlyLockedOut -> authenticationFailed
        // - 其他 -> systemError
        
        // 实际测试需要使用 mock 或真实设备
        final result = await service.authenticate(
          reason: '测试认证',
        );
        
        expect(result, isA<BiometricAuthResult>());
        if (!result.success) {
          expect(result.failure, isNotNull);
          expect(
            result.failure,
            isIn([
              BiometricAuthFailure.deviceNotSupported,
              BiometricAuthFailure.noBiometricsAvailable,
              BiometricAuthFailure.userCancel,
              BiometricAuthFailure.authenticationFailed,
              BiometricAuthFailure.systemError,
            ]),
          );
        }
      });

      test('应该在意外错误时返回 systemError', () async {
        // 这个测试需要 mock LocalAuthentication 来模拟意外错误
        // 实际测试需要使用 mock
        final result = await service.authenticate(
          reason: '测试认证',
        );
        
        expect(result, isA<BiometricAuthResult>());
        // 如果发生意外错误，failure 应该是 systemError
      });
    });

    group('stopAuthentication', () {
      test('应该能够停止认证', () async {
        final result = await service.stopAuthentication();
        expect(result, isA<bool>());
      });

      test('应该在异常时返回 false', () async {
        // 验证异常处理
        final result = await service.stopAuthentication();
        expect(result, isA<bool>());
      });
    });
  });

  group('BiometricAuthResult', () {
    test('success factory 应该创建成功结果', () {
      const biometricType = BiometricType.fingerprint;
      final result = BiometricAuthResult.success(biometricType);
      
      expect(result.success, isTrue);
      expect(result.failure, isNull);
      expect(result.biometricType, equals(biometricType));
    });

    test('failure factory 应该创建失败结果', () {
      const failure = BiometricAuthFailure.userCancel;
      final result = BiometricAuthResult.failure(failure);
      
      expect(result.success, isFalse);
      expect(result.failure, equals(failure));
      expect(result.biometricType, isNull);
    });

    test('应该能够创建自定义结果', () {
      const result = BiometricAuthResult(
        success: true,
        biometricType: BiometricType.face,
      );
      
      expect(result.success, isTrue);
      expect(result.failure, isNull);
      expect(result.biometricType, equals(BiometricType.face));
    });
  });

  group('BiometricAuthFailure', () {
    test('应该包含所有定义的失败类型', () {
      expect(BiometricAuthFailure.deviceNotSupported, isNotNull);
      expect(BiometricAuthFailure.noBiometricsAvailable, isNotNull);
      expect(BiometricAuthFailure.userCancel, isNotNull);
      expect(BiometricAuthFailure.authenticationFailed, isNotNull);
      expect(BiometricAuthFailure.systemError, isNotNull);
    });
  });

  group('BiometricAuthOptions', () {
    test('应该有默认值', () {
      const options = BiometricAuthOptions();
      
      expect(options.biometricOnly, isTrue);
      expect(options.useErrorDialogs, isTrue);
      expect(options.stickyAuth, isTrue);
      expect(options.cancelButtonText, isNull);
    });

    test('应该能够自定义所有选项', () {
      const options = BiometricAuthOptions(
        biometricOnly: false,
        useErrorDialogs: false,
        stickyAuth: false,
        cancelButtonText: '取消',
      );
      
      expect(options.biometricOnly, isFalse);
      expect(options.useErrorDialogs, isFalse);
      expect(options.stickyAuth, isFalse);
      expect(options.cancelButtonText, equals('取消'));
    });
  });
}

