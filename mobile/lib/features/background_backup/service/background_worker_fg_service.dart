// lib/features/background_backup/service/background_worker_fg_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/platform/background_worker_api.g.dart';

/// 前台后台工作器服务
/// 
/// 用于在 Flutter 前台应用中调用原生平台的后台任务 API
/// 
/// **职责**：
/// - 启用/禁用后台任务
/// - 配置后台任务参数
/// - 保存通知消息（Android）
/// 
/// **使用方式**：
/// ```dart
/// final service = ref.read(backgroundWorkerFgServiceProvider);
/// await service.enable(notificationTitle: '备份中...');
/// ```
class BackgroundWorkerFgService {
  /// 前台 Host API（Pigeon 生成）
  final BackgroundWorkerFgHostApi _foregroundHostApi;
  
  /// 日志记录器
  final Logger _logger = Logger('BackgroundWorkerFgService');

  /// 构造函数
  /// 
  /// [foregroundHostApi] - Pigeon 生成的前台 API 实例
  /// 如果为 null，将创建默认实例
  BackgroundWorkerFgService({BackgroundWorkerFgHostApi? foregroundHostApi})
      : _foregroundHostApi = foregroundHostApi ?? BackgroundWorkerFgHostApi();

  /// 启用后台任务
  /// 
  /// **参数**：
  /// - [notificationTitle] - 通知标题（Android 使用）
  /// - [immediate] - 是否立即执行（Android 使用）
  /// 
  /// **注意**：
  /// - iOS 版本的 enable 方法会忽略 callbackHandle 和 notificationTitle
  /// - callbackHandle 在当前实现中不使用（设置为 0）
  Future<void> enable({
    String notificationTitle = '后台备份',
    bool immediate = false,
  }) async {
    try {
      _logger.info('Enabling background worker');
      
      // callbackHandle 在当前实现中不使用，设置为 0
      // iOS 会忽略此参数，Android 也可能不需要（取决于实现）
      await _foregroundHostApi.enable(0, notificationTitle, immediate);
      
      _logger.info('Background worker enabled successfully');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to enable background worker',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 禁用后台任务
  /// 
  /// 取消所有已调度的后台任务
  Future<void> disable() async {
    try {
      _logger.info('Disabling background worker');
      
      await _foregroundHostApi.disable();
      
      _logger.info('Background worker disabled successfully');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to disable background worker',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 配置后台任务参数
  /// 
  /// **参数**：
  /// - [requiresCharging] - 是否要求充电时执行
  /// - [requiresBatteryNotLow] - 是否要求电池不低
  /// - [minimumDelaySeconds] - 最小延迟秒数
  /// - [requiresNetworkType] - 是否要求特定网络类型（true=WiFi，false=不限制）
  /// 
  /// **注意**：
  /// - iOS 版本会忽略这些参数（iOS 使用系统调度）
  /// - Android 版本会使用这些参数配置 WorkManager
  Future<void> configure({
    bool requiresCharging = false,
    bool requiresBatteryNotLow = true,
    int minimumDelaySeconds = 300, // 默认 5 分钟
    bool requiresNetworkType = true, // 默认要求 WiFi
  }) async {
    try {
      _logger.info(
        'Configuring background worker: '
        'requiresCharging=$requiresCharging, '
        'requiresBatteryNotLow=$requiresBatteryNotLow, '
        'minimumDelaySeconds=$minimumDelaySeconds, '
        'requiresNetworkType=$requiresNetworkType',
      );
      
      final settings = BackgroundWorkerSettings(
        requiresCharging: requiresCharging,
        requiresBatteryNotLow: requiresBatteryNotLow,
        minimumDelaySeconds: minimumDelaySeconds,
        requiresNetworkType: requiresNetworkType,
      );
      
      await _foregroundHostApi.configure(settings);
      
      _logger.info('Background worker configured successfully');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to configure background worker',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 保存通知消息
  /// 
  /// **参数**：
  /// - [title] - 通知标题
  /// - [body] - 通知内容
  /// 
  /// **注意**：
  /// - 此方法主要用于 Android
  /// - iOS 会忽略此调用（iOS 通知由 Flutter 侧管理）
  Future<void> saveNotificationMessage({
    required String title,
    required String body,
  }) async {
    try {
      _logger.fine('Saving notification message: $title - $body');
      
      await _foregroundHostApi.saveNotificationMessage(title, body);
      
      _logger.fine('Notification message saved successfully');
    } catch (error, stackTrace) {
      _logger.warning(
        'Failed to save notification message (may not be supported on this platform)',
        error,
        stackTrace,
      );
      // 不抛出异常，因为某些平台可能不支持此功能
    }
  }

  /// 启用并配置后台任务
  /// 
  /// **参数**：
  /// - [notificationTitle] - 通知标题
  /// - [immediate] - 是否立即执行
  /// - [requiresCharging] - 是否要求充电时执行
  /// - [requiresBatteryNotLow] - 是否要求电池不低
  /// - [minimumDelaySeconds] - 最小延迟秒数
  /// - [requiresNetworkType] - 是否要求 WiFi
  /// 
  /// **便捷方法**：一次性启用和配置后台任务
  Future<void> enableAndConfigure({
    String notificationTitle = '后台备份',
    bool immediate = false,
    bool requiresCharging = false,
    bool requiresBatteryNotLow = true,
    int minimumDelaySeconds = 300,
    bool requiresNetworkType = true,
  }) async {
    try {
      _logger.info('Enabling and configuring background worker');
      
      // 先配置
      await configure(
        requiresCharging: requiresCharging,
        requiresBatteryNotLow: requiresBatteryNotLow,
        minimumDelaySeconds: minimumDelaySeconds,
        requiresNetworkType: requiresNetworkType,
      );
      
      // 再启用
      await enable(
        notificationTitle: notificationTitle,
        immediate: immediate,
      );
      
      _logger.info('Background worker enabled and configured successfully');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to enable and configure background worker',
        error,
        stackTrace,
      );
      rethrow;
    }
  }
}

