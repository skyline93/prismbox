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

final userProvider = StateNotifierProvider<UserNotifier, UserProfileEntity>((
  ref,
) {
  final userRepository = ref.watch(userRepositoryProvider);
  return UserNotifier(ref, userRepository);
});

// [NEW] The Notifier for the global userProvider.
class UserNotifier extends StateNotifier<UserProfileEntity> {
  final Ref _ref;
  final UserRepository _userRepository;

  UserNotifier(this._ref, this._userRepository)
    : super(UserProfileEntity.initial()) {
    // Listen to authentication changes to fetch the user data once upon login.
    _ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      next.mapOrNull(
        authenticated: (_) => fetchUser(),
        unauthenticated: (_) => state = UserProfileEntity.initial(),
      );
    }, fireImmediately: true);
  }

  Future<void> fetchUser() async {
    try {
      final userProfile = await _userRepository.getCurrentUser();
      if (mounted) {
        state = userProfile;
      }
    } catch (e) {
      log('Failed to fetch global user: $e', name: 'UserNotifier');
    }
  }
}

final userProfileProvider =
    StateNotifierProvider.autoDispose<UserProfileNotifier, UserProfileEntity>((
      ref,
    ) {
      ref.onDispose(() {
        log(
          'userProfileProvider for Dialog has been disposed.',
          name: 'UserProfileProvider',
        );
      });
      final userRepository = ref.watch(userRepositoryProvider);
      return UserProfileNotifier(ref, userRepository);
    });

class UserProfileNotifier extends StateNotifier<UserProfileEntity> {
  final UserRepository _userRepository;
  final Ref _ref;

  UserProfileNotifier(this._ref, this._userRepository)
    : super(UserProfileEntity.initial()) {
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      log(
        'Fetching fresh user profile for dialog...',
        name: 'UserProfileNotifier',
      );
      final userProfile = await _userRepository.getCurrentUser();
      if (mounted) {
        state = userProfile;
        log(
          'Fresh user profile loaded: ${userProfile.username}',
          name: 'UserProfileNotifier',
        );
      }
    } catch (e, stackTrace) {
      log(
        'Failed to fetch user profile for dialog!',
        error: e,
        stackTrace: stackTrace,
        name: 'UserProfileNotifier',
      );
    }
  }

  // The upload/update logic remains the same, refreshing its own state.
  Future<void> uploadNewAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 200,
      );

      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);
      await _userRepository.uploadAvatar(imageFile);

      // After uploading, refresh this dialog's state with the absolute latest data.
      await fetchUserProfile();

      log(
        'Triggering global user provider refresh...',
        name: 'UserProfileNotifier',
      );
      _ref.read(userProvider.notifier).fetchUser();
    } catch (e, stackTrace) {
      log(
        'Upload avatar failed!',
        error: e,
        stackTrace: stackTrace,
        name: 'UserProfileNotifier',
      );
    }
  }
}
