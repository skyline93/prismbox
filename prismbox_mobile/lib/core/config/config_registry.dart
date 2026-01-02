// lib/core/config/config_registry.dart

import 'package:prismbox/core/config/cache_config.dart';
import 'package:prismbox/core/config/network_config.dart';
import 'package:prismbox/core/config/task_config.dart';

/// 配置注册表
///
/// 作为统一访问入口，提供所有运行时系统配置的访问接口。
///
/// **配置架构**：
/// - **编译时配置**：`AppConfig` - 应用构建时确定，修改需重新编译
/// - **运行时系统配置**：`ConfigRegistry` - 应用级常量，通常不暴露给用户
/// - **用户设置**：`AppSetting` - 用户可配置，持久化存储
///
/// **使用示例**：
/// ```dart
/// // 访问网络配置
/// final timeout = ConfigRegistry.network.connectTimeout;
///
/// // 访问任务配置
/// final pollInterval = ConfigRegistry.task.pollInterval;
///
/// // 访问缓存配置
/// final ttl = ConfigRegistry.cache.defaultTtl;
///
/// // 访问同步配置
/// final freshnessThreshold = ConfigRegistry.sync.localFreshnessThreshold;
/// ```
///
/// **扩展性**：
/// - 当前实现为静态配置，使用常量值
/// - 接口设计支持未来添加配置监听和动态更新机制（当前不实现）
class ConfigRegistry {
  ConfigRegistry._(); // 私有构造函数，防止实例化

  /// 网络配置
  ///
  /// 包含网络请求相关的配置，如超时、重试等
  static const NetworkConfig network = NetworkConfig();

  /// 任务配置
  ///
  /// 包含任务执行相关的配置，如上传超时、轮询间隔等
  static const TaskConfig task = TaskConfig();

  /// 缓存配置
  ///
  /// 包含缓存相关的配置，如 TTL、大小限制等
  static const CacheConfig cache = CacheConfig();

  /// 同步配置
  ///
  /// 包含同步功能相关的配置，如阈值、间隔等
  ///
  /// **注意**：SyncConfig 使用静态字段，请直接通过 `SyncConfig` 类访问配置项
  /// 例如：`SyncConfig.localFreshnessThreshold`
}
