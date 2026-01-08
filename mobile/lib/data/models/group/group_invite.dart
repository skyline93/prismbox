// lib/data/models/group/group_invite.dart

/// 圈子邀请码数据模型（仅用于 API 响应解析）
class GroupInvite {
  final String code;
  final DateTime expiresAt;
  final int? usageLimit;

  GroupInvite({
    required this.code,
    required this.expiresAt,
    this.usageLimit,
  });

  factory GroupInvite.fromJson(Map<String, dynamic> json) {
    return GroupInvite(
      code: json['code'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usageLimit: json['usage_limit'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'expires_at': expiresAt.toIso8601String(),
      'usage_limit': usageLimit,
    };
  }
}

