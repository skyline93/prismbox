// lib/auth/notifiers/auth_notifier.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../api/models/auth_models.dart';
import '../../core/providers.dart';
import '../../core/storage/secure_storage_service.dart';
import '../state/auth_state.dart';

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    // 启动时可以增加一个验证token有效性的API调用（例如/users/me）
    // 如果失败（401），刷新机制会自动触发
    // 这里我们保持简单，只检查token是否存在
    final token = await _ref
        .read(secureStorageServiceProvider)
        .getAccessToken();
    await Future.delayed(const Duration(seconds: 1));
    if (token != null && token.isNotEmpty) {
      state = const AuthState.authenticated();
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String username, String password) async {
    state = const AuthState.loading();
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.login(
        UserLoginInput(username: username, password: password),
      );
      state = const AuthState.authenticated();
    } catch (e) {
      state = AuthState.error("登录失败: ${e.toString()}");
    }
  }

  void resetToUnauthenticated() {
    state = const AuthState.unauthenticated();
  }

  Future<void> logout() async {
    await _ref.read(authServiceProvider).logout();
    state = const AuthState.unauthenticated();
  }
}
