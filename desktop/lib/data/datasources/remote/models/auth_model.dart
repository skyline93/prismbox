// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_model.freezed.dart';
part 'auth_model.g.dart';

@freezed
class UserLoginInput with _$UserLoginInput {
  const factory UserLoginInput({
    required String username,
    required String password,
  }) = _UserLoginInput;

  factory UserLoginInput.fromJson(Map<String, dynamic> json) =>
      _$UserLoginInputFromJson(json);
}

@freezed
class UserRegisterInput with _$UserRegisterInput {
  const factory UserRegisterInput({
    required String username,
    required String email,
    required String password,
  }) = _UserRegisterInput;

  factory UserRegisterInput.fromJson(Map<String, dynamic> json) =>
      _$UserRegisterInputFromJson(json);
}

@freezed
class RefreshTokenInput with _$RefreshTokenInput {
  const factory RefreshTokenInput({
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _RefreshTokenInput;

  factory RefreshTokenInput.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenInputFromJson(json);
}

// --- 响应体Data部分 ---

@freezed
class UserLoginSuccessData with _$UserLoginSuccessData {
  const factory UserLoginSuccessData({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _UserLoginSuccessData;

  factory UserLoginSuccessData.fromJson(Map<String, dynamic> json) =>
      _$UserLoginSuccessDataFromJson(json);
}

@freezed
class UserRegisterSuccessData with _$UserRegisterSuccessData {
  const factory UserRegisterSuccessData({
    @JsonKey(name: 'user_id') required int userId,
    required String username,
  }) = _UserRegisterSuccessData;

  factory UserRegisterSuccessData.fromJson(Map<String, dynamic> json) =>
      _$UserRegisterSuccessDataFromJson(json);
}

@freezed
class RefreshTokenSuccessData with _$RefreshTokenSuccessData {
  const factory RefreshTokenSuccessData({
    @JsonKey(name: 'access_token') required String accessToken,
  }) = _RefreshTokenSuccessData;

  factory RefreshTokenSuccessData.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenSuccessDataFromJson(json);
}

@freezed
class GetProfileSuccessData with _$GetProfileSuccessData {
  const factory GetProfileSuccessData({
    required int id,
    required String username,
    required String email,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _GetProfileSuccessData;

  factory GetProfileSuccessData.fromJson(Map<String, dynamic> json) =>
      _$GetProfileSuccessDataFromJson(json);
}
