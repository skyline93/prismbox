// lib/data/models/group/group_member.dart

/// 圈子成员角色枚举
enum GroupRole {
  owner,
  admin,
  member;

  static GroupRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return GroupRole.owner;
      case 'admin':
        return GroupRole.admin;
      case 'member':
        return GroupRole.member;
      default:
        return GroupRole.member;
    }
  }

  String toJson() {
    switch (this) {
      case GroupRole.owner:
        return 'owner';
      case GroupRole.admin:
        return 'admin';
      case GroupRole.member:
        return 'member';
    }
  }
}

/// 圈子成员数据模型（仅用于 API 响应解析）
class GroupMember {
  final int userId;
  final String username;
  final GroupRole role;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.username,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['user_id'] as int,
      username: json['username'] as String,
      role: GroupRole.fromString(json['role'] as String),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'role': role.toJson(),
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

