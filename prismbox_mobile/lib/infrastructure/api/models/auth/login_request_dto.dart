// lib/infrastructure/api/models/auth/login_request_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'login_request_dto.g.dart';

/// 登录请求 DTO
@JsonSerializable()
class LoginRequestDto {
  final String email;
  final String password;

  LoginRequestDto({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);
}

