// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserLoginInputImpl _$$UserLoginInputImplFromJson(Map<String, dynamic> json) =>
    _$UserLoginInputImpl(
      username: json['username'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$$UserLoginInputImplToJson(
        _$UserLoginInputImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'password': instance.password,
    };

_$UserRegisterInputImpl _$$UserRegisterInputImplFromJson(
        Map<String, dynamic> json) =>
    _$UserRegisterInputImpl(
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$$UserRegisterInputImplToJson(
        _$UserRegisterInputImpl instance) =>
    <String, dynamic>{
      'username': instance.username,
      'email': instance.email,
      'password': instance.password,
    };

_$RefreshTokenInputImpl _$$RefreshTokenInputImplFromJson(
        Map<String, dynamic> json) =>
    _$RefreshTokenInputImpl(
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$$RefreshTokenInputImplToJson(
        _$RefreshTokenInputImpl instance) =>
    <String, dynamic>{
      'refresh_token': instance.refreshToken,
    };

_$UserLoginSuccessDataImpl _$$UserLoginSuccessDataImplFromJson(
        Map<String, dynamic> json) =>
    _$UserLoginSuccessDataImpl(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
    );

Map<String, dynamic> _$$UserLoginSuccessDataImplToJson(
        _$UserLoginSuccessDataImpl instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
    };

_$UserRegisterSuccessDataImpl _$$UserRegisterSuccessDataImplFromJson(
        Map<String, dynamic> json) =>
    _$UserRegisterSuccessDataImpl(
      userId: (json['user_id'] as num).toInt(),
      username: json['username'] as String,
    );

Map<String, dynamic> _$$UserRegisterSuccessDataImplToJson(
        _$UserRegisterSuccessDataImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
    };

_$RefreshTokenSuccessDataImpl _$$RefreshTokenSuccessDataImplFromJson(
        Map<String, dynamic> json) =>
    _$RefreshTokenSuccessDataImpl(
      accessToken: json['access_token'] as String,
    );

Map<String, dynamic> _$$RefreshTokenSuccessDataImplToJson(
        _$RefreshTokenSuccessDataImpl instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
    };

_$GetProfileSuccessDataImpl _$$GetProfileSuccessDataImplFromJson(
        Map<String, dynamic> json) =>
    _$GetProfileSuccessDataImpl(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$GetProfileSuccessDataImplToJson(
        _$GetProfileSuccessDataImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'email': instance.email,
      'created_at': instance.createdAt.toIso8601String(),
    };
