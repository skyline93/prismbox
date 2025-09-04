// lib/providers/user_profile_provider.dart

import 'dart:io';
import 'dart:developer'; // 引入 developer 库，使用 log 替代 print

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/core/service_locator.dart';

import 'package:mobile/domain/entities/user_profile_entity.dart';
import 'package:mobile/domain/repositories/user_repository.dart';
import 'package:mobile/providers/providers.dart';
import 'package:mobile/auth/auth_state.dart';

// 这个 provider 定义没有问题
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => getIt<UserRepository>(),
);

/// StateNotifierProvider 用于提供 UserProfileNotifier 的实例
/// 它依赖于 userRepositoryProvider
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfileEntity>((ref) {
      final userRepository = ref.watch(userRepositoryProvider);
      return UserProfileNotifier(ref, userRepository);
    });

/// Notifier 类，封装了所有与用户个人资料相关的业务逻辑
class UserProfileNotifier extends StateNotifier<UserProfileEntity> {
  final Ref _ref;
  final UserRepository _userRepository;
  UserProfileNotifier(this._ref, this._userRepository)
    : super(UserProfileEntity.initial()) {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _ref.listen<AuthState>(
      authNotifierProvider,
      (previous, next) {
        log(
          'Auth state changed from $previous to $next',
          name: 'UserProfileNotifier',
        );
        next.mapOrNull(
          authenticated: (_) => fetchUserProfile(),
          unauthenticated: (_) => state = UserProfileEntity.initial(),
        );
      },
      fireImmediately: true, // 修复“迟到监听者”问题
    );
  }

  Future<void> fetchUserProfile() async {
    try {
      log('开始获取用户信息...', name: 'UserProfileNotifier');
      final userProfile = await _userRepository.getCurrentUser();
      if (mounted) {
        state = userProfile;
        log('用户信息获取成功: ${userProfile.username}', name: 'UserProfileNotifier');
      }
    } catch (e, stackTrace) {
      // 修复“静默错误”问题
      log(
        '获取用户信息失败!',
        error: e,
        stackTrace: stackTrace,
        name: 'UserProfileNotifier',
      );
    }
  }

  /// 上传新头像的完整业务逻辑
  Future<void> uploadNewAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile == null) {
        return;
      }

      final imageFile = File(pickedFile.path);
      final newAvatarUrl = await _userRepository.uploadAvatar(imageFile);

      if (mounted) {
        state = state.copyWith(avatarUrl: newAvatarUrl);
      }
    } catch (e) {
      // [修复 #3] 建议使用日志库替代 print
      // log('上传头像失败: $e', name: 'UserProfileNotifier');
    }
  }

  /// 更新用户名的业务逻辑 (示例)
  Future<void> updateUsername(String newName) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        state = state.copyWith(username: newName);
      }
    } catch (e) {
      // [修复 #3] 建议使用日志库替代 print
      // log('更新用户名失败: $e', name: 'UserProfileNotifier');
    }
  }
}
