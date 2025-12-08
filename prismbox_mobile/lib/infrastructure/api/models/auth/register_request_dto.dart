// lib/infrastructure/api/models/auth/register_request_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'register_request_dto.g.dart';

/// 注册请求 DTO
@JsonSerializable()
class RegisterRequestDto {
  final String username;
  final String email;
  final String password;

  RegisterRequestDto({
    required this.username,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => _$RegisterRequestDtoToJson(this);

  factory RegisterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestDtoFromJson(json);
}

