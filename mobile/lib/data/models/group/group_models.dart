// lib/data/models/group/group_models.dart

// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import '../media/media_model.dart';

part 'group_models.freezed.dart';
part 'group_models.g.dart';

/// 圈子成员角色枚举
enum GroupRole {
  @JsonValue('owner')
  owner,
  @JsonValue('admin')
  admin,
  @JsonValue('member')
  member,
}

/// 圈子基础信息模型
@freezed
class GroupModel with _$GroupModel {
  const factory GroupModel({
    required String uuid,
    required String name,
    String? description,
    @JsonKey(name: 'cover_media_uuid') String? coverMediaUuid,
    @JsonKey(name: 'owner_id') required int ownerId,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    // 聚合信息
    int? memberCount,

    /// 当前登录用户在此圈子中的 User ID
    @JsonKey(name: 'current_user_id') int? currentUserId,

    /// 当前登录用户在此圈子中的角色
    @JsonKey(name: 'current_user_role') GroupRole? currentUserRole,
  }) = _GroupModel;

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);
}

/// 圈子成员信息模型
@freezed
class GroupMemberModel with _$GroupMemberModel {
  const factory GroupMemberModel({
    @JsonKey(name: 'user_id') required int userId,
    required String username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    required GroupRole role,
    @JsonKey(name: 'joined_at') required String joinedAt,
  }) = _GroupMemberModel;

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberModelFromJson(json);
}

@freezed
class AuthorModel with _$AuthorModel {
  const factory AuthorModel({
    @JsonKey(name: 'user_id') required int userId,
    required String username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _AuthorModel;

  factory AuthorModel.fromJson(Map<String, dynamic> json) =>
      _$AuthorModelFromJson(json);
}

@freezed
class GroupPostModel with _$GroupPostModel {
  const factory GroupPostModel({
    required int id,
    required String caption,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required AuthorModel creator,
    required List<MediaResponse> media,
    @JsonKey(name: 'likes_count') required int likesCount,
    @JsonKey(name: 'comments_count') required int commentsCount,
    @JsonKey(name: 'has_liked') bool? hasLiked,
  }) = _GroupPostModel;

  factory GroupPostModel.fromJson(Map<String, dynamic> json) =>
      _$GroupPostModelFromJson(json);
}

/// 评论模型
@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    required int id,
    required String content,
    @JsonKey(name: 'created_at') required String createdAt,
    required AuthorModel user,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}

/// 邀请码模型
@freezed
class InviteCodeModel with _$InviteCodeModel {
  const factory InviteCodeModel({
    required String code,
    @JsonKey(name: 'expires_at') String? expiresAt,
    @JsonKey(name: 'usage_limit') int? usageLimit,
  }) = _InviteCodeModel;

  factory InviteCodeModel.fromJson(Map<String, dynamic> json) =>
      _$InviteCodeModelFromJson(json);
}
