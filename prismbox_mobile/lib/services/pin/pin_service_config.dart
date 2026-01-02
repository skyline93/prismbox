// lib/services/pin/pin_service_config.dart

/// PIN服务配置
/// 用于配置PIN服务的存储键名前缀、资源类型名称和超时时间
class PinServiceConfig {
  /// 存储键名前缀（如: 'encrypted_space_'）
  final String storageKeyPrefix;

  /// 资源类型名称（如: 'album'），用于日志和错误消息
  final String resourceTypeName;

  /// 默认会话超时时间
  final Duration defaultSessionTimeout;

  PinServiceConfig({
    required this.storageKeyPrefix,
    required this.resourceTypeName,
    Duration? defaultSessionTimeout,
  }) : defaultSessionTimeout =
           defaultSessionTimeout ?? const Duration(minutes: 30);

  /// 验证配置的有效性
  bool get isValid {
    return storageKeyPrefix.isNotEmpty && resourceTypeName.isNotEmpty;
  }
}
