import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

/// 安全存储服务
/// 用于存储敏感信息，如Token等
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final Logger _log = Logger('SecureStorageService');
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _accessTokenKey = 'prismbox_access_token';
  static const String _refreshTokenKey = 'prismbox_refresh_token';
  static const String _clientCertDataKey = 'prismbox_client_cert_data';
  static const String _clientCertPasswordKey = 'prismbox_client_cert_password';

  /// 保存访问令牌
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
    _log.fine('Access token saved');
  }

  /// 获取访问令牌
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  /// 删除访问令牌
  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
    _log.fine('Access token deleted');
  }

  /// 保存刷新令牌
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
    _log.fine('Refresh token saved');
  }

  /// 获取刷新令牌
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// 删除刷新令牌
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
    _log.fine('Refresh token deleted');
  }

  /// 保存客户端证书数据
  Future<void> setClientCertData(String data) async {
    await _storage.write(key: _clientCertDataKey, value: data);
    _log.fine('Client cert data saved');
  }

  /// 获取客户端证书数据
  Future<String?> getClientCertData() async {
    return await _storage.read(key: _clientCertDataKey);
  }

  /// 删除客户端证书数据
  Future<void> deleteClientCertData() async {
    await _storage.delete(key: _clientCertDataKey);
  }

  /// 保存客户端证书密码
  Future<void> setClientCertPassword(String password) async {
    await _storage.write(key: _clientCertPasswordKey, value: password);
    _log.fine('Client cert password saved');
  }

  /// 获取客户端证书密码
  Future<String?> getClientCertPassword() async {
    return await _storage.read(key: _clientCertPasswordKey);
  }

  /// 删除客户端证书密码
  Future<void> deleteClientCertPassword() async {
    await _storage.delete(key: _clientCertPasswordKey);
  }

  /// 清除所有安全存储的数据
  Future<void> clearAll() async {
    await _storage.deleteAll();
    _log.info('All secure storage cleared');
  }
}

