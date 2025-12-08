// lib/domain/entities/auth_result.dart

import 'package:prismbox/domain/entities/user_profile.dart';

/// 登录结果
sealed class AuthResult {
  const AuthResult();

  bool get isSuccess => this is AuthSuccess;
  bool get isFailure => this is AuthFailure;
  UserProfile? get user => switch (this) {
        AuthSuccess(:final user) => user,
        _ => null,
      };
  String? get errorMessage => switch (this) {
        AuthFailure(:final message) => message,
        _ => null,
      };
}

/// 登录成功
class AuthSuccess extends AuthResult {
  final UserProfile user;

  const AuthSuccess(this.user);
}

/// 登录失败
class AuthFailure extends AuthResult {
  final String message;

  const AuthFailure(this.message);
}

/// 注册结果
sealed class RegisterResult {
  const RegisterResult();

  bool get isSuccess => this is RegisterSuccess;
  bool get isFailure => this is RegisterFailure;
  UserProfile? get user => switch (this) {
        RegisterSuccess(:final user) => user,
        _ => null,
      };
  String? get errorMessage => switch (this) {
        RegisterFailure(:final message) => message,
        _ => null,
      };
}

/// 注册成功
class RegisterSuccess extends RegisterResult {
  final UserProfile user;

  const RegisterSuccess(this.user);
}

/// 注册失败
class RegisterFailure extends RegisterResult {
  final String message;

  const RegisterFailure(this.message);
}

