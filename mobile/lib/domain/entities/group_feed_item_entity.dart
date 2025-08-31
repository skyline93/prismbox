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

  /// 从数据模型 [UploaderInfo] 转换
  factory FeedAuthorEntity.fromUploaderInfo(UploaderInfo uploaderInfo) {
    return FeedAuthorEntity(
      userId: uploaderInfo.userId,
      username: uploaderInfo.username,
      // 注意: 当前的 UploaderInfo 模型中没有头像信息。
      // 后续可能需要API同步提供或通过其他方式获取。
      avatarUrl: null,
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
    required List<UnifiedMediaEntity> mediaAttachments,
    // 注意: 点赞和评论数在当前的 GroupMediaModel 中不存在。
    // 此处添加是为了UI统一，数据将在后续或通过聚合接口提供。
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
  }) = _GroupFeedItemEntity;

  /// 从数据模型 [GroupMediaModel] 转换
  factory GroupFeedItemEntity.fromGroupMediaModel(GroupMediaModel model) {
    return GroupFeedItemEntity(
      id: model.group_media_id,
      content: model.caption ?? '',
      createdAt: DateTime.parse(model.sharedAt),
      author: FeedAuthorEntity.fromUploaderInfo(model.uploader),
      // 当前 GroupMediaModel 只包含一个媒体项，我们将其转换为列表
      mediaAttachments: [
        UnifiedMediaEntity.fromRemoteMedia(model.mediaDetails),
      ],
      // 暂时默认值为0
      likesCount: 0,
      commentsCount: 0,
    );
  }
}
