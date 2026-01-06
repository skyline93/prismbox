// lib/services/pin/pin_session_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/services/pin/pin_service_config.dart';
import 'package:prismbox/services/pin/pin_key_derivation_service.dart';
import 'package:prismbox/services/pin/pin_token_encryption_service.dart';

/// PIN会话存储服务
/// 负责加密空间会话令牌的安全存储和检索
/// 使用KDF派生密钥加密会话令牌
class PinSessionService {
  final PinServiceConfig _config;
  final PinKeyDerivationService _keyDerivationService;
  final PinTokenEncryptionService _tokenEncryptionService;
  final Logger _log = Logger('PinSessionService');
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  PinSessionService({
    required PinServiceConfig config,
    required PinKeyDerivationService keyDerivationService,
    required PinTokenEncryptionService tokenEncryptionService,
  }) : _config = config,
       _keyDerivationService = keyDerivationService,
       _tokenEncryptionService = tokenEncryptionService;

  /// 获取会话令牌存储键
  String _getSessionTokenKey(String resourceId) {
    return '${_config.storageKeyPrefix}session_$resourceId';
  }

  /// 获取会话过期时间存储键
  String _getExpiresAtKey(String resourceId) {
    return '${_config.storageKeyPrefix}expires_at_$resourceId';
  }

  /// 获取资源ID列表存储键
  String _getResourceIdsKey() {
    return '${_config.storageKeyPrefix}resource_ids';
  }

