// lib/core/config/task_config.dart

/// 任务配置
///
/// 统一管理任务执行相关的配置常量，包括上传超时、轮询间隔、检查间隔等。
///
/// **配置项说明**：
/// - 上传超时：单个文件上传的最大等待时间
/// - 轮询间隔：任务状态轮询的间隔时间
/// - 检查间隔：定期检查任务状态的间隔
/// - 刷新间隔：状态刷新的间隔时间
class TaskConfig {
  const TaskConfig();

  /// 任务完成轮询间隔（1秒）
  ///
  /// **用途**：等待任务完成时的轮询间隔
  /// **默认值**：1秒
  /// **调整建议**：根据任务完成速度调整，过短可能增加服务器压力
  static const Duration pollInterval = Duration(seconds: 1);

  /// 任务完成超时（10分钟）
  ///
  /// **用途**：等待任务完成的最大等待时间
  /// **默认值**：10分钟
  /// **调整建议**：根据任务复杂度调整，大文件上传可能需要更长时间
  static const Duration taskCompletionTimeout = Duration(minutes: 10);

  /// 最大上传时长（30分钟）
  ///
  /// **用途**：单个文件上传的最大允许时长，超过此时长将被标记为失败
  /// **默认值**：30分钟
  /// **调整建议**：根据文件大小和网络速度调整
  static const Duration maxUploadingDuration = Duration(minutes: 30);

  /// 任务状态检查间隔（5分钟）
  ///
  /// **用途**：定期检查异常任务状态的间隔时间
  /// **默认值**：5分钟
  /// **调整建议**：根据任务数量和服务器负载调整
  static const Duration statusCheckInterval = Duration(minutes: 5);

  /// 备份状态刷新间隔（1秒）
  ///
  /// **用途**：备份状态刷新的间隔时间
  /// **默认值**：1秒
  /// **调整建议**：根据UI响应需求调整，过短可能增加服务器压力
  static const Duration backupStateRefreshInterval = Duration(seconds: 1);

  /// 最大连续失败次数（3次）
  ///
  /// **用途**：备份状态刷新连续失败的最大次数，超过后停止刷新
  /// **默认值**：3次
  /// **调整建议**：根据网络稳定性调整
  static const int maxConsecutiveFailures = 3;
}
