// lib/core/config/network_config.dart

/// 网络配置
///
/// 统一管理网络请求相关的配置常量，包括超时、重试、连接池等。
///
/// **配置项说明**：
/// - 连接超时：建立连接的最大等待时间
/// - 接收超时：接收数据的最大等待时间
/// - 发送超时：发送数据的最大等待时间
/// - 文件上传超时：文件上传的特殊超时设置（通常更长）
/// - 重试配置：网络错误重试的次数和延迟
/// - 连接池配置：最大连接数和空闲超时
class NetworkConfig {
  const NetworkConfig();

  /// 标准连接超时（60秒）
  ///
  /// **用途**：建立网络连接的最大等待时间
  /// **默认值**：60秒
  /// **调整建议**：根据网络环境调整，移动网络建议30-60秒，WiFi可适当延长
  static const Duration connectTimeout = Duration(seconds: 60);

  /// 标准接收超时（30分钟）
  ///
  /// **用途**：接收响应数据的最大等待时间
  /// **默认值**：30分钟
  /// **调整建议**：对于大数据量请求，可适当延长
  static const Duration receiveTimeout = Duration(minutes: 30);

  /// 标准发送超时（60秒）
  ///
  /// **用途**：发送请求数据的最大等待时间
  /// **默认值**：60秒
  /// **调整建议**：根据请求数据大小调整
  static const Duration sendTimeout = Duration(seconds: 60);

  /// 文件上传连接超时（60秒）
  ///
  /// **用途**：文件上传时的连接超时
  /// **默认值**：60秒
  /// **说明**：与标准连接超时相同，但可独立配置
  static const Duration fileUploadConnectTimeout = Duration(seconds: 60);

  /// 文件上传接收超时（1小时）
  ///
  /// **用途**：文件上传时的接收超时（上传响应）
  /// **默认值**：1小时
  /// **说明**：文件上传可能需要较长时间，因此使用更长的超时
  static const Duration fileUploadReceiveTimeout = Duration(hours: 1);

  /// 文件上传发送超时（1小时）
  ///
  /// **用途**：文件上传时的发送超时（上传数据）
  /// **默认值**：1小时
  /// **说明**：大文件上传需要较长时间，因此使用更长的超时
  static const Duration fileUploadSendTimeout = Duration(hours: 1);

  /// Token刷新连接超时（10秒）
  ///
  /// **用途**：刷新Token时的连接超时
  /// **默认值**：10秒
  /// **说明**：Token刷新应快速完成，使用较短超时
  static const Duration tokenRefreshConnectTimeout = Duration(seconds: 10);

  /// Token刷新接收超时（10秒）
  ///
  /// **用途**：刷新Token时的接收超时
  /// **默认值**：10秒
  /// **说明**：Token刷新应快速完成，使用较短超时
  static const Duration tokenRefreshReceiveTimeout = Duration(seconds: 10);

  /// 最大重试次数（3次）
  ///
  /// **用途**：网络错误时的最大重试次数
  /// **默认值**：3次
  /// **调整建议**：根据业务需求调整，避免过度重试
  static const int maxRetries = 3;

  /// 重试延迟（1秒）
  ///
  /// **用途**：重试之间的基础延迟时间
  /// **默认值**：1秒
  /// **说明**：使用指数退避策略，实际延迟 = 重试延迟 × 重试次数
  static const Duration retryDelay = Duration(seconds: 1);

  /// 端点验证超时（5秒）
  ///
  /// **用途**：验证服务器端点可用性的超时时间
  /// **默认值**：5秒
  /// **说明**：端点验证应快速完成，使用较短超时
  static const Duration endpointValidationTimeout = Duration(seconds: 5);

  /// 每主机最大连接数（16个）
  ///
  /// **用途**：HTTP连接池中每个主机的最大连接数
  /// **默认值**：16个
  /// **调整建议**：根据并发需求调整，过多可能消耗资源
  static const int maxConnectionsPerHost = 16;

  /// 连接池最大连接数（网络优化器使用，6个）
  ///
  /// **用途**：网络优化器的连接池配置
  /// **默认值**：6个
  /// **说明**：用于备份上传等场景的连接池
  static const int networkOptimizerMaxConnections = 6;

  /// 连接池空闲超时（30秒）
  ///
  /// **用途**：连接池中空闲连接的超时时间
  /// **默认值**：30秒
  /// **说明**：超过此时间的空闲连接将被关闭
  static const Duration networkOptimizerIdleTimeout = Duration(seconds: 30);

  /// 批量请求大小（100个）
  ///
  /// **用途**：批量请求合并的最大数量
  /// **默认值**：100个
  /// **说明**：用于网络优化器的批量请求合并
  static const int batchSize = 100;
}
