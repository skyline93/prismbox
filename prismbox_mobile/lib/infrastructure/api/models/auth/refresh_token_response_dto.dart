// lib/infrastructure/api/models/auth/refresh_token_response_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'refresh_token_response_dto.g.dart';

/// 刷新令牌响应 DTO
@JsonSerializable()
class RefreshTokenResponseDto {
  @JsonKey(name: 'access_token')
  final String accessToken;

  RefreshTokenResponseDto({
    required this.accessToken,
  });

  factory RefreshTokenResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RefreshTokenResponseDtoToJson(this);
}

