// lib/providers/permission/notification_permission_provider.dart

import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_permission_provider.g.dart';

/// 通知权限状态管理器
@riverpod
class NotificationPermissionNotifier extends _$NotificationPermissionNotifier {
  @override
  Future<PermissionStatus> build() async {
    // 初始化时检查当前权限状态
    // Android 13 以下不需要通知权限，直接返回 granted
    if (Platform.isAndroid) {
      // Android 13 (API 33) 及以上需要通知权限
      // 对于 Android 12 及以下，通知权限默认授予
      return await _getNotificationPermissionStatus();
    } else {
      // iOS 需要检查通知权限
      return await _getNotificationPermissionStatus();
    }
  }

  /// 获取通知权限状态
  Future<PermissionStatus> _getNotificationPermissionStatus() async {
    try {
      final status = await Permission.notification.status;
      return status;
    } catch (e) {
      // 如果获取失败，默认返回 denied
      return PermissionStatus.denied;
    }
  }

  /// 请求通知权限
  /// 
  /// **注意**：
  /// - Android 13 以下不需要请求，直接返回 granted
  /// - iOS 需要用户授权
  Future<PermissionStatus> requestPermission() async {
    state = const AsyncValue.loading();

    try {
      PermissionStatus result;
      
      if (Platform.isAndroid) {
        // Android 13 (API 33) 及以上需要请求通知权限
        // permission_handler 会自动处理版本差异
        result = await Permission.notification.request();
      } else {
        // iOS 请求通知权限
        result = await Permission.notification.request();
      }

      state = AsyncValue.data(result);
      return result;
    } catch (e) {
      final deniedStatus = PermissionStatus.denied;
      state = AsyncValue.data(deniedStatus);
      return deniedStatus;
    }
  }

  /// 检查是否有通知权限
  Future<bool> hasPermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 13 以下默认有权限
        // permission_handler 会自动处理版本差异
        return await Permission.notification.isGranted;
      } else {
        return await Permission.notification.isGranted;
      }
    } catch (e) {
      return false;
    }
  }

  /// 检查权限状态并请求（如果没有权限）
  /// 
  /// **返回**：是否有权限
  Future<bool> hasOrRequestPermission() async {
    final hasPermission = await this.hasPermission();
    if (hasPermission) {
      return true;
    }
    
    final status = await requestPermission();
    return status.isGranted;
  }
}

