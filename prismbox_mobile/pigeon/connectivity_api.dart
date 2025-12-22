// pigeon/connectivity_api.dart

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/platform/connectivity_api.g.dart',
    swiftOut: 'ios/Runner/Connectivity/Connectivity.g.swift',
    swiftOptions: SwiftOptions(includeErrorClass: false),
    kotlinOut: 'android/app/src/main/kotlin/app/prismbox/connectivity/Connectivity.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'app.prismbox.connectivity',
      includeErrorClass: true,
    ),
    dartOptions: DartOptions(),
    dartPackageName: 'prismbox',
  ),
)

/// 网络能力枚举
enum NetworkCapability {
  /// WiFi 连接
  wifi,
  
  /// 移动数据连接
  cellular,
  
  /// VPN 连接
  vpn,
  
  /// 无流量限制的网络（通常是 WiFi）
  unmetered,
}

/// 网络连接信息
class NetworkInfo {
  /// 是否有网络连接
  final bool isConnected;
  
  /// 网络能力列表
  final List<NetworkCapability> capabilities;
  
  const NetworkInfo({
    required this.isConnected,
    required this.capabilities,
  });
}

/// 网络连接检查 API
/// 从 Flutter 调用原生平台的网络检查功能
@HostApi()
abstract class ConnectivityApi {
  /// 获取当前网络连接信息
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  NetworkInfo getNetworkInfo();
  
  /// 检查是否连接 WiFi
  /// 
  /// **返回值**：
  /// - `true`：已连接 WiFi
  /// - `false`：未连接 WiFi 或无法确定
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool isWifiConnected();
  
  /// 检查是否有网络连接
  /// 
  /// **返回值**：
  /// - `true`：有网络连接
  /// - `false`：无网络连接
  @TaskQueue(type: TaskQueueType.serialBackgroundThread)
  bool hasNetworkConnection();
}

