// lib/providers/user_profile_provider.dart

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/user_profile_entity.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/auth/auth_state.dart';

// [升级] 将 Provider 升级为 StateNotifierProvider
// 它现在提供的是 UserProfileNotifier 的实例
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileEntity>((ref) {
      return UserProfileNotifier(ref);
    });

// [新增] UserProfileNotifier 类，我们的业务逻辑核心
class UserProfileNotifier extends StateNotifier<UserProfileEntity> {
  final Ref _ref;

  UserProfileNotifier(this._ref) : super(_getInitialViewModel()) {
    // [修改] 3. 在构造函数中，立即开始监听认证状态
    _setupAuthListener();
  }

  // 私有方法，用于获取初始数据
  static UserProfileEntity _getInitialViewModel() {
    // =======================================================================
    // ** 这里是获取初始数据的地方 **
    // 在真实应用中，你会在这里调用 API 或数据库来加载用户初始信息
    // =======================================================================
    return const UserProfileEntity(
      username: '你的名字',
      email: 'your.email@example.com',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      usedStorage: 12.3,
      totalStorage: 15.0,
    );
  }

  void _setupAuthListener() {
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      // 检查新的认证状态
      next.whenOrNull(
        // 当状态变为 "unauthenticated" (即用户已注销)
        unauthenticated: () {
          // 将当前 Notifier 的状态重置为最原始的初始状态
          state = _getInitialViewModel();
        },
      );
    });
  }

  // --- 公开的业务逻辑方法 ---

  /// 方法1：更新用户名
  Future<void> updateUsername(String newName) async {
    // 可以在这里添加加载状态，例如：
    // state = state.copyWith(isLoading: true);

    try {
      // =======================================================================
      // ** 1. 在这里调用你的 API 或 Repository 来保存新用户名 **
      // await userRepository.updateName(newName);
      // 模拟一个网络延迟
      await Future.delayed(const Duration(seconds: 1));
      // =======================================================================

      // 2. 如果API调用成功，则更新本地状态以刷新UI
      state = state.copyWith(username: newName);
    } catch (e) {
      // 3. 处理错误
      print('更新用户名失败: $e');
      // 可以在这里设置一个错误状态给UI显示
      // state = state.copyWith(error: '更新失败，请重试');
    } finally {
      // state = state.copyWith(isLoading: false);
    }
  }

  /// 方法2：上传新头像
  Future<void> uploadNewAvatar() async {
    try {
      // =======================================================================
      // ** 1. 调用图片选择器让用户选择图片 **
      // final file = await ImagePicker().pickImage(...);

      // ** 2. 上传文件到你的服务器，并获取新的URL **
      // final newAvatarUrl = await storageRepository.uploadFile(file);
      // 模拟一个网络延迟和新的URL
      await Future.delayed(const Duration(seconds: 2));
      final newAvatarUrl =
          'https://i.pravatar.cc/150?img=${DateTime.now().millisecond % 60}';
      // =======================================================================

      // 3. 更新本地状态
      state = state.copyWith(avatarUrl: newAvatarUrl);
    } catch (e) {
      // 4. 处理错误
      print('上传头像失败: $e');
    }
  }
}
