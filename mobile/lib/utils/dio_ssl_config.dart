// lib/utils/dio_ssl_config.dart

import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:mobile/config/app_config.dart';

/// Dio SSL/TLS 配置工具类
/// 
/// 提供统一的 SSL 证书配置逻辑，可在多个地方复用
/// 根据 AppConfig 中的 SslConfig 自动配置证书验证策略
class DioSslConfig {
  DioSslConfig._();

  /// 根据 AppConfig 配置 Dio 实例的 SSL/TLS
  /// 
  /// 如果使用自签名证书，会配置 badCertificateCallback
  /// 如果使用受信任证书（Let's Encrypt），使用默认配置，无需特殊处理
  /// 
  /// [dioInstance] 要配置的 Dio 实例
  /// [enableLogging] 是否启用日志输出，默认为 true
  static void configureSsl(Dio dioInstance, {bool enableLogging = true}) {
    if (enableLogging) {
      log('配置 SSL: allowSelfSignedCert=${SslConfig.allowSelfSignedCert}, certificateType=${SslConfig.certificateType}');
      log('允许的自签名主机: ${SslConfig.allowedSelfSignedHosts.join(", ")}');
    }
    
    // 如果使用自签名证书，需要配置 badCertificateCallback
    if (SslConfig.allowSelfSignedCert) {
      if (enableLogging) {
        log('配置自签名证书支持: 设置 badCertificateCallback');
      }
      (dioInstance.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // 检查是否在允许列表中
          final isAllowed = SslConfig.isAllowedSelfSignedHost(host);
          if (enableLogging) {
            if (isAllowed) {
              log('⚠️ 允许自签名证书: $host:$port');
            } else {
              log('❌ 拒绝自签名证书: $host:$port (不在允许列表中)');
            }
          }
          return isAllowed;
        };
        return client;
      };
    } else {
      if (enableLogging) {
        log('使用受信任证书模式: 使用系统默认证书验证');
      }
    }
    // 如果使用受信任证书（Let's Encrypt），使用默认配置，无需特殊处理
    // Dio 的 HttpClient 会自动信任系统信任的证书
  }
}

