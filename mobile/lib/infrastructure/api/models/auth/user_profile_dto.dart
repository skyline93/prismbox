// lib/infrastructure/api/models/auth/user_profile_dto.dart

import 'package:json_annotation/json_annotation.dart';

part 'user_profile_dto.g.dart';

/// 用户资料 DTO
@JsonSerializable()
class UserProfileDto {
  final int id;
  final String username;
  final String email;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  UserProfileDto({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.createdAt,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) =>
      _$UserProfileDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}

