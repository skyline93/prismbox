// lib/services/pin/pin_access_control_service.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/services/pin/pin_service_config.dart';
import 'package:prismbox/services/pin/pin_session_service.dart';
import 'package:prismbox/services/biometric/biometric_auth_service.dart';

/// 解锁状态
class UnlockState {
  final String resourceId;
  final DateTime unlockedAt;
  final DateTime expiresAt;

  UnlockState({
    required this.resourceId,
    required this.unlockedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// PIN访问控制服务
/// 负责管理资源的解锁状态和自动锁定机制
class PinAccessControlService {
  final PinServiceConfig _config;
  final PinSessionService _sessionService;
  final BiometricAuthService _biometricAuth;
  final Logger _log = Logger('PinAccessControlService');

  // 内存中维护已解锁资源集合
  final Map<String, UnlockState> _unlockedResources = {};

  // 锁定计时器
  final Map<String, Timer> _lockTimers = {};

  // 定期验证令牌的计时器
  Timer? _tokenValidationTimer;

  // 定期验证令牌的间隔（5分钟）
  static const Duration _tokenValidationInterval = Duration(minutes: 5);

  // Store服务，用于读取用户配置
  final StoreService _store = StoreService();

  PinAccessControlService({
    required PinServiceConfig config,
    required PinSessionService sessionService,
    BiometricAuthService? biometricAuth,
  }) : _config = config,
       _sessionService = sessionService,
       _biometricAuth = biometricAuth ?? BiometricAuthService() {
    // 启动定期验证令牌的计时器
    _startTokenValidationTimer();
  }

  /// 检查资源是否已解锁
  bool isResourceUnlocked(String resourceId) {
    final state = _unlockedResources[resourceId];
    if (state == null) {
      return false;
    }

    if (state.isExpired) {
      // 已过期，清除状态
      _unlockedResources.remove(resourceId);
      _lockTimers[resourceId]?.cancel();
      _lockTimers.remove(resourceId);
      return false;
    }

    return true;
  }

  /// 解锁资源
  /// [useBiometric] 是否使用生物识别认证（如果设备支持）
  Future<void> unlockResource(
    String resourceId, {
    bool useBiometric = true,
  }) async {
    // 如果启用生物识别且设备支持，先进行生物识别认证
    if (useBiometric && await _biometricAuth.isDeviceSupported()) {
      final biometricResult = await _biometricAuth.authenticate(
        reason: '请使用生物识别验证以访问${_config.resourceTypeName}',
      );

      if (!biometricResult.success) {
        // 根据失败类型抛出不同的异常
        if (biometricResult.failure == BiometricAuthFailure.userCancel) {
          throw Exception('Biometric authentication cancelled by user');
        } else {
          throw Exception(
            'Biometric authentication failed: ${biometricResult.failure}',
          );
        }
      }

      _log.info(
        'Biometric authentication succeeded for ${_config.resourceTypeName}: $resourceId',
      );
    }

    // 检查是否有有效的会话令牌
    final hasValidToken = await _sessionService.isSessionTokenValid(resourceId);
    if (!hasValidToken) {
      throw Exception('No valid session token. Please verify password first.');
    }

    // 获取过期时间
    final expiresAt = await _sessionService.getExpiresAt(resourceId);
    if (expiresAt == null) {
      throw Exception('Session token expires_at not found');
    }
    final now = DateTime.now();

    // 获取用户配置的超时时间
    final userTimeout = _getUserConfiguredTimeout();

    // 记录解锁状态
    // 使用用户配置的超时时间和令牌过期时间中的较小值
    final calculatedExpiresAt = expiresAt.isBefore(now.add(userTimeout))
        ? expiresAt
        : now.add(userTimeout);

    _unlockedResources[resourceId] = UnlockState(
      resourceId: resourceId,
      unlockedAt: now,
      expiresAt: calculatedExpiresAt,
    );

    // 启动锁定计时器
    _startLockTimer(resourceId);

    _log.info('${_config.resourceTypeName} unlocked: $resourceId');
  }

  /// 检查设备是否支持生物识别
  Future<bool> isBiometricSupported() async {
    return await _biometricAuth.isDeviceSupported();
  }

  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _biometricAuth.getAvailableBiometrics();
  }

  /// 锁定资源
  void lockResource(String resourceId) {
    _unlockedResources.remove(resourceId);
    _lockTimers[resourceId]?.cancel();
    _lockTimers.remove(resourceId);
    _log.info('${_config.resourceTypeName} locked: $resourceId');
  }

  /// 启动锁定计时器
  void _startLockTimer(String resourceId) {
    // 取消现有计时器
    _lockTimers[resourceId]?.cancel();

    final state = _unlockedResources[resourceId];
    if (state == null) {
      return;
    }

    // 计算剩余时间
    final remaining = state.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      lockResource(resourceId);
      return;
    }

    // 启动计时器
    _lockTimers[resourceId] = Timer(remaining, () {
      lockResource(resourceId);
      _log.info(
        '${_config.resourceTypeName} auto-locked due to timeout: $resourceId',
      );
    });
  }

  /// 设置超时时间（用户可配置）
  /// 此方法用于临时调整单个资源的超时时间
  /// 全局配置应通过StoreService设置
  void setTimeout(String resourceId, Duration timeout) {
    final state = _unlockedResources[resourceId];
    if (state == null) {
      return;
    }

    // 更新过期时间
    final newExpiresAt = DateTime.now().add(timeout);
    _unlockedResources[resourceId] = UnlockState(
      resourceId: resourceId,
      unlockedAt: state.unlockedAt,
      expiresAt: newExpiresAt,
    );

    // 重启计时器
    _startLockTimer(resourceId);
  }

  /// 获取用户配置的超时时间
  /// 从StoreService读取配置，如果未配置则使用默认值
  Duration _getUserConfiguredTimeout() {
    if (!_store.isInitialized) {
      return _config.defaultSessionTimeout;
    }

    final timeoutMinutes = _store.tryGet<int>(
      StoreKey.encryptedSpaceLockTimeoutMinutes,
    );
    if (timeoutMinutes == null || timeoutMinutes <= 0) {
      return _config.defaultSessionTimeout;
    }

    // 支持特殊值：0 表示永不自动锁定（仅令牌过期时锁定）
    if (timeoutMinutes == 0) {
      // 返回一个很长的超时时间（1年），实际由令牌过期时间控制
      return const Duration(days: 365);
    }

    return Duration(minutes: timeoutMinutes);
  }

  /// 设置用户配置的超时时间（分钟）
  /// [minutes] 超时时间（分钟），0 表示永不自动锁定（仅令牌过期时锁定）
  /// 支持的常用值：5, 15, 30, 60, 120, 0（永不）
  Future<void> setUserConfiguredTimeout(int minutes) async {
    if (!_store.isInitialized) {
      _log.warning('Store not initialized, cannot save timeout configuration');
      return;
    }

    await _store.put(StoreKey.encryptedSpaceLockTimeoutMinutes, minutes);
    _log.info('User configured lock timeout: $minutes minutes');

    // 更新所有已解锁资源的超时时间
    final resourceIds = _unlockedResources.keys.toList();
    for (final resourceId in resourceIds) {
      final state = _unlockedResources[resourceId];
      if (state != null) {
        // 重新计算过期时间
        final now = DateTime.now();
        final userTimeout = _getUserConfiguredTimeout();
        final expiresAt = await _sessionService.getExpiresAt(resourceId);

        final newExpiresAt =
            expiresAt != null && expiresAt.isBefore(now.add(userTimeout))
            ? expiresAt
            : now.add(userTimeout);

        _unlockedResources[resourceId] = UnlockState(
          resourceId: resourceId,
          unlockedAt: state.unlockedAt,
          expiresAt: newExpiresAt,
        );

        // 重启计时器
        _startLockTimer(resourceId);
      }
    }
  }

  /// 获取当前用户配置的超时时间（分钟）
  /// 返回 null 表示使用默认值
  int? getUserConfiguredTimeoutMinutes() {
    if (!_store.isInitialized) {
      return null;
    }
    return _store.tryGet<int>(StoreKey.encryptedSpaceLockTimeoutMinutes);
  }

  /// 应用进入后台时锁定所有资源
  void lockAllOnBackground() {
    final resourceIds = _unlockedResources.keys.toList();
    for (final resourceId in resourceIds) {
      lockResource(resourceId);
    }
    _log.info('All ${_config.resourceTypeName}s locked on background');
  }

  /// 应用恢复时检查会话令牌有效性
  Future<void> checkTokensOnResume() async {
    final resourceIds = _unlockedResources.keys.toList();
    for (final resourceId in resourceIds) {
      final isValid = await _sessionService.isSessionTokenValid(resourceId);
      if (!isValid) {
        // 令牌已失效，锁定资源
        lockResource(resourceId);
        _log.info(
          '${_config.resourceTypeName} locked due to invalid token: $resourceId',
        );
      }
    }
  }

  /// 启动定期验证令牌的计时器
  void _startTokenValidationTimer() {
    _tokenValidationTimer?.cancel();
    _tokenValidationTimer = Timer.periodic(_tokenValidationInterval, (_) {
      _validateAllTokens();
    });
  }

  /// 验证所有已解锁资源的令牌
  Future<void> _validateAllTokens() async {
    if (_unlockedResources.isEmpty) {
      return;
    }

    final resourceIds = _unlockedResources.keys.toList();
    for (final resourceId in resourceIds) {
      try {
        final isValid = await _sessionService.isSessionTokenValid(resourceId);
        if (!isValid) {
          // 令牌已失效，锁定资源
          lockResource(resourceId);
          _log.info(
            '${_config.resourceTypeName} auto-locked due to invalid token: $resourceId',
          );
        }
      } catch (e, stackTrace) {
        _log.warning(
          'Failed to validate token for ${_config.resourceTypeName}: $resourceId',
          e,
          stackTrace,
        );
      }
    }
  }

  /// 处理应用生命周期变化
  /// 应该在应用的主 Widget 中调用（通过 WidgetsBindingObserver）
  void handleAppLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // 应用进入后台，锁定所有资源
        lockAllOnBackground();
        break;
      case AppLifecycleState.resumed:
        // 应用恢复，检查令牌有效性
        checkTokensOnResume();
        break;
      case AppLifecycleState.detached:
        // 应用被销毁，清理资源
        dispose();
        break;
    }
  }

  /// 清理资源
  void dispose() {
    _tokenValidationTimer?.cancel();
    _tokenValidationTimer = null;

    for (final timer in _lockTimers.values) {
      timer.cancel();
    }
    _lockTimers.clear();
    _unlockedResources.clear();

    _log.info('PinAccessControlService disposed');
  }
}
