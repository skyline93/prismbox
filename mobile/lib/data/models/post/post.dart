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

  Post({
    required this.id,
    required this.caption,
    required this.createdAt,
    required this.creator,
    required this.media,
    required this.likesCount,
    required this.commentsCount,
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
    };
  }
}

