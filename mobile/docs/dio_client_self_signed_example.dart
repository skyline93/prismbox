// 示例：如何在 DioClient 中添加自签名证书支持
// 此文件仅作为参考，不要直接使用

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

// 在 DioClient 构造函数中添加以下代码：

DioClient(this._storage) : dio = Dio(), fileDio = Dio() {
  // ... 现有初始化代码 ...
  
  // ===== 添加自签名证书支持（仅开发环境） =====
  if (kDebugMode) {
    _configureSelfSignedCert(dio);
    _configureSelfSignedCert(fileDio);
  }
  
  // ... 继续现有代码 ...
}

/// 配置 Dio 实例以支持自签名证书
void _configureSelfSignedCert(Dio dioInstance) {
  (dioInstance.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    
    // 允许特定 IP/域名的自签名证书
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // 允许的服务器列表（根据实际情况修改）
      const allowedHosts = [
        '47.107.63.140',
        'api.example.com',
        'localhost',
        '127.0.0.1',
      ];
      
      // 检查是否在允许列表中
      final isAllowed = allowedHosts.contains(host);
      
      if (isAllowed) {
        print('⚠️ 允许自签名证书: $host:$port');
      }
      
      return isAllowed;
    };
    
    return client;
  };
}

// ===== 或者使用环境变量控制 =====

// 1. 创建环境配置
class EnvConfig {
  static const bool allowSelfSignedCert = 
    bool.fromEnvironment('ALLOW_SELF_SIGNED_CERT', defaultValue: false);
  
  static const List<String> allowedSelfSignedHosts = [
    '47.107.63.140',
    'api.example.com',
  ];
}

// 2. 在 DioClient 中使用
DioClient(this._storage) : dio = Dio(), fileDio = Dio() {
  // ... 现有代码 ...
  
  if (EnvConfig.allowSelfSignedCert) {
    _configureSelfSignedCert(dio);
    _configureSelfSignedCert(fileDio);
  }
}

// ===== 构建时启用 =====
// flutter run --dart-define=ALLOW_SELF_SIGNED_CERT=true
// flutter build apk --dart-define=ALLOW_SELF_SIGNED_CERT=true

