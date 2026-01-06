// lib/providers/permission/photo_permission_provider.dart

import 'package:photo_manager/photo_manager.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_permission_provider.g.dart';

/// 相册权限状态
sealed class PhotoPermissionState {
  const PhotoPermissionState();
}

/// 已授权
class PhotoPermissionGranted extends PhotoPermissionState {
  const PhotoPermissionGranted();
}

/// 未授权
class PhotoPermissionDenied extends PhotoPermissionState {
  const PhotoPermissionDenied();
}

/// 权限被永久拒绝（需要跳转到系统设置）
class PhotoPermissionPermanentlyDenied extends PhotoPermissionState {
  const PhotoPermissionPermanentlyDenied();
}

/// 权限状态管理器
@riverpod
class PhotoPermissionNotifier extends _$PhotoPermissionNotifier {
  @override
  Future<PhotoPermissionState> build() async {
    // 初始化时检查当前权限状态
    // 如果权限已授予，requestPermissionExtend 不会弹出对话框，直接返回当前状态
    // 如果权限未授予，也不会弹出对话框（只有在用户主动请求时才会弹出）
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      
      if (permission.isAuth) {
        return const PhotoPermissionGranted();
      } else {
        // 检查是否为永久拒绝
        final isPermanentlyDenied =
            !permission.hasAccess && !permission.isLimited;
        
        return isPermanentlyDenied
            ? const PhotoPermissionPermanentlyDenied()
            : const PhotoPermissionDenied();
      }
    } catch (e) {
      // 如果检查失败，默认返回未授权状态
      return const PhotoPermissionDenied();
    }
  }

  /// 请求权限
  Future<PhotoPermissionState> requestPermission() async {
    state = const AsyncValue.loading();

    try {
      final permission = await PhotoManager.requestPermissionExtend();

      PhotoPermissionState newState;
      if (permission.isAuth) {
        newState = const PhotoPermissionGranted();
      } else {
        // 检查是否为永久拒绝
        // 在 Android 上，如果权限被永久拒绝，requestPermissionExtend 会返回特定的状态
        // 通过检查 permission 的 hasAccess 和 isLimited 属性来判断
        final isPermanentlyDenied =
            !permission.hasAccess && !permission.isLimited;

        newState = isPermanentlyDenied
            ? const PhotoPermissionPermanentlyDenied()
            : const PhotoPermissionDenied();
      }

      state = AsyncValue.data(newState);
      return newState;
    } catch (e) {
      final errorState = const PhotoPermissionDenied();
      state = AsyncValue.data(errorState);
      return errorState;
    }
  }
}
