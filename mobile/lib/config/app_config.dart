// lib/config/app_config.dart

import 'package:shared_preferences/shared_preferences.dart';

/// 证书类型枚举
enum CertificateType {
    /// Let's Encrypt 或其他受信任 CA 颁发的证书（生产环境）
    /// 系统自动信任，无需特殊配置
    trusted,

    /// 自签名证书（测试环境）
    /// 需要配置允许的域名/IP 列表
    selfSigned,
  }

class AppConfig {
  AppConfig._();

  static const ApiConfig api = ApiConfig();
  static const SslConfig ssl = SslConfig();
}

class ApiConfig {
  const ApiConfig();

  // 默认服务器地址（生产环境使用 HTTPS）
  // 注意：如果后端启用了 HTTPS，请将地址改为 https://
  // static const String defaultServerAddr = 'https://47.107.63.140';
  // static const String defaultServerAddr = 'https://api.example.com';  // HTTPS 示例
  // static const String defaultServerAddr = 'http://10.0.2.2';  // Android 模拟器
  static const String defaultServerAddr = 'https://127.0.0.1';
  // static const String defaultServerAddr = 'http://10.168.1.161';

  // 支持从本地存储读取自定义服务器地址
  static Future<String> getServerAddr() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customAddr = prefs.getString('server_address');
      return customAddr ?? defaultServerAddr;
    } catch (e) {
      // 如果读取失败，使用默认地址
      return defaultServerAddr;
    }
  }

  // 动态获取 baseUrl
  static Future<String> get baseUrl async {
    final serverAddr = await getServerAddr();
    return '$serverAddr/api/v1';
  }

  // 同步获取 baseUrl（用于不需要异步的场景，使用默认地址）
  static const String baseUrlSync = '$defaultServerAddr/api/v1';
}

/// SSL/TLS 证书配置
/// 
/// 用于配置 HTTPS 连接和证书验证策略
class SslConfig {
  const SslConfig();

  /// 是否启用 HTTPS
  /// 如果为 true，服务器地址应使用 https:// 协议
  static const bool enableHttps = true;

  /// 当前使用的证书类型
  /// 
  /// - [CertificateType.trusted]: 生产环境，使用 Let's Encrypt 等受信任证书
  /// - [CertificateType.selfSigned]: 测试环境，使用自签名证书
  static const CertificateType certificateType = CertificateType.selfSigned;

  /// 允许自签名证书的域名/IP 列表
  /// 
  /// 仅当 [certificateType] 为 [CertificateType.selfSigned] 时生效
  /// 只有列表中的主机才会被允许使用自签名证书
  static const List<String> allowedSelfSignedHosts = [
    '47.107.63.140',
    'localhost',
    '127.0.0.1',
    '10.0.2.2', // Android 模拟器
    // 'api.example.com',  // 添加其他测试域名
  ];

  /// 是否允许自签名证书
  /// 
  /// 当 [certificateType] 为 [CertificateType.selfSigned] 时返回 true
  static bool get allowSelfSignedCert =>
      certificateType == CertificateType.selfSigned;

  /// 检查指定主机是否允许使用自签名证书
  /// 
  /// [host] 要检查的主机名或 IP 地址
  /// 返回 true 如果主机在允许列表中且允许自签名证书
  static bool isAllowedSelfSignedHost(String host) {
    if (!allowSelfSignedCert) {
      return false;
    }
    return allowedSelfSignedHosts.contains(host);
  }

  /// 获取配置摘要（用于调试）
  static String get configSummary {
    return '''
SSL Config:
  - Enable HTTPS: $enableHttps
  - Certificate Type: $certificateType
  - Allow Self-Signed: $allowSelfSignedCert
  - Allowed Hosts: ${allowedSelfSignedHosts.join(', ')}
''';
  }
}
