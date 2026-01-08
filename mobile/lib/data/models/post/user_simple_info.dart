// lib/data/models/post/user_simple_info.dart

/// 用户简单信息数据模型（仅用于 API 响应解析）
class UserSimpleInfo {
  final int userId;
  final String username;
  final String? avatarUrl;

  UserSimpleInfo({
    required this.userId,
    required this.username,
    this.avatarUrl,
  });

  factory UserSimpleInfo.fromJson(Map<String, dynamic> json) {
    // 兼容两种格式：
    // 1. Feed 流返回的格式：user_id, avatar_url
    // 2. 创建帖子返回的格式：id, avatar
    final userId = json['user_id'] as int? ?? json['id'] as int?;
    if (userId == null) {
      throw FormatException(
        'UserSimpleInfo.fromJson: missing user_id or id field',
      );
    }
    
    return UserSimpleInfo(
      userId: userId,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String? ?? json['avatar'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }
}

