// lib/utils/device_utils.dart

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
// [阶段三 新增]: 导入网络连接检查插件
import 'package:connectivity_plus/connectivity_plus.dart';

class DeviceUtils {
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = "persistent_device_id";

  /// 获取设备信息（包含持久化 ID）
  static Future<Map<String, String>> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();

    String deviceName = 'Unknown';
    String systemType = 'Unknown';
    String systemVersion = 'Unknown';

    // 获取持久化 ID
    String deviceId = await _getPersistentDeviceId();

    if (kIsWeb) {
      final webInfo = await deviceInfo.webBrowserInfo;
      deviceName = webInfo.userAgent ?? "Web Browser";
      systemType = "Web";
      systemVersion = webInfo.appVersion ?? "Unknown";
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceName = androidInfo.model;
      systemType = "Android";
      systemVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceName = iosInfo.name;
      systemType = "iOS";
      systemVersion = iosInfo.systemVersion;
    } else if (Platform.isMacOS) {
      final macInfo = await deviceInfo.macOsInfo;
      deviceName = macInfo.computerName;
      systemType = "macOS";
      systemVersion = macInfo.osRelease;
    } else if (Platform.isWindows) {
      final winInfo = await deviceInfo.windowsInfo;
      deviceName = winInfo.computerName;
      systemType = "Windows";
      systemVersion = winInfo.productName;
    } else if (Platform.isLinux) {
      final linuxInfo = await deviceInfo.linuxInfo;
      deviceName = linuxInfo.name;
      systemType = "Linux";
      systemVersion = linuxInfo.version!;
    }

    return {
      "deviceName": deviceName,
      "systemType": systemType,
      "systemVersion": systemVersion,
      "deviceId": deviceId,
    };
  }

  /// 获取持久化的设备 ID（首次生成后存储）
  static Future<String> _getPersistentDeviceId() async {
    String? storedId = await _storage.read(key: _deviceIdKey);
    if (storedId != null) {
      return storedId;
    }

    // 第一次运行，生成 UUID
    String newId = const Uuid().v4();
    await _storage.write(key: _deviceIdKey, value: newId);
    return newId;
  }

  // [阶段三 修正]: 修正返回类型以匹配 connectivity_plus 插件
  /// 检查当前的网络状态 (Wi-Fi, 移动数据, 或无连接等)
  ///
  /// 使用 `connectivity_plus` 插件实现。返回一个列表，因为设备可能同时连接到多个网络。
  static Future<List<ConnectivityResult>> checkConnectivity() async {
    // 在 web 平台上，总是返回 wifi，因为无法区分
    if (kIsWeb) return [ConnectivityResult.wifi];
    return Connectivity().checkConnectivity();
  }
}
