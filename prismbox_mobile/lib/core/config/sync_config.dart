// lib/core/config/sync_config.dart

/// 同步功能配置
/// 
/// 统一管理同步相关的配置常量，包括阈值、间隔等
class SyncConfig {
  SyncConfig._(); // 私有构造函数，防止实例化

  /// 本地同步数据新鲜度阈值（30秒）
  /// 
  /// **说明**：为了尽可能快地同步本地相册变化，使用较短阈值以确保及时检测
  /// 新增、修改或删除的媒体文件。
  static const Duration localFreshnessThreshold = Duration(seconds: 30);

  /// 远程同步数据新鲜度阈值（1分钟）
  /// 
  /// **说明**：需要及时检测服务器上的新资产（可能由其他设备上传），
  /// 因此使用较短阈值以确保及时同步。
  static const Duration remoteFreshnessThreshold = Duration(minutes: 1);

  /// 远程同步定时轮询间隔（30秒）
  /// 
  /// **说明**：后台定期轮询检查是否有新数据需要同步
  static const Duration remotePollingInterval = Duration(seconds: 30);

  /// 同步启动延迟（2秒）
  /// 
  /// **说明**：应用启动后延迟执行同步，确保页面完全加载
  static const Duration startDelay = Duration(seconds: 2);

  /// 同步触发防抖时间（3秒）
  /// 
  /// **说明**：防止短时间内多次触发同步，避免重复执行
  static const Duration triggerDebounce = Duration(seconds: 3);
}

