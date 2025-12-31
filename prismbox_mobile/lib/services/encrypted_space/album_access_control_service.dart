// lib/services/encrypted_space/album_access_control_service.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/services/encrypted_space/session_storage_service.dart';
import 'package:prismbox/services/encrypted_space/biometric_auth_service.dart';

/// 解锁状态
class UnlockState {
  final String albumId;
  final DateTime unlockedAt;
  final DateTime expiresAt;

  UnlockState({
    required this.albumId,
    required this.unlockedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// 相册访问控制服务
/// 负责管理相册的解锁状态和自动锁定机制
class AlbumAccessControlService {
  final SessionStorageService _sessionStorage;
  final BiometricAuthService _biometricAuth;
  final Logger _log = Logger('AlbumAccessControlService');

  // 内存中维护已解锁相册集合
  final Map<String, UnlockState> _unlockedAlbums = {};
  
  // 锁定计时器
  final Map<String, Timer> _lockTimers = {};

  // 定期验证令牌的计时器
  Timer? _tokenValidationTimer;

  // 默认超时时间（30分钟）
  static const Duration _defaultTimeout = Duration(minutes: 30);

  // 定期验证令牌的间隔（5分钟）
  static const Duration _tokenValidationInterval = Duration(minutes: 5);

  // Store服务，用于读取用户配置
  final StoreService _store = StoreService();

  AlbumAccessControlService({
    SessionStorageService? sessionStorage,
    BiometricAuthService? biometricAuth,
  }) : _sessionStorage = sessionStorage ?? SessionStorageService(),
        _biometricAuth = biometricAuth ?? BiometricAuthService() {
    // 启动定期验证令牌的计时器
    _startTokenValidationTimer();
  }

  /// 检查相册是否已解锁
  bool isAlbumUnlocked(String albumId) {
    final state = _unlockedAlbums[albumId];
    if (state == null) {
      return false;
    }

    if (state.isExpired) {
      // 已过期，清除状态
      _unlockedAlbums.remove(albumId);
      _lockTimers[albumId]?.cancel();
      _lockTimers.remove(albumId);
      return false;
    }

    return true;
  }

  /// 解锁相册
  /// [useBiometric] 是否使用生物识别认证（如果设备支持）
  Future<void> unlockAlbum(
    String albumId, {
    bool useBiometric = true,
  }) async {
    // 如果启用生物识别且设备支持，先进行生物识别认证
    if (useBiometric && await _biometricAuth.isDeviceSupported()) {
      final biometricResult = await _biometricAuth.authenticate(
        reason: '请使用生物识别验证以访问加密空间',
      );
      
      if (!biometricResult) {
        throw Exception('Biometric authentication failed or cancelled');
      }
      
      _log.info('Biometric authentication succeeded for album: $albumId');
    }

    // 检查是否有有效的会话令牌
    final hasValidToken = await _sessionStorage.isSessionTokenValid(albumId);
    if (!hasValidToken) {
      throw Exception('No valid session token. Please verify password first.');
    }

    // 获取过期时间
    final expiresAt = await _sessionStorage.getExpiresAt(albumId);
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
    
    _unlockedAlbums[albumId] = UnlockState(
      albumId: albumId,
      unlockedAt: now,
      expiresAt: calculatedExpiresAt,
    );

    // 启动锁定计时器
    _startLockTimer(albumId);

    _log.info('Album unlocked: $albumId');
  }
  
  /// 检查设备是否支持生物识别
  Future<bool> isBiometricSupported() async {
    return await _biometricAuth.isDeviceSupported();
  }
  
  /// 获取可用的生物识别类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _biometricAuth.getAvailableBiometrics();
  }

  /// 锁定相册
  void lockAlbum(String albumId) {
    _unlockedAlbums.remove(albumId);
    _lockTimers[albumId]?.cancel();
    _lockTimers.remove(albumId);
    _log.info('Album locked: $albumId');
  }

  /// 启动锁定计时器
  void _startLockTimer(String albumId) {
    // 取消现有计时器
    _lockTimers[albumId]?.cancel();

    final state = _unlockedAlbums[albumId];
    if (state == null) {
      return;
    }

    // 计算剩余时间
    final remaining = state.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      lockAlbum(albumId);
      return;
    }

    // 启动计时器
    _lockTimers[albumId] = Timer(remaining, () {
      lockAlbum(albumId);
      _log.info('Album auto-locked due to timeout: $albumId');
    });
  }

  /// 设置超时时间（用户可配置）
  /// 此方法用于临时调整单个相册的超时时间
  /// 全局配置应通过StoreService设置
  void setTimeout(String albumId, Duration timeout) {
    final state = _unlockedAlbums[albumId];
    if (state == null) {
      return;
    }

    // 更新过期时间
    final newExpiresAt = DateTime.now().add(timeout);
    _unlockedAlbums[albumId] = UnlockState(
      albumId: albumId,
      unlockedAt: state.unlockedAt,
      expiresAt: newExpiresAt,
    );

    // 重启计时器
    _startLockTimer(albumId);
  }

  /// 获取用户配置的超时时间
  /// 从StoreService读取配置，如果未配置则使用默认值
  Duration _getUserConfiguredTimeout() {
    if (!_store.isInitialized) {
      return _defaultTimeout;
    }

    final timeoutMinutes = _store.tryGet<int>(StoreKey.encryptedSpaceLockTimeoutMinutes);
    if (timeoutMinutes == null || timeoutMinutes <= 0) {
      return _defaultTimeout;
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

    // 更新所有已解锁相册的超时时间
    final albumIds = _unlockedAlbums.keys.toList();
    for (final albumId in albumIds) {
      final state = _unlockedAlbums[albumId];
      if (state != null) {
        // 重新计算过期时间
        final now = DateTime.now();
        final userTimeout = _getUserConfiguredTimeout();
        final expiresAt = await _sessionStorage.getExpiresAt(albumId);
        
        final newExpiresAt = expiresAt != null && expiresAt.isBefore(now.add(userTimeout))
            ? expiresAt
            : now.add(userTimeout);
        
        _unlockedAlbums[albumId] = UnlockState(
          albumId: albumId,
          unlockedAt: state.unlockedAt,
          expiresAt: newExpiresAt,
        );
        
        // 重启计时器
        _startLockTimer(albumId);
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

  /// 应用进入后台时锁定所有相册
  void lockAllOnBackground() {
    final albumIds = _unlockedAlbums.keys.toList();
    for (final albumId in albumIds) {
      lockAlbum(albumId);
    }
    _log.info('All albums locked on background');
  }

  /// 应用恢复时检查会话令牌有效性
  Future<void> checkTokensOnResume() async {
    final albumIds = _unlockedAlbums.keys.toList();
    for (final albumId in albumIds) {
      final isValid = await _sessionStorage.isSessionTokenValid(albumId);
      if (!isValid) {
        // 令牌已失效，锁定相册
        lockAlbum(albumId);
        _log.info('Album locked due to invalid token: $albumId');
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

  /// 验证所有已解锁相册的令牌
  Future<void> _validateAllTokens() async {
    if (_unlockedAlbums.isEmpty) {
      return;
    }

    final albumIds = _unlockedAlbums.keys.toList();
    for (final albumId in albumIds) {
      try {
        final isValid = await _sessionStorage.isSessionTokenValid(albumId);
        if (!isValid) {
          // 令牌已失效，锁定相册
          lockAlbum(albumId);
          _log.info('Album auto-locked due to invalid token: $albumId');
        }
      } catch (e, stackTrace) {
        _log.warning('Failed to validate token for album: $albumId', e, stackTrace);
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
        // 应用进入后台，锁定所有相册
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
    _unlockedAlbums.clear();
    
    _log.info('AlbumAccessControlService disposed');
  }
}

