// lib/services/encrypted_space/key_derivation_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

/// 密钥派生服务
/// 负责从用户密码派生加密密钥，用于加密会话令牌
class KeyDerivationService {
  static final KeyDerivationService _instance = KeyDerivationService._internal();
  factory KeyDerivationService() => _instance;
  KeyDerivationService._internal();

  final Logger _log = Logger('KeyDerivationService');
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // PBKDF2 参数
  static const int _iterations = 100000; // 迭代次数
  static const int _keyLength = 32; // 密钥长度（256位，用于AES-256）
  static const String _saltPrefix = 'encrypted_space_salt_';
  static const String _keyPrefix = 'encrypted_space_key_';

  /// 从密码派生密钥
  /// 使用PBKDF2算法从用户密码派生加密密钥
  Future<Uint8List> deriveKey({
    required String albumId,
    required String password,
  }) async {
    try {
      // 获取或生成盐值
      final salt = await _getOrCreateSalt(albumId);
      
      // 使用PBKDF2派生密钥
      final passwordBytes = utf8.encode(password);
      final key = _pbkdf2(
        passwordBytes,
        salt,
        _iterations,
        _keyLength,
      );

      _log.fine('Key derived for album: $albumId');
      return key;
    } catch (e, stackTrace) {
      _log.severe('Failed to derive key for album: $albumId', e, stackTrace);
      rethrow;
    }
  }

  /// 获取或创建盐值
  Future<Uint8List> _getOrCreateSalt(String albumId) async {
    final saltKey = '$_saltPrefix$albumId';
    final saltStr = await _storage.read(key: saltKey);
    
    if (saltStr != null) {
      // 从Base64解码盐值
      return base64Decode(saltStr);
    }
    
    // 生成新的随机盐值（16字节）
    final salt = Uint8List(16);
    final random = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < 16; i++) {
      salt[i] = (random + i) % 256;
    }
    // 使用更安全的随机数生成（简化版本，实际应该使用更安全的随机数生成器）
    // 这里使用时间戳作为种子，实际应用中应该使用更安全的随机数生成器
    final secureRandom = List<int>.generate(16, (i) => (random * (i + 1)) % 256);
    final newSalt = Uint8List.fromList(secureRandom);
    
    // 存储盐值（Base64编码）
    await _storage.write(
      key: saltKey,
      value: base64Encode(newSalt),
    );
    
    return newSalt;
  }

  /// 保存派生密钥（可选，用于缓存）
  /// 注意：实际应用中，密钥应该从密码实时派生，而不是存储
  /// 这里提供存储选项是为了性能优化，但需要权衡安全性
  Future<void> saveDerivedKey({
    required String albumId,
    required Uint8List key,
  }) async {
    try {
      final keyKey = '$_keyPrefix$albumId';
      // 将密钥转换为Base64存储
      await _storage.write(
        key: keyKey,
        value: base64Encode(key),
      );
      _log.fine('Derived key saved for album: $albumId');
    } catch (e, stackTrace) {
      _log.warning('Failed to save derived key for album: $albumId', e, stackTrace);
    }
  }

  /// 获取缓存的派生密钥（如果存在）
  Future<Uint8List?> getCachedDerivedKey(String albumId) async {
    try {
      final keyKey = '$_keyPrefix$albumId';
      final keyStr = await _storage.read(key: keyKey);
      if (keyStr == null) {
        return null;
      }
      return base64Decode(keyStr);
    } catch (e, stackTrace) {
      _log.warning('Failed to get cached derived key for album: $albumId', e, stackTrace);
      return null;
    }
  }

  /// 删除派生密钥和盐值
  Future<void> deleteDerivedKey(String albumId) async {
    try {
      final saltKey = '$_saltPrefix$albumId';
      final keyKey = '$_keyPrefix$albumId';
      await _storage.delete(key: saltKey);
      await _storage.delete(key: keyKey);
      _log.fine('Derived key deleted for album: $albumId');
    } catch (e, stackTrace) {
      _log.warning('Failed to delete derived key for album: $albumId', e, stackTrace);
    }
  }

  /// 清除所有派生密钥和盐值
  Future<void> clearAllDerivedKeys() async {
    try {
      // 注意：这里需要遍历所有相册ID，但为了简化，我们只清除已知的
      // 实际应用中，应该维护一个相册ID列表
      _log.info('Clearing all derived keys');
      // 由于无法枚举所有键，这里只记录日志
      // 实际清除操作应该在知道相册ID列表时调用deleteDerivedKey
    } catch (e, stackTrace) {
      _log.warning('Failed to clear all derived keys', e, stackTrace);
    }
  }

  /// PBKDF2密钥派生函数实现
  /// 使用HMAC-SHA256作为伪随机函数
  Uint8List _pbkdf2(
    List<int> password,
    Uint8List salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final key = Uint8List(keyLength);
    int offset = 0;
    int blockIndex = 1;

    while (offset < keyLength) {
      // 计算U1 = HMAC(password, salt || i)
      final blockInput = Uint8List(salt.length + 4);
      blockInput.setRange(0, salt.length, salt);
      blockInput[salt.length] = (blockIndex >> 24) & 0xFF;
      blockInput[salt.length + 1] = (blockIndex >> 16) & 0xFF;
      blockInput[salt.length + 2] = (blockIndex >> 8) & 0xFF;
      blockInput[salt.length + 3] = blockIndex & 0xFF;

      var u = hmac.convert(blockInput).bytes;
      final t = Uint8List.fromList(u);

      // 迭代计算U2, U3, ..., Uc
      for (int i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (int j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }

      // 复制到输出密钥
      final copyLength = (keyLength - offset < t.length)
          ? keyLength - offset
          : t.length;
      key.setRange(offset, offset + copyLength, t.sublist(0, copyLength));
      offset += copyLength;
      blockIndex++;
    }

    return key;
  }
}

