// pigeon/background_worker_api.dart

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/background_worker_api.g.dart',
    swiftOut: 'ios/Runner/Background/BackgroundWorker.g.swift',
    swiftOptions: SwiftOptions(includeErrorClass: false),
    kotlinOut: 'android/app/src/main/kotlin/app/prismbox/background/BackgroundWorker.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'app.prismbox.background',
      includeErrorClass: false,
    ),
    dartOptions: DartOptions(),
    dartPackageName: 'prismbox',
  ),
)

/// 后台任务配置设置
class BackgroundWorkerSettings {
  /// 是否要求充电
  final bool requiresCharging;

  /// 是否要求电池不低
  final bool requiresBatteryNotLow;

  /// 最小延迟秒数
  final int minimumDelaySeconds;

  /// 网络类型要求（true表示需要WiFi，false表示不限制）
  final bool requiresNetworkType;

  const BackgroundWorkerSettings({
    required this.requiresCharging,
    required this.requiresBatteryNotLow,
    required this.minimumDelaySeconds,
    required this.requiresNetworkType,
  });
}

/// 前台 API（Foreground API）
/// 从 Flutter 前台应用调用原生平台的 API
@HostApi()
abstract class BackgroundWorkerFgHostApi {
  /// 启用后台任务
  /// [callbackHandle] - Flutter回调函数句柄
  /// [notificationTitle] - 通知标题
  /// [immediate] - 是否立即执行
  void enable(int callbackHandle, String notificationTitle, bool immediate);

  /// 禁用后台任务
  void disable();

  /// 配置任务参数
  void configure(BackgroundWorkerSettings settings);

  /// 保存通知消息
  void saveNotificationMessage(String title, String body);
}

/// 后台 API（Background API）
/// 从后台 Flutter Engine 调用原生平台的 API
@HostApi()
abstract class BackgroundWorkerBgHostApi {
  /// 通知原生层初始化完成
  /// 当后台 Flutter Engine 初始化完成并建立必要的平台通道后调用
  void onInitialized();

  /// 通知原生层任务完成
  /// 当后台任务执行完成后调用
  void onCompleted();

  /// 更新进度
  /// [uploadedCount] - 已上传数量
  /// [totalCount] - 总数量
  /// [currentFileName] - 当前文件名（可选）
  void updateProgress(int uploadedCount, int totalCount, String? currentFileName);
}

/// Flutter API
/// 从原生平台调用 Flutter 的 API
@FlutterApi()
abstract class BackgroundWorkerFlutterApi {
  /// iOS 专用：iOS 后台上传触发
  /// [isRefresh] - 是否为刷新任务（BGAppRefreshTask）
  /// [maxSeconds] - 最大执行时间（秒），BGProcessingTask 使用
  @async
  void onIosUpload(bool isRefresh, int? maxSeconds);

  /// Android 专用：Android 后台上传触发
  @async
  void onAndroidUpload();

  /// 取消任务
  @async
  void cancel();
}

