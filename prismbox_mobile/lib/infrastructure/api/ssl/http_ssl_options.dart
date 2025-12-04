import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_cert_override.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_cert_override.dart' as ssl;

/// SSL/TLS配置管理
class HttpSSLOptions {
  /// 从设置应用SSL配置
  static void apply({bool applyNative = true}) {
    final store = StoreService();
    if (!store.isInitialized) {
      debugPrint('StoreService not initialized, skipping SSL config');
      return;
    }

    final allowSelfSigned = store.tryGet(StoreKey.allowSelfSignedSSLCert) ?? false;
    _apply(allowSelfSigned: allowSelfSigned, applyNative: applyNative);
  }

  /// 响应设置变更
  static void applyFromSettings(bool newValue) {
    final store = StoreService();
    if (!store.isInitialized) {
      debugPrint('StoreService not initialized, skipping SSL config');
      return;
    }

    // 更新设置
    store.put(StoreKey.allowSelfSignedSSLCert, newValue);

    // 立即应用
    _apply(allowSelfSigned: newValue, applyNative: true);
  }

  /// 内部配置逻辑
  static Future<void> _apply({
    required bool allowSelfSigned,
    required bool applyNative,
  }) async {
    // 获取服务器主机（如果已登录）
    String? serverHost;
    final store = StoreService();
    if (store.isInitialized) {
      final endpoint = store.tryGet<String>(StoreKey.serverEndpoint);
      if (endpoint != null) {
        try {
          final uri = Uri.parse(endpoint);
          serverHost = uri.host;
        } catch (e) {
          debugPrint('Failed to parse server endpoint: $e');
        }
      }
    }

    // 加载客户端证书
    final clientCert = await ssl.SSLClientCertStoreVal.load();

    // 设置Dart层HttpOverrides
    HttpOverrides.global = HttpSSLCertOverride(
      allowSelfSignedSSLCert: allowSelfSigned,
      serverHost: serverHost,
      clientCert: clientCert,
    );

    // Android平台原生配置
    if (applyNative && Platform.isAndroid) {
      await _applyAndroidNative(
        allowSelfSigned: allowSelfSigned,
        serverHost: serverHost,
        clientCert: clientCert,
      );
    }
  }

  /// Android平台原生配置
  static Future<void> _applyAndroidNative({
    required bool allowSelfSigned,
    String? serverHost,
    ssl.SSLClientCertStoreVal? clientCert,
  }) async {
    try {
      const channel = MethodChannel('app.prismbox/http_ssl_options');
      await channel.invokeMethod('apply', {
        'allowSelfSigned': allowSelfSigned,
        'serverHost': serverHost,
        'clientCertData': clientCert?.data,
        'clientCertPassword': clientCert?.password,
      });
    } catch (e) {
      // 记录错误但不影响Dart层配置
      debugPrint('Failed to apply Android native SSL config: $e');
    }
  }
}

