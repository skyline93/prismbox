// lib/auth/notifiers/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/auth/auth_model.dart';
import 'auth_state.dart';
import 'package:mobile/providers/providers.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    final token = await _ref
        .read(secureStorageServiceProvider)
        .getAccessToken();

    final authService = _ref.read(authServiceProvider);
    await authService.getProfile();

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
