import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:prismbox/config/app_config.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_cert_override.dart';
import 'package:prismbox/infrastructure/api/ssl/http_ssl_cert_override.dart' as ssl;

/// SSL/TLS配置管理
class HttpSSLOptions {
  /// 从 AppConfig 应用 SSL 配置
  /// 
  /// 从编译时配置（AppConfig）读取 SSL 设置并应用
  /// 这是主要的配置方式，适用于开发/生产环境的区分
  static Future<void> apply({bool applyNative = true}) async {
    // 从 AppConfig 读取配置
    final allowSelfSigned = SslConfig.allowSelfSignedCert;
    
    await _apply(
      allowSelfSigned: allowSelfSigned,
      applyNative: applyNative,
    );
  }

  /// 运行时动态应用 SSL 配置（可选）
  /// 
  /// 用于在运行时动态切换 SSL 配置
  /// 注意：主要配置应通过 AppConfig 设置，此方法仅用于特殊场景
  /// 
  /// [allowSelfSigned] 是否允许自签名证书
  /// [applyNative] 是否应用 Android 原生配置
  static Future<void> applyWithConfig({
    required bool allowSelfSigned,
    bool applyNative = true,
  }) async {
    await _apply(
      allowSelfSigned: allowSelfSigned,
      applyNative: applyNative,
    );
  }

  /// 响应设置变更（保留用于兼容性，但推荐使用 AppConfig）
  /// 
  /// 注意：此方法会更新 StoreService 中的设置，但实际配置仍以 AppConfig 为准
  /// 建议直接修改 AppConfig 并重新编译应用
  @Deprecated('推荐使用 AppConfig.ssl.allowSelfSignedCert 配置，修改后重新编译应用')
  static Future<void> applyFromSettings(bool newValue) async {
    final store = StoreService();
    if (store.isInitialized) {
      // 更新 Store 中的设置（用于兼容性）
      store.put(StoreKey.allowSelfSignedSSLCert, newValue);
    }

    // 应用配置（但实际应该使用 AppConfig 的配置）
    await applyWithConfig(allowSelfSigned: newValue, applyNative: true);
  }

  /// 内部配置逻辑
  static Future<void> _apply({
    required bool allowSelfSigned,
    required bool applyNative,
  }) async {
    // 获取服务器主机（从 AppConfig 读取）
    String? serverHost;
    try {
      final endpoint = ApiConfig.apiEndpoint;
      final uri = Uri.parse(endpoint);
      serverHost = uri.host;
    } catch (e) {
      debugPrint('Failed to parse server endpoint from AppConfig: $e');
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

