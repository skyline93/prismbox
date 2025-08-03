// lib/auth/state/auth_state.dart
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  // 初始状态，App刚启动，正在检查本地token
  const factory AuthState.initial() = _Initial;
  // 未认证/已登出
  const factory AuthState.unauthenticated() = _Unauthenticated;
  // 正在进行认证操作（登录、注册）
  const factory AuthState.loading() = _Loading;
  // 已认证
  const factory AuthState.authenticated() = _Authenticated;
  // 发生错误
  const factory AuthState.error(String message) = _Error;
}
