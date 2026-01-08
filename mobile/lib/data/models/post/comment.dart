// lib/data/models/post/comment.dart

import 'package:prismbox/data/models/post/user_simple_info.dart';

/// 评论数据模型（仅用于 API 响应解析）
class Comment {
  final String id;
  final DateTime createdAt;
  final String content;
  final UserSimpleInfo author;
  final int likesCount;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.createdAt,
    required this.content,
    required this.author,
    required this.likesCount,
    required this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      content: json['content'] as String,
      author: UserSimpleInfo.fromJson(json['author'] as Map<String, dynamic>),
      likesCount: json['likes_count'] as int? ?? 0,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((item) => Comment.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'content': content,
      'author': author.toJson(),
      'likes_count': likesCount,
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}

