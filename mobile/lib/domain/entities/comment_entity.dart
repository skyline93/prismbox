// lib/domain/entities/comment_entity.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/domain/entities/group_feed_item_entity.dart';

part 'comment_entity.freezed.dart';

@freezed
class CommentEntity with _$CommentEntity {
  const factory CommentEntity({
    required String id,
    required FeedAuthorEntity author,
    required String content,
    required DateTime createdAt,
    @Default(0) int likesCount,
    @Default([]) List<CommentEntity> replies,
  }) = _CommentEntity;

  const CommentEntity._();
}
