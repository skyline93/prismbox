/// 应用配置
/// 
/// 包含所有编译时确定的配置项，如服务器地址等
/// 修改服务器地址后需要重新编译应用
class AppConfig {
  AppConfig._();

  static const ApiConfig api = ApiConfig();
  static const SslConfig ssl = SslConfig();
}

/// API 配置
class ApiConfig {
  const ApiConfig();

  /// 服务器基础地址
  ///
  /// 修改此值以配置后端服务器地址
  /// 格式：协议://主机[:端口]
  /// 示例：
  /// - https://api.example.com
  /// - http://localhost:8080
  /// - https://47.107.63.140
  static const String serverBaseUrl = 'http://47.107.63.140';
  // static const String serverBaseUrl = 'http://172.20.10.6';
  // static const String serverBaseUrl = 'http://10.0.2.2';
  // static const String serverBaseUrl = 'http://10.0.2.2:8080';

  /// 获取完整的 API 端点 URL
  /// 
  /// 返回格式：{serverBaseUrl}/api/v1
  static String get apiEndpoint {
    // 确保 URL 格式正确
    String url = serverBaseUrl.trim();
    
    // 移除末尾的斜杠
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    
    // 拼接 API 路径
    return url;
  }

  /// 获取服务器基础 URL（不含 /api/v1 路径）
  /// 
  /// 用于端点发现等场景
  static String get serverUrl => serverBaseUrl;
}

/// SSL/TLS 配置
class SslConfig {
  const SslConfig();

  /// 是否允许自签名证书
  /// 
  /// - `true`: 允许自签名证书（用于开发/测试环境）
  /// - `false`: 仅允许受信任的证书（生产环境推荐）
  /// 
  /// 注意：修改此值后需要重新编译应用
  static const bool allowSelfSignedCert = false;

  /// 允许自签名证书的主机列表（可选）
  /// 
  /// 仅当 [allowSelfSignedCert] 为 `true` 时生效
  /// 如果列表为空，则允许所有主机的自签名证书
  /// 如果列表不为空，则仅允许列表中主机的自签名证书
  /// 
  /// 示例：
  /// ```dart
  /// static const List<String> allowedSelfSignedHosts = [
  ///   '127.0.0.1',
  ///   'localhost',
  ///   '47.107.63.140',
  /// ];
  /// ```
  static const List<String> allowedSelfSignedHosts = [
    '127.0.0.1',
    'localhost',
    '10.0.2.2',
  ];
}
