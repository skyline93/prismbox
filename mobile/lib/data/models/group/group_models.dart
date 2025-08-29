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
    // 聚合信息，例如成员数，可以由后端提供
    int? memberCount,
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

/// 上传者信息（用于Feed流）
@freezed
class UploaderInfo with _$UploaderInfo {
  const factory UploaderInfo({
    @JsonKey(name: 'user_id') required int userId,
    required String username,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
  }) = _UploaderInfo;

  factory UploaderInfo.fromJson(Map<String, dynamic> json) =>
      _$UploaderInfoFromJson(json);
}

/// 圈子Feed流中的媒体项模型
@freezed
class GroupMediaModel with _$GroupMediaModel {
  const factory GroupMediaModel({
    // 这是 group_media 表的 id
    required int id,
    String? caption,
    @JsonKey(name: 'shared_at') required String sharedAt,
    required UploaderInfo uploader,
    // 嵌套完整的媒体详情，复用已有的 MediaResponse
    @JsonKey(name: 'media_details') required MediaResponse mediaDetails,
  }) = _GroupMediaModel;

  factory GroupMediaModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMediaModelFromJson(json);
}

/// 评论模型
@freezed
class CommentModel with _$CommentModel {
  const factory CommentModel({
    required int id,
    required String content,
    @JsonKey(name: 'created_at') required String createdAt,
    // 评论发布者的信息
    required UploaderInfo user,
  }) = _CommentModel;

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);
}