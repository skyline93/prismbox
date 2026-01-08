// lib/data/models/group/group_detail.dart

import 'package:prismbox/data/models/group/group_member.dart';

/// 圈子详情数据模型（仅用于 API 响应解析）
class GroupDetail {
  final String uuid;
  final String name;
  final String? description;
  final String? coverMediaUuid;
  final int ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int memberCount;
  final int currentUserId;
  final GroupRole currentUserRole;

  GroupDetail({
    required this.uuid,
    required this.name,
    this.description,
    this.coverMediaUuid,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    required this.memberCount,
    required this.currentUserId,
    required this.currentUserRole,
  });

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverMediaUuid: json['cover_media_uuid'] as String?,
      ownerId: json['owner_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      memberCount: json['member_count'] as int,
      currentUserId: json['current_user_id'] as int,
      currentUserRole: GroupRole.fromString(json['current_user_role'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'name': name,
      'description': description,
      'cover_media_uuid': coverMediaUuid,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'member_count': memberCount,
      'current_user_id': currentUserId,
      'current_user_role': currentUserRole.toJson(),
    };
  }
}

