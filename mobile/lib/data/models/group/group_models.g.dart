// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroupModelImpl _$$GroupModelImplFromJson(Map<String, dynamic> json) =>
    _$GroupModelImpl(
      uuid: json['uuid'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      coverMediaUuid: json['cover_media_uuid'] as String?,
      ownerId: (json['owner_id'] as num).toInt(),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      memberCount: (json['memberCount'] as num?)?.toInt(),
      currentUserId: (json['current_user_id'] as num?)?.toInt(),
      currentUserRole:
          $enumDecodeNullable(_$GroupRoleEnumMap, json['current_user_role']),
    );

Map<String, dynamic> _$$GroupModelImplToJson(_$GroupModelImpl instance) =>
    <String, dynamic>{
      'uuid': instance.uuid,
      'name': instance.name,
      'description': instance.description,
      'cover_media_uuid': instance.coverMediaUuid,
      'owner_id': instance.ownerId,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'memberCount': instance.memberCount,
      'current_user_id': instance.currentUserId,
      'current_user_role': _$GroupRoleEnumMap[instance.currentUserRole],
    };

const _$GroupRoleEnumMap = {
  GroupRole.owner: 'owner',
  GroupRole.admin: 'admin',
  GroupRole.member: 'member',
};

_$GroupMemberModelImpl _$$GroupMemberModelImplFromJson(
        Map<String, dynamic> json) =>
    _$GroupMemberModelImpl(
      userId: (json['user_id'] as num).toInt(),
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      role: $enumDecode(_$GroupRoleEnumMap, json['role']),
      joinedAt: json['joined_at'] as String,
    );

Map<String, dynamic> _$$GroupMemberModelImplToJson(
        _$GroupMemberModelImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
      'role': _$GroupRoleEnumMap[instance.role]!,
      'joined_at': instance.joinedAt,
    };

_$AuthorModelImpl _$$AuthorModelImplFromJson(Map<String, dynamic> json) =>
    _$AuthorModelImpl(
      userId: (json['user_id'] as num).toInt(),
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$$AuthorModelImplToJson(_$AuthorModelImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
    };

_$GroupPostModelImpl _$$GroupPostModelImplFromJson(Map<String, dynamic> json) =>
    _$GroupPostModelImpl(
      id: (json['id'] as num).toInt(),
      caption: json['caption'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      creator: AuthorModel.fromJson(json['creator'] as Map<String, dynamic>),
      media: (json['media'] as List<dynamic>)
          .map((e) => MediaResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      likesCount: (json['likes_count'] as num).toInt(),
      commentsCount: (json['comments_count'] as num).toInt(),
      hasLiked: json['has_liked'] as bool?,
    );

Map<String, dynamic> _$$GroupPostModelImplToJson(
        _$GroupPostModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'caption': instance.caption,
      'created_at': instance.createdAt.toIso8601String(),
      'creator': instance.creator,
      'media': instance.media,
      'likes_count': instance.likesCount,
      'comments_count': instance.commentsCount,
      'has_liked': instance.hasLiked,
    };

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    _$CommentModelImpl(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      user: AuthorModel.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CommentModelImplToJson(_$CommentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'created_at': instance.createdAt,
      'user': instance.user,
    };

_$InviteCodeModelImpl _$$InviteCodeModelImplFromJson(
        Map<String, dynamic> json) =>
    _$InviteCodeModelImpl(
      code: json['code'] as String,
      expiresAt: json['expires_at'] as String?,
      usageLimit: (json['usage_limit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$InviteCodeModelImplToJson(
        _$InviteCodeModelImpl instance) =>
    <String, dynamic>{
      'code': instance.code,
      'expires_at': instance.expiresAt,
      'usage_limit': instance.usageLimit,
    };
