// lib/infrastructure/api/models/auth/register_response_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'register_response_dto.g.dart';

/// 注册响应 DTO
@JsonSerializable()
class RegisterResponseDto {
  @JsonKey(name: 'user_id')
  final int userId;

  final String username;

  RegisterResponseDto({
    required this.userId,
    required this.username,
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseDtoToJson(this);
}

