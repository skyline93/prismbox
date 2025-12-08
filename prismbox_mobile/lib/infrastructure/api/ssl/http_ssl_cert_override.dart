import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:prismbox/config/app_config.dart';
import 'package:prismbox/core/storage/secure_storage_service.dart';

/// SSL客户端证书存储值
class SSLClientCertStoreVal {
  final String data;
  final String? password;

  SSLClientCertStoreVal({
    required this.data,
    this.password,
  });

  /// 从安全存储加载客户端证书
  static Future<SSLClientCertStoreVal?> load() async {
    final secureStorage = SecureStorageService();
    final data = await secureStorage.getClientCertData();
    if (data == null) return null;

    final password = await secureStorage.getClientCertPassword();
    return SSLClientCertStoreVal(
      data: data,
      password: password,
    );
  }
}

/// HTTP SSL证书覆盖实现
/// 实现HttpOverrides以自定义HTTP客户端创建
class HttpSSLCertOverride extends HttpOverrides {
  final bool allowSelfSignedSSLCert;
  final String? serverHost;
  final SSLClientCertStoreVal? clientCert;
  SecurityContext? _securityContext;

  HttpSSLCertOverride({
    required this.allowSelfSignedSSLCert,
    this.serverHost,
    this.clientCert,
  }) {
    // 如果有客户端证书，预创建SecurityContext
    if (clientCert != null) {
      _securityContext = SecurityContext(withTrustedRoots: true);
      try {
        final certBytes = base64Decode(clientCert!.data);
        _securityContext!.usePrivateKeyBytes(
          certBytes,
          password: clientCert!.password,
        );
        _securityContext!.useCertificateChainBytes(certBytes);
      } catch (e) {
        debugPrint('Failed to load client certificate: $e');
        _securityContext = null;
      }
    }
  }

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // 使用预创建的SecurityContext或传入的context
    final securityContext = _securityContext ?? context;

    // 关键修复：使用 super.createHttpClient 而不是直接创建 HttpClient
    // 这样可以避免递归调用 HttpOverrides.global
    // super.createHttpClient 会创建基础的 HttpClient，不会再次触发 HttpOverrides
    final client = super.createHttpClient(securityContext);

    // 设置证书验证回调
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // 如果启用自签名证书
      if (allowSelfSignedSSLCert) {
        // 检查允许的主机列表
        final allowedHosts = SslConfig.allowedSelfSignedHosts;
        
        // 如果列表为空，允许所有主机的自签名证书
        if (allowedHosts.isEmpty) {
          return true;
        }
        
        // 如果列表不为空，检查当前主机是否在允许列表中
        for (final allowedHost in allowedHosts) {
          if (host == allowedHost || 
              host.contains(allowedHost) || 
              allowedHost.contains(host)) {
            return true;
          }
        }
        
        // 如果 serverHost 已设置，也检查是否匹配
        if (serverHost != null) {
          final hostPattern = serverHost!;
          if (host.contains(hostPattern) || hostPattern.contains(host)) {
            return true;
          }
        }
      }

      // 其他情况：拒绝证书
      return false;
    };

    return client;
  }
}


