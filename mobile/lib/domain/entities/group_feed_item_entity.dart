// lib/domain/entities/group_feed_item_entity.dart

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mobile/data/models/group/group_models.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';

part 'group_feed_item_entity.freezed.dart';

/// Feed流中帖子的作者信息实体
@freezed
class FeedAuthorEntity with _$FeedAuthorEntity {
  const factory FeedAuthorEntity({
    required int userId,
    required String username,
    String? avatarUrl,
  }) = _FeedAuthorEntity;

  /// [改造] 从新的数据模型 [AuthorModel] 转换
  factory FeedAuthorEntity.fromAuthorModel(AuthorModel author) {
    return FeedAuthorEntity(
      userId: author.userId,
      username: author.username,
      avatarUrl: author.avatarUrl,
    );
  }
}

/// 统一的圈子Feed项领域实体
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

  /// [核心改造] 从新的数据模型 [GroupPostModel] 转换
  /// 这个方法现在将一个“帖子”模型（可能包含多张图片）转换为UI层使用的单个Feed项。
  factory GroupFeedItemEntity.fromGroupPostModel(GroupPostModel model) {
    // 将 model.media (List<MediaResponse>) 转换为 List<UnifiedMediaEntity>
    final attachments = model.media
        .map(
          (mediaResponse) => UnifiedMediaEntity.fromRemoteMedia(mediaResponse),
        )
        .toList();

    return GroupFeedItemEntity(
      id: model.id,
      content: model.caption, // caption 现在是帖子的内容
      createdAt: model.createdAt, // createdAt 现在是 DateTime 类型
      // 使用新的 fromAuthorModel 工厂方法
      author: FeedAuthorEntity.fromAuthorModel(model.creator),
      // 关键：mediaAttachments 现在是一个完整的媒体列表
      mediaAttachments: attachments,
      likesCount: model.likesCount,
      commentsCount: model.commentsCount,
    );
  }
}
