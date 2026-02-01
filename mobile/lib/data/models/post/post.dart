// lib/data/models/post/post.dart

import 'package:prismbox/data/models/post/post_media.dart';
import 'package:prismbox/data/models/post/user_simple_info.dart';

/// 帖子数据模型（仅用于 API 响应解析）
class Post {
  final int id;
  final String caption;
  final DateTime createdAt;
  final UserSimpleInfo creator;
  final List<PostMedia> media;
  final int likesCount;
  final int commentsCount;
  /// 所属圈子 UUID（全部 Feed 必带，单圈 Feed 可选）
  final String? groupUuid;
  /// 所属圈子名称（全部 Feed 必带，单圈 Feed 可选）
  final String? groupName;

  Post({
    required this.id,
    required this.caption,
    required this.createdAt,
    required this.creator,
    required this.media,
    required this.likesCount,
    required this.commentsCount,
    this.groupUuid,
    this.groupName,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      caption: json['caption'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      creator: UserSimpleInfo.fromJson(json['creator'] as Map<String, dynamic>),
      media: (json['media'] as List<dynamic>?)
              ?.map((item) => PostMedia.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      groupUuid: json['group_uuid'] as String?,
      groupName: json['group_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'creator': creator.toJson(),
      'media': media.map((m) => m.toJson()).toList(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      if (groupUuid != null) 'group_uuid': groupUuid,
      if (groupName != null) 'group_name': groupName,
    };
  }
}

