import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_udid/flutter_udid.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';

/// 设备信息服务
/// 提供设备唯一ID和系统类型信息
class DeviceService {
  static final DeviceService _instance = DeviceService._internal();
  factory DeviceService() => _instance;
  DeviceService._internal();

  final Logger _log = Logger('DeviceService');
  String? _cachedDeviceId;
  String? _cachedPlatformType;

  /// 获取设备唯一ID
  ///
  /// 实现策略：
  /// 1. 优先从本地存储读取已保存的设备ID
  /// 2. 如果存储中没有，调用 FlutterUdid.consistentUdid 生成新的ID
  /// 3. 生成后立即保存到本地存储
  ///
  /// 返回的设备ID在应用卸载重装后保持不变（基于系统级标识符）
  Future<String> getDeviceId() async {
    // 如果内存中有缓存，直接返回
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    try {
      final store = StoreService();
      if (!store.isInitialized) {
        _log.warning('StoreService not initialized, generating new device ID');
        return await _generateAndCacheDeviceId();
      }

      // 尝试从本地存储读取
      final storedDeviceId = store.tryGet<String>(StoreKey.deviceId);
      if (storedDeviceId != null && storedDeviceId.isNotEmpty) {
        _cachedDeviceId = storedDeviceId;
        _log.info(
          'Device ID loaded from storage: ${_cachedDeviceId!.substring(0, 8)}...',
        );
        return _cachedDeviceId!;
      }

      // 存储中没有，生成新的ID
      return await _generateAndCacheDeviceId();
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to get device ID from storage, generating new one',
        e,
        stackTrace,
      );
      // 存储读取失败，尝试生成新的ID
      return await _generateAndCacheDeviceId();
    }
  }

  /// 生成并缓存设备ID
  Future<String> _generateAndCacheDeviceId() async {
    try {
      // 调用 flutter_udid 的 consistentUdid 生成设备ID
      final deviceId = await FlutterUdid.consistentUdid;

      if (deviceId.isEmpty) {
        throw Exception('FlutterUdid.consistentUdid returned empty string');
      }

      _cachedDeviceId = deviceId;
      _log.info('Generated new device ID: ${deviceId.substring(0, 8)}...');

      // 保存到本地存储
      try {
        final store = StoreService();
        if (store.isInitialized) {
          await store.put(StoreKey.deviceId, deviceId);
          _log.info('Device ID saved to storage');
        } else {
          _log.warning('StoreService not initialized, device ID not saved');
        }
      } catch (e) {
        _log.warning('Failed to save device ID to storage: $e');
        // 即使保存失败，也继续使用生成的ID
      }

      return deviceId;
    } catch (e, stackTrace) {
      _log.severe('Failed to generate device ID', e, stackTrace);
      rethrow;
    }
  }

  /// 获取设备系统类型
  ///
  /// 返回格式示例：
  /// - Android: "android-arm64", "android-arm", "android-x64"
  /// - iOS: "ios"
  /// - 其他平台: "unknown"
  Future<String> getPlatformType() async {
    // 如果内存中有缓存，直接返回
    if (_cachedPlatformType != null) {
      return _cachedPlatformType!;
    }

    try {
      String platformType;

      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;

        // 获取架构信息
        final abi = androidInfo.supportedAbis.isNotEmpty
            ? androidInfo.supportedAbis.first
            : 'arm';

        // 标准化架构名称
        String arch;
        if (abi.contains('arm64') || abi.contains('aarch64')) {
          arch = 'arm64';
        } else if (abi.contains('arm')) {
          arch = 'arm';
        } else if (abi.contains('x86_64')) {
          arch = 'x64';
        } else if (abi.contains('x86')) {
          arch = 'x86';
        } else {
          arch = abi.toLowerCase();
        }

        platformType = 'android-$arch';
      } else if (Platform.isIOS) {
        platformType = 'ios';
      } else {
        platformType = 'unknown';
        _log.warning('Unknown platform: ${Platform.operatingSystem}');
      }

      _cachedPlatformType = platformType;
      _log.info('Platform type: $platformType');
      return platformType;
    } catch (e, stackTrace) {
      _log.severe('Failed to get platform type', e, stackTrace);
      // 发生错误时返回默认值
      if (Platform.isAndroid) {
        _cachedPlatformType = 'android-arm64';
        return 'android-arm64';
      } else if (Platform.isIOS) {
        _cachedPlatformType = 'ios';
        return 'ios';
      } else {
        _cachedPlatformType = 'unknown';
        return 'unknown';
      }
    }
  }

  /// 同步获取设备系统类型（使用缓存）
  ///
  /// 注意：如果之前没有调用过 getPlatformType()，此方法可能返回 null
  String? getPlatformTypeSync() {
    return _cachedPlatformType;
  }

  /// 同步获取设备ID（使用缓存）
  ///
  /// 注意：如果之前没有调用过 getDeviceId()，此方法可能返回 null
  String? getDeviceIdSync() {
    return _cachedDeviceId;
  }

  /// 清除缓存（用于测试或重置场景）
  void clearCache() {
    _cachedDeviceId = null;
    _cachedPlatformType = null;
    _log.info('Device service cache cleared');
  }
}
