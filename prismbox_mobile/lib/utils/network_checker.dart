// lib/utils/network_checker.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/platform/connectivity_api.g.dart';

/// 网络检查工具
/// 
/// 用于检查当前网络连接类型（WiFi、移动数据等）
/// 使用平台通道实现，提供准确的网络状态检查
class NetworkChecker {
  static final Logger _logger = Logger('NetworkChecker');
  static ConnectivityApi? _api;

  /// 获取 ConnectivityApi 实例
  static ConnectivityApi _getApi() {
    _api ??= ConnectivityApi();
    return _api!;
  }

  /// 检查当前是否连接 WiFi
  /// 
  /// **返回值**：
  /// - `true`：已连接 WiFi
  /// - `false`：未连接 WiFi 或无法确定
  /// 
  /// **注意**：
  /// - 在 Web 平台上，无法准确判断网络类型，返回 `true`（假设为 WiFi）
  /// - 在移动平台上，通过平台通道获取准确的网络状态
  static Future<bool> isWifiConnected() async {
    try {
      if (kIsWeb) {
        // Web 平台无法准确判断网络类型，假设为 WiFi
        return true;
      }

      if (Platform.isAndroid || Platform.isIOS) {
        // 使用平台通道获取准确的网络状态
        final api = _getApi();
        return await api.isWifiConnected();
      }

      // 其他平台（桌面）默认返回 true
      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to check WiFi connection',
        e,
        stackTrace,
      );
      // 出错时返回 true，让后台任务自己处理
      return true;
    }
  }

  /// 检查当前是否有网络连接
  /// 
  /// **返回值**：
  /// - `true`：有网络连接
  /// - `false`：无网络连接
  static Future<bool> hasNetworkConnection() async {
    try {
      if (kIsWeb) {
        // Web 平台总是假设有网络连接
        return true;
      }

      if (Platform.isAndroid || Platform.isIOS) {
        // 使用平台通道获取准确的网络状态
        final api = _getApi();
        return await api.hasNetworkConnection();
      }

      // 其他平台，尝试连接一个可靠的服务器来检查网络连接
      final result = await InternetAddress.lookup('google.com')
          .timeout(
        const Duration(seconds: 3),
        onTimeout: () => [],
      );

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      _logger.fine('No network connection: $e');
      return false;
    }
  }

  /// 获取详细的网络连接信息
  /// 
  /// **返回值**：NetworkInfo 对象，包含连接状态和网络能力列表
  static Future<NetworkInfo> getNetworkInfo() async {
    try {
      if (kIsWeb) {
        // Web 平台返回默认值
        return NetworkInfo(
          isConnected: true,
          capabilities: [NetworkCapability.wifi],
        );
      }

      if (Platform.isAndroid || Platform.isIOS) {
        // 使用平台通道获取详细的网络信息
        final api = _getApi();
        return await api.getNetworkInfo();
      }

      // 其他平台返回默认值
      return NetworkInfo(
        isConnected: true,
        capabilities: [NetworkCapability.wifi],
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to get network info',
        e,
        stackTrace,
      );
      // 出错时返回默认值
      return NetworkInfo(
        isConnected: false,
        capabilities: [],
      );
    }
  }
}

