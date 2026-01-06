// lib/core/config/cache_config.dart

/// 缓存配置
///
/// 统一管理缓存相关的配置常量，包括 TTL、大小限制等。
///
/// **配置项说明**：
/// - TTL：缓存数据的生存时间
/// - 大小限制：缓存的最大大小限制
/// - 清理策略：缓存清理的相关配置
///
/// **注意**：当前实现为静态配置，未来可扩展为支持动态配置
class CacheConfig {
  const CacheConfig();

  /// 默认缓存 TTL（1小时）
  ///
  /// **用途**：缓存数据的默认生存时间
  /// **默认值**：1小时
  /// **调整建议**：根据数据更新频率调整，频繁更新的数据应使用较短TTL
  static const Duration defaultTtl = Duration(hours: 1);

  /// 短期缓存 TTL（5分钟）
  ///
  /// **用途**：短期缓存数据的生存时间
  /// **默认值**：5分钟
  /// **说明**：用于频繁更新的数据，如状态信息
  static const Duration shortTtl = Duration(minutes: 5);

  /// 长期缓存 TTL（24小时）
  ///
  /// **用途**：长期缓存数据的生存时间
  /// **默认值**：24小时
  /// **说明**：用于相对稳定的数据，如配置信息
  static const Duration longTtl = Duration(hours: 24);

  /// 最大缓存大小（100MB）
  ///
  /// **用途**：缓存的最大总大小限制
  /// **默认值**：100MB
  /// **调整建议**：根据设备存储空间调整
  static const int maxCacheSizeBytes = 100 * 1024 * 1024; // 100MB

  /// 单个缓存项最大大小（10MB）
  ///
  /// **用途**：单个缓存项的最大大小限制
  /// **默认值**：10MB
  /// **调整建议**：根据缓存项类型调整
  static const int maxItemSizeBytes = 10 * 1024 * 1024; // 10MB
}
