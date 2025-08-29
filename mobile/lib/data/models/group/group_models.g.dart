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

_$UploaderInfoImpl _$$UploaderInfoImplFromJson(Map<String, dynamic> json) =>
    _$UploaderInfoImpl(
      userId: (json['user_id'] as num).toInt(),
      username: json['username'] as String,
    );

Map<String, dynamic> _$$UploaderInfoImplToJson(_$UploaderInfoImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'username': instance.username,
    };

_$GroupMediaModelImpl _$$GroupMediaModelImplFromJson(
        Map<String, dynamic> json) =>
    _$GroupMediaModelImpl(
      group_media_id: (json['group_media_id'] as num).toInt(),
      caption: json['caption'] as String?,
      sharedAt: json['shared_at'] as String,
      uploader: UploaderInfo.fromJson(json['uploader'] as Map<String, dynamic>),
      mediaDetails:
          MediaResponse.fromJson(json['media_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$GroupMediaModelImplToJson(
        _$GroupMediaModelImpl instance) =>
    <String, dynamic>{
      'group_media_id': instance.group_media_id,
      'caption': instance.caption,
      'shared_at': instance.sharedAt,
      'uploader': instance.uploader,
      'media_details': instance.mediaDetails,
    };

_$CommentModelImpl _$$CommentModelImplFromJson(Map<String, dynamic> json) =>
    _$CommentModelImpl(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      user: UploaderInfo.fromJson(json['user'] as Map<String, dynamic>),
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
