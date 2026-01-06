// lib/domain/entities/user_profile.dart

import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/infrastructure/api/models/auth/user_profile_dto.dart';

/// 用户资料（业务实体）
class UserProfile {
  final int id;
  final String username;
  final String email;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.createdAt,
  });

  /// 从 DTO 创建
  factory UserProfile.fromDto(UserProfileDto dto) {
    return UserProfile(
      id: dto.id,
      username: dto.username,
      email: dto.email,
      avatarUrl: dto.avatarUrl,
      createdAt: dto.createdAt != null ? DateTime.parse(dto.createdAt!) : null,
    );
  }

  /// 从 JSON 创建
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// 从数据库实体创建
  factory UserProfile.fromEntity(UserEntityData entity) {
    return UserProfile(
      id: int.parse(entity.id),
      username: entity.name,
      email: entity.email ?? '',
      avatarUrl: entity.avatarUrl,
      createdAt: entity.createdAt,
    );
  }

  /// 转换为数据库实体
  UserEntityData toEntity() {
    return UserEntityData(
      id: id.toString(),
      name: username,
      email: email,
      avatarUrl: avatarUrl,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

