// lib/domain/entities/group_feed_item_entity.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

part 'group_feed_item_entity.freezed.dart';

@freezed
class FeedAuthorEntity with _$FeedAuthorEntity {
  const factory FeedAuthorEntity({
    required int userId,
    required String username,
    String? avatarUrl,
  }) = _FeedAuthorEntity;

  factory FeedAuthorEntity.fromAuthorModel(AuthorModel author) {
    return FeedAuthorEntity(
      userId: author.userId,
      username: author.username,
      avatarUrl: author.avatarUrl,
    );
  }
}

@freezed
class GroupFeedItemEntity with _$GroupFeedItemEntity {
  const factory GroupFeedItemEntity({
    required int id,
    required String content,
    required DateTime createdAt,
    required FeedAuthorEntity author,
    required List<UnifiedMediaEntity> mediaAttachments, // 这是一个列表
    required int likesCount,
    required int commentsCount,
  }) = _GroupFeedItemEntity;

  factory GroupFeedItemEntity.fromGroupPostModel(GroupPostModel model) {
    final attachments = model.media
        .map(
          (mediaResponse) => UnifiedMediaEntity.fromRemoteMedia(mediaResponse),
        )
        .toList();

    return GroupFeedItemEntity(
      id: model.id,
      content: model.caption, // caption 现在是帖子的内容
      createdAt: model.createdAt, // createdAt 现在是 DateTime 类型
      author: FeedAuthorEntity.fromAuthorModel(model.creator),
      mediaAttachments: attachments,
      likesCount: model.likesCount,
      commentsCount: model.commentsCount,
    );
  }
}
