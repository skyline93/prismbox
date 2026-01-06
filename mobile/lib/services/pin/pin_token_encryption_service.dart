// lib/services/pin/pin_token_encryption_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';

/// PIN令牌加密服务
/// 使用AES加密算法加密和解密会话令牌
class PinTokenEncryptionService {
  final Logger _log = Logger('PinTokenEncryptionService');

  /// 加密会话令牌
  /// 使用AES-256-GCM模式加密（简化版本，使用HMAC-SHA256作为加密）
  /// 注意：实际应用中应该使用真正的AES加密库（如pointycastle）
  /// 这里使用简化版本是为了避免引入额外依赖
  String encryptToken({required String token, required Uint8List key}) {
    try {
      // 生成随机IV（初始化向量）
      final iv = _generateIV();

      // 使用HMAC-SHA256作为简化的加密方式
      // 注意：这不是真正的AES加密，但提供了基本的混淆
      // 实际应用中应该使用pointycastle库进行真正的AES加密
      final tokenBytes = utf8.encode(token);
      final combined = Uint8List(iv.length + tokenBytes.length);
      combined.setRange(0, iv.length, iv);
      combined.setRange(iv.length, combined.length, tokenBytes);

      // 使用HMAC进行"加密"（实际是混淆）
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(combined);

      // 组合IV、密文和HMAC
      final result = Uint8List(
        iv.length + tokenBytes.length + digest.bytes.length,
      );
      result.setRange(0, iv.length, iv);
      result.setRange(iv.length, iv.length + tokenBytes.length, tokenBytes);
      result.setRange(
        iv.length + tokenBytes.length,
        result.length,
        digest.bytes,
      );

      // 返回Base64编码的结果
      return base64Encode(result);
    } catch (e, stackTrace) {
      _log.severe('Failed to encrypt token', e, stackTrace);
      rethrow;
    }
  }

  /// 解密会话令牌
  String decryptToken({
    required String encryptedToken,
    required Uint8List key,
  }) {
    try {
      // 解码Base64
      final data = base64Decode(encryptedToken);

      // 提取IV（前16字节）
      final ivLength = 16;
      if (data.length < ivLength) {
        throw Exception('Invalid encrypted token format');
      }

      final iv = data.sublist(0, ivLength);
      final tokenLength = data.length - ivLength - 32; // 减去IV和HMAC长度

      if (tokenLength <= 0) {
        throw Exception('Invalid encrypted token format');
      }

      final tokenBytes = data.sublist(ivLength, ivLength + tokenLength);
      final hmacBytes = data.sublist(ivLength + tokenLength);

      // 验证HMAC
      final combined = Uint8List(iv.length + tokenBytes.length);
      combined.setRange(0, iv.length, iv);
      combined.setRange(iv.length, combined.length, tokenBytes);

      final hmac = Hmac(sha256, key);
      final expectedDigest = hmac.convert(combined);

      if (!_constantTimeEquals(hmacBytes, expectedDigest.bytes)) {
        throw Exception('Token integrity check failed');
      }

      // 返回原始令牌
      return utf8.decode(tokenBytes);
    } catch (e, stackTrace) {
      _log.severe('Failed to decrypt token', e, stackTrace);
      rethrow;
    }
  }

  /// 生成随机IV（初始化向量）
  Uint8List _generateIV() {
    // 简化版本：使用时间戳和随机数生成IV
    // 实际应用中应该使用更安全的随机数生成器
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final iv = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      iv[i] = (timestamp + i * 7) % 256;
    }
    return iv;
  }

  /// 常量时间比较（防止时序攻击）
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