  /// 保存会话令牌
  /// 使用KDF派生密钥加密令牌后存储
  Future<void> saveSessionToken({
    required String resourceId,
    required String token,
    required DateTime expiresAt,
    String? password, // 可选：如果提供密码，使用KDF加密；否则使用缓存的密钥
  }) async {
    try {
      String encryptedToken;

      if (password != null) {
        // 从密码派生密钥并加密令牌
        final key = await _keyDerivationService.deriveKey(
          resourceId: resourceId,
          password: password,
        );
        encryptedToken = _tokenEncryptionService.encryptToken(
          token: token,
          key: key,
        );
        // 可选：缓存派生密钥（权衡安全性和性能）
        await _keyDerivationService.saveDerivedKey(
          resourceId: resourceId,
          key: key,
        );
      } else {
        // 尝试使用缓存的密钥
        final cachedKey = await _keyDerivationService.getCachedDerivedKey(
          resourceId,
        );
        if (cachedKey != null) {
          encryptedToken = _tokenEncryptionService.encryptToken(
            token: token,
            key: cachedKey,
          );
        } else {
          // 如果没有缓存的密钥，直接存储（向后兼容）
          // 注意：这不应该发生，因为应该先验证密码
          _log.warning(
            'No cached key found for ${_config.resourceTypeName}: $resourceId, storing token without encryption',
          );
          encryptedToken = token;
        }
      }

      await _storage.write(
        key: _getSessionTokenKey(resourceId),
        value: encryptedToken,
      );
      await _storage.write(
        key: _getExpiresAtKey(resourceId),
        value: expiresAt.toIso8601String(),
      );

      // 添加到资源ID列表
      await _addResourceIdToList(resourceId);

      _log.fine(
        'Session token saved for ${_config.resourceTypeName}: $resourceId',
      );
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to save session token for ${_config.resourceTypeName}: $resourceId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 获取会话令牌
  /// 从加密存储中解密令牌
  Future<String?> getSessionToken(String resourceId) async {
    try {
      // 检查是否过期
      final expiresAtStr = await _storage.read(
        key: _getExpiresAtKey(resourceId),
      );
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          // 已过期，删除令牌
          await deleteSessionToken(resourceId);
          return null;
        }
      }

      final encryptedToken = await _storage.read(
        key: _getSessionTokenKey(resourceId),
      );
      if (encryptedToken == null) {
        return null;
      }

      // 尝试使用缓存的密钥解密
      final cachedKey = await _keyDerivationService.getCachedDerivedKey(
        resourceId,
      );
      if (cachedKey != null) {
        try {
          return _tokenEncryptionService.decryptToken(
            encryptedToken: encryptedToken,
            key: cachedKey,
          );
        } catch (e) {
          // 解密失败，可能是旧格式的未加密令牌
          _log.warning(
            'Failed to decrypt token, trying plain text: $resourceId',
          );
          return encryptedToken; // 向后兼容：返回原始值
        }
      } else {
        // 没有缓存的密钥，可能是旧格式的未加密令牌
        _log.warning(
          'No cached key found for ${_config.resourceTypeName}: $resourceId, returning token as-is',
        );
        return encryptedToken; // 向后兼容：返回原始值
      }
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get session token for ${_config.resourceTypeName}: $resourceId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 删除会话令牌
  Future<void> deleteSessionToken(String resourceId) async {
    try {
      await _storage.delete(key: _getSessionTokenKey(resourceId));
      await _storage.delete(key: _getExpiresAtKey(resourceId));

      // 删除派生密钥（可选，为了安全）
      // 注意：删除密钥后，下次需要使用密码重新派生
      await _keyDerivationService.deleteDerivedKey(resourceId);

      // 从资源ID列表中移除
      await _removeResourceIdFromList(resourceId);

      _log.fine(
        'Session token deleted for ${_config.resourceTypeName}: $resourceId',
      );
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to delete session token for ${_config.resourceTypeName}: $resourceId',
        e,
        stackTrace,
      );
    }
  }

  /// 检查会话令牌是否有效
  Future<bool> isSessionTokenValid(String resourceId) async {
    final token = await getSessionToken(resourceId);
    return token != null;
  }

  /// 获取会话过期时间
  Future<DateTime?> getExpiresAt(String resourceId) async {
    try {
      final expiresAtStr = await _storage.read(
        key: _getExpiresAtKey(resourceId),
      );
      if (expiresAtStr == null) {
        return null;
      }
      return DateTime.parse(expiresAtStr);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get expires at for ${_config.resourceTypeName}: $resourceId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 清除所有会话令牌
  Future<void> clearAllSessions() async {
    try {
      // 获取所有资源ID
      final resourceIds = await _getResourceIdList();

      if (resourceIds.isEmpty) {
        _log.info('No sessions to clear');
        return;
      }

      // 删除所有会话令牌
      for (final resourceId in resourceIds) {
        try {
          await _storage.delete(key: _getSessionTokenKey(resourceId));
          await _storage.delete(key: _getExpiresAtKey(resourceId));
        } catch (e) {
          _log.warning(
            'Failed to delete session token for ${_config.resourceTypeName}: $resourceId',
            e,
          );
        }
      }

      // 清空资源ID列表
      await _storage.delete(key: _getResourceIdsKey());

      _log.info(
        'Cleared all sessions (${resourceIds.length} ${_config.resourceTypeName}s)',
      );
    } catch (e, stackTrace) {
      _log.warning('Failed to clear all sessions', e, stackTrace);
    }
  }

  /// 添加资源ID到列表
  Future<void> _addResourceIdToList(String resourceId) async {
    try {
      final resourceIds = await _getResourceIdList();
      if (!resourceIds.contains(resourceId)) {
        resourceIds.add(resourceId);
        await _storage.write(
          key: _getResourceIdsKey(),
          value: resourceIds.join(','),
        );
      }
    } catch (e) {
      _log.warning('Failed to add resource ID to list: $resourceId', e);
    }
  }

  /// 从列表中移除资源ID
  Future<void> _removeResourceIdFromList(String resourceId) async {
    try {
      final resourceIds = await _getResourceIdList();
      resourceIds.remove(resourceId);
      if (resourceIds.isEmpty) {
        await _storage.delete(key: _getResourceIdsKey());
      } else {
        await _storage.write(
          key: _getResourceIdsKey(),
          value: resourceIds.join(','),
        );
      }
    } catch (e) {
      _log.warning('Failed to remove resource ID from list: $resourceId', e);
    }
  }

  /// 获取资源ID列表
  Future<List<String>> _getResourceIdList() async {
    try {
      final value = await _storage.read(key: _getResourceIdsKey());
      if (value == null || value.isEmpty) {
        return [];
      }
      return value.split(',').where((id) => id.isNotEmpty).toList();
    } catch (e) {
      _log.warning('Failed to get resource ID list', e);
      return [];
    }
  }
}
