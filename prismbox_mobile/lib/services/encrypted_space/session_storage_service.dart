// lib/services/encrypted_space/session_storage_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/services/encrypted_space/key_derivation_service.dart';
import 'package:prismbox/services/encrypted_space/token_encryption_service.dart';

/// 会话存储服务
/// 负责加密空间会话令牌的安全存储和检索
/// 使用KDF派生密钥加密会话令牌
class SessionStorageService {
  static final SessionStorageService _instance = SessionStorageService._internal();
  factory SessionStorageService() => _instance;
  SessionStorageService._internal();

  final Logger _log = Logger('SessionStorageService');
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  final KeyDerivationService _keyDerivationService = KeyDerivationService();
  final TokenEncryptionService _tokenEncryptionService = TokenEncryptionService();

  // 维护相册ID列表，用于清除所有会话令牌
  static const String _albumIdsKey = 'encrypted_space_album_ids';

  /// 获取会话令牌存储键
  String _getSessionTokenKey(String albumId) {
    return 'encrypted_space_session_$albumId';
  }

  /// 获取会话过期时间存储键
  String _getExpiresAtKey(String albumId) {
    return 'encrypted_space_expires_at_$albumId';
  }

  /// 保存会话令牌
  /// 使用KDF派生密钥加密令牌后存储
  Future<void> saveSessionToken({
    required String albumId,
    required String token,
    required DateTime expiresAt,
    String? password, // 可选：如果提供密码，使用KDF加密；否则使用缓存的密钥
  }) async {
    try {
      String encryptedToken;
      
      if (password != null) {
        // 从密码派生密钥并加密令牌
        final key = await _keyDerivationService.deriveKey(
          albumId: albumId,
          password: password,
        );
        encryptedToken = _tokenEncryptionService.encryptToken(
          token: token,
          key: key,
        );
        // 可选：缓存派生密钥（权衡安全性和性能）
        await _keyDerivationService.saveDerivedKey(
          albumId: albumId,
          key: key,
        );
      } else {
        // 尝试使用缓存的密钥
        final cachedKey = await _keyDerivationService.getCachedDerivedKey(albumId);
        if (cachedKey != null) {
          encryptedToken = _tokenEncryptionService.encryptToken(
            token: token,
            key: cachedKey,
          );
        } else {
          // 如果没有缓存的密钥，直接存储（向后兼容）
          // 注意：这不应该发生，因为应该先验证密码
          _log.warning('No cached key found for album: $albumId, storing token without encryption');
          encryptedToken = token;
        }
      }
      
      await _storage.write(
        key: _getSessionTokenKey(albumId),
        value: encryptedToken,
      );
      await _storage.write(
        key: _getExpiresAtKey(albumId),
        value: expiresAt.toIso8601String(),
      );
      
      // 添加到相册ID列表
      await _addAlbumIdToList(albumId);
      
      _log.fine('Session token saved for album: $albumId');
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to save session token for album: $albumId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 获取会话令牌
  /// 从加密存储中解密令牌
  Future<String?> getSessionToken(String albumId) async {
    try {
      // 检查是否过期
      final expiresAtStr = await _storage.read(key: _getExpiresAtKey(albumId));
      if (expiresAtStr != null) {
        final expiresAt = DateTime.parse(expiresAtStr);
        if (DateTime.now().isAfter(expiresAt)) {
          // 已过期，删除令牌
          await deleteSessionToken(albumId);
          return null;
        }
      }

      final encryptedToken = await _storage.read(key: _getSessionTokenKey(albumId));
      if (encryptedToken == null) {
        return null;
      }

      // 尝试使用缓存的密钥解密
      final cachedKey = await _keyDerivationService.getCachedDerivedKey(albumId);
      if (cachedKey != null) {
        try {
          return _tokenEncryptionService.decryptToken(
            encryptedToken: encryptedToken,
            key: cachedKey,
          );
        } catch (e) {
          // 解密失败，可能是旧格式的未加密令牌
          _log.warning('Failed to decrypt token, trying plain text: $albumId');
          return encryptedToken; // 向后兼容：返回原始值
        }
      } else {
        // 没有缓存的密钥，可能是旧格式的未加密令牌
        _log.warning('No cached key found for album: $albumId, returning token as-is');
        return encryptedToken; // 向后兼容：返回原始值
      }
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get session token for album: $albumId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 删除会话令牌
  Future<void> deleteSessionToken(String albumId) async {
    try {
      await _storage.delete(key: _getSessionTokenKey(albumId));
      await _storage.delete(key: _getExpiresAtKey(albumId));
      
      // 删除派生密钥（可选，为了安全）
      // 注意：删除密钥后，下次需要使用密码重新派生
      await _keyDerivationService.deleteDerivedKey(albumId);
      
      // 从相册ID列表中移除
      await _removeAlbumIdFromList(albumId);
      
      _log.fine('Session token deleted for album: $albumId');
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to delete session token for album: $albumId',
        e,
        stackTrace,
      );
    }
  }

  /// 检查会话令牌是否有效
  Future<bool> isSessionTokenValid(String albumId) async {
    final token = await getSessionToken(albumId);
    return token != null;
  }

  /// 获取会话过期时间
  Future<DateTime?> getExpiresAt(String albumId) async {
    try {
      final expiresAtStr = await _storage.read(key: _getExpiresAtKey(albumId));
      if (expiresAtStr == null) {
        return null;
      }
      return DateTime.parse(expiresAtStr);
    } catch (e, stackTrace) {
      _log.warning(
        'Failed to get expires at for album: $albumId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 清除所有会话令牌
  Future<void> clearAllSessions() async {
    try {
      // 获取所有相册ID
      final albumIds = await _getAlbumIdList();
      
      if (albumIds.isEmpty) {
        _log.info('No sessions to clear');
        return;
      }

      // 删除所有会话令牌
      for (final albumId in albumIds) {
        try {
          await _storage.delete(key: _getSessionTokenKey(albumId));
          await _storage.delete(key: _getExpiresAtKey(albumId));
        } catch (e) {
          _log.warning('Failed to delete session token for album: $albumId', e);
        }
      }

      // 清空相册ID列表
      await _storage.delete(key: _albumIdsKey);

      _log.info('Cleared all sessions (${albumIds.length} albums)');
    } catch (e, stackTrace) {
      _log.warning('Failed to clear all sessions', e, stackTrace);
    }
  }

  /// 添加相册ID到列表
  Future<void> _addAlbumIdToList(String albumId) async {
    try {
      final albumIds = await _getAlbumIdList();
      if (!albumIds.contains(albumId)) {
        albumIds.add(albumId);
        await _storage.write(
          key: _albumIdsKey,
          value: albumIds.join(','),
        );
      }
    } catch (e) {
      _log.warning('Failed to add album ID to list: $albumId', e);
    }
  }

  /// 从列表中移除相册ID
  Future<void> _removeAlbumIdFromList(String albumId) async {
    try {
      final albumIds = await _getAlbumIdList();
      albumIds.remove(albumId);
      if (albumIds.isEmpty) {
        await _storage.delete(key: _albumIdsKey);
      } else {
        await _storage.write(
          key: _albumIdsKey,
          value: albumIds.join(','),
        );
      }
    } catch (e) {
      _log.warning('Failed to remove album ID from list: $albumId', e);
    }
  }

  /// 获取相册ID列表
  Future<List<String>> _getAlbumIdList() async {
    try {
      final value = await _storage.read(key: _albumIdsKey);
      if (value == null || value.isEmpty) {
        return [];
      }
      return value.split(',').where((id) => id.isNotEmpty).toList();
    } catch (e) {
      _log.warning('Failed to get album ID list', e);
      return [];
    }
  }
}

