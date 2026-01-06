// lib/providers/auth/auth_state_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/domain/entities/user_profile.dart';
import 'package:prismbox/providers/services/auth_service_provider.dart';

part 'auth_state_provider.g.dart';

/// 认证状态
sealed class AuthState {
  const AuthState();
}

/// 初始状态
class AuthStateInitial extends AuthState {
  const AuthStateInitial();
}

/// 已认证（包含用户信息）
class AuthStateAuthenticated extends AuthState {
  final UserProfile user;

  const AuthStateAuthenticated(this.user);
}

/// 未认证
class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// 加载中
class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// 错误状态
class AuthStateError extends AuthState {
  final String message;

  const AuthStateError(this.message);
}

/// 认证状态管理器
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    // 初始化：检查登录状态
    state = const AsyncValue.loading();
    await initialize();
    return state.value ?? const AuthStateLoading();
  }

  /// 初始化：检查登录状态
  Future<void> initialize() async {
    state = const AsyncValue.loading();

    try {
      final authService = await ref.read(authServiceProvider.future);
      final isAuthenticated = await authService.isAuthenticated();
      if (isAuthenticated) {
        final profile = await authService.getProfile();
        state = AsyncValue.data(AuthStateAuthenticated(profile));
      } else {
        state = const AsyncValue.data(AuthStateUnauthenticated());
      }
    } catch (e) {
      state = AsyncValue.data(AuthStateError('初始化失败: $e'));
    }
  }

  /// 登录
  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final authService = await ref.read(authServiceProvider.future);
      final result = await authService.login(email, password);
      if (result.isSuccess) {
        state = AsyncValue.data(AuthStateAuthenticated(result.user!));
      } else {
        state = AsyncValue.data(AuthStateError(result.errorMessage ?? '登录失败'));
      }
    } catch (e) {
      state = AsyncValue.data(AuthStateError('登录失败: $e'));
    }
  }

  /// 注册
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final authService = await ref.read(authServiceProvider.future);
      final result = await authService.register(
        username: username,
        email: email,
        password: password,
      );
      if (result.isSuccess) {
        state = AsyncValue.data(AuthStateAuthenticated(result.user!));
      } else {
        state = AsyncValue.data(AuthStateError(result.errorMessage ?? '注册失败'));
      }
    } catch (e) {
      state = AsyncValue.data(AuthStateError('注册失败: $e'));
    }
  }

  /// 登出
  Future<void> logout() async {
    state = const AsyncValue.loading();

    try {
      final authService = await ref.read(authServiceProvider.future);
      await authService.logout();
      state = const AsyncValue.data(AuthStateUnauthenticated());
    } catch (e) {
      state = AsyncValue.data(AuthStateError('登出失败: $e'));
    }
  }
}

