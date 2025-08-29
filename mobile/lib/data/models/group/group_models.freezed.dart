// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GroupModel _$GroupModelFromJson(Map<String, dynamic> json) {
  return _GroupModel.fromJson(json);
}

/// @nodoc
mixin _$GroupModel {
  String get uuid => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'cover_media_uuid')
  String? get coverMediaUuid => throw _privateConstructorUsedError;
  @JsonKey(name: 'owner_id')
  int get ownerId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError; // 聚合信息
  int? get memberCount => throw _privateConstructorUsedError; // === M4 新增字段 ===
// 这部分信息需要后端在 GET /groups/{uuid} 接口中针对当前请求者动态添加
  /// 当前登录用户在此圈子中的 User ID
  @JsonKey(name: 'current_user_id')
  int? get currentUserId => throw _privateConstructorUsedError;

  /// 当前登录用户在此圈子中的角色
  @JsonKey(name: 'current_user_role')
  GroupRole? get currentUserRole => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupModelCopyWith<GroupModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupModelCopyWith<$Res> {
  factory $GroupModelCopyWith(
          GroupModel value, $Res Function(GroupModel) then) =
      _$GroupModelCopyWithImpl<$Res, GroupModel>;
  @useResult
  $Res call(
      {String uuid,
      String name,
      String? description,
      @JsonKey(name: 'cover_media_uuid') String? coverMediaUuid,
      @JsonKey(name: 'owner_id') int ownerId,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      int? memberCount,
      @JsonKey(name: 'current_user_id') int? currentUserId,
      @JsonKey(name: 'current_user_role') GroupRole? currentUserRole});
}

/// @nodoc
class _$GroupModelCopyWithImpl<$Res, $Val extends GroupModel>
    implements $GroupModelCopyWith<$Res> {
  _$GroupModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = null,
    Object? name = null,
    Object? description = freezed,
    Object? coverMediaUuid = freezed,
    Object? ownerId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? memberCount = freezed,
    Object? currentUserId = freezed,
    Object? currentUserRole = freezed,
  }) {
    return _then(_value.copyWith(
      uuid: null == uuid
          ? _value.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      coverMediaUuid: freezed == coverMediaUuid
          ? _value.coverMediaUuid
          : coverMediaUuid // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      memberCount: freezed == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int?,
      currentUserId: freezed == currentUserId
          ? _value.currentUserId
          : currentUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      currentUserRole: freezed == currentUserRole
          ? _value.currentUserRole
          : currentUserRole // ignore: cast_nullable_to_non_nullable
              as GroupRole?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupModelImplCopyWith<$Res>
    implements $GroupModelCopyWith<$Res> {
  factory _$$GroupModelImplCopyWith(
          _$GroupModelImpl value, $Res Function(_$GroupModelImpl) then) =
      __$$GroupModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uuid,
      String name,
      String? description,
      @JsonKey(name: 'cover_media_uuid') String? coverMediaUuid,
      @JsonKey(name: 'owner_id') int ownerId,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      int? memberCount,
      @JsonKey(name: 'current_user_id') int? currentUserId,
      @JsonKey(name: 'current_user_role') GroupRole? currentUserRole});
}

/// @nodoc
class __$$GroupModelImplCopyWithImpl<$Res>
    extends _$GroupModelCopyWithImpl<$Res, _$GroupModelImpl>
    implements _$$GroupModelImplCopyWith<$Res> {
  __$$GroupModelImplCopyWithImpl(
      _$GroupModelImpl _value, $Res Function(_$GroupModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = null,
    Object? name = null,
    Object? description = freezed,
    Object? coverMediaUuid = freezed,
    Object? ownerId = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? memberCount = freezed,
    Object? currentUserId = freezed,
    Object? currentUserRole = freezed,
  }) {
    return _then(_$GroupModelImpl(
      uuid: null == uuid
          ? _value.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      coverMediaUuid: freezed == coverMediaUuid
          ? _value.coverMediaUuid
          : coverMediaUuid // ignore: cast_nullable_to_non_nullable
              as String?,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      memberCount: freezed == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int?,
      currentUserId: freezed == currentUserId
          ? _value.currentUserId
          : currentUserId // ignore: cast_nullable_to_non_nullable
              as int?,
      currentUserRole: freezed == currentUserRole
          ? _value.currentUserRole
          : currentUserRole // ignore: cast_nullable_to_non_nullable
              as GroupRole?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupModelImpl implements _GroupModel {
  const _$GroupModelImpl(
      {required this.uuid,
      required this.name,
      this.description,
      @JsonKey(name: 'cover_media_uuid') this.coverMediaUuid,
      @JsonKey(name: 'owner_id') required this.ownerId,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      this.memberCount,
      @JsonKey(name: 'current_user_id') this.currentUserId,
      @JsonKey(name: 'current_user_role') this.currentUserRole});

  factory _$GroupModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupModelImplFromJson(json);

  @override
  final String uuid;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'cover_media_uuid')
  final String? coverMediaUuid;
  @override
  @JsonKey(name: 'owner_id')
  final int ownerId;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;
// 聚合信息
  @override
  final int? memberCount;
// === M4 新增字段 ===
// 这部分信息需要后端在 GET /groups/{uuid} 接口中针对当前请求者动态添加
  /// 当前登录用户在此圈子中的 User ID
  @override
  @JsonKey(name: 'current_user_id')
  final int? currentUserId;

  /// 当前登录用户在此圈子中的角色
  @override
  @JsonKey(name: 'current_user_role')
  final GroupRole? currentUserRole;

  @override
  String toString() {
    return 'GroupModel(uuid: $uuid, name: $name, description: $description, coverMediaUuid: $coverMediaUuid, ownerId: $ownerId, createdAt: $createdAt, updatedAt: $updatedAt, memberCount: $memberCount, currentUserId: $currentUserId, currentUserRole: $currentUserRole)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupModelImpl &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.coverMediaUuid, coverMediaUuid) ||
                other.coverMediaUuid == coverMediaUuid) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount) &&
            (identical(other.currentUserId, currentUserId) ||
                other.currentUserId == currentUserId) &&
            (identical(other.currentUserRole, currentUserRole) ||
                other.currentUserRole == currentUserRole));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      uuid,
      name,
      description,
      coverMediaUuid,
      ownerId,
      createdAt,
      updatedAt,
      memberCount,
      currentUserId,
      currentUserRole);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupModelImplCopyWith<_$GroupModelImpl> get copyWith =>
      __$$GroupModelImplCopyWithImpl<_$GroupModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupModelImplToJson(
      this,
    );
  }
}

abstract class _GroupModel implements GroupModel {
  const factory _GroupModel(
      {required final String uuid,
      required final String name,
      final String? description,
      @JsonKey(name: 'cover_media_uuid') final String? coverMediaUuid,
      @JsonKey(name: 'owner_id') required final int ownerId,
      @JsonKey(name: 'created_at') required final String createdAt,
      @JsonKey(name: 'updated_at') required final String updatedAt,
      final int? memberCount,
      @JsonKey(name: 'current_user_id') final int? currentUserId,
      @JsonKey(name: 'current_user_role')
      final GroupRole? currentUserRole}) = _$GroupModelImpl;

  factory _GroupModel.fromJson(Map<String, dynamic> json) =
      _$GroupModelImpl.fromJson;

  @override
  String get uuid;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'cover_media_uuid')
  String? get coverMediaUuid;
  @override
  @JsonKey(name: 'owner_id')
  int get ownerId;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;
  @override // 聚合信息
  int? get memberCount;
  @override // === M4 新增字段 ===
// 这部分信息需要后端在 GET /groups/{uuid} 接口中针对当前请求者动态添加
  /// 当前登录用户在此圈子中的 User ID
  @JsonKey(name: 'current_user_id')
  int? get currentUserId;
  @override

  /// 当前登录用户在此圈子中的角色
  @JsonKey(name: 'current_user_role')
  GroupRole? get currentUserRole;
  @override
  @JsonKey(ignore: true)
  _$$GroupModelImplCopyWith<_$GroupModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupMemberModel _$GroupMemberModelFromJson(Map<String, dynamic> json) {
  return _GroupMemberModel.fromJson(json);
}

/// @nodoc
mixin _$GroupMemberModel {
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;
  GroupRole get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'joined_at')
  String get joinedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupMemberModelCopyWith<GroupMemberModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupMemberModelCopyWith<$Res> {
  factory $GroupMemberModelCopyWith(
          GroupMemberModel value, $Res Function(GroupMemberModel) then) =
      _$GroupMemberModelCopyWithImpl<$Res, GroupMemberModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') int userId,
      String username,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      GroupRole role,
      @JsonKey(name: 'joined_at') String joinedAt});
}

/// @nodoc
class _$GroupMemberModelCopyWithImpl<$Res, $Val extends GroupMemberModel>
    implements $GroupMemberModelCopyWith<$Res> {
  _$GroupMemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? joinedAt = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as GroupRole,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupMemberModelImplCopyWith<$Res>
    implements $GroupMemberModelCopyWith<$Res> {
  factory _$$GroupMemberModelImplCopyWith(_$GroupMemberModelImpl value,
          $Res Function(_$GroupMemberModelImpl) then) =
      __$$GroupMemberModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') int userId,
      String username,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      GroupRole role,
      @JsonKey(name: 'joined_at') String joinedAt});
}

/// @nodoc
class __$$GroupMemberModelImplCopyWithImpl<$Res>
    extends _$GroupMemberModelCopyWithImpl<$Res, _$GroupMemberModelImpl>
    implements _$$GroupMemberModelImplCopyWith<$Res> {
  __$$GroupMemberModelImplCopyWithImpl(_$GroupMemberModelImpl _value,
      $Res Function(_$GroupMemberModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? avatarUrl = freezed,
    Object? role = null,
    Object? joinedAt = null,
  }) {
    return _then(_$GroupMemberModelImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as GroupRole,
      joinedAt: null == joinedAt
          ? _value.joinedAt
          : joinedAt // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupMemberModelImpl implements _GroupMemberModel {
  const _$GroupMemberModelImpl(
      {@JsonKey(name: 'user_id') required this.userId,
      required this.username,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      required this.role,
      @JsonKey(name: 'joined_at') required this.joinedAt});

  factory _$GroupMemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupMemberModelImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  final String username;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @override
  final GroupRole role;
  @override
  @JsonKey(name: 'joined_at')
  final String joinedAt;

  @override
  String toString() {
    return 'GroupMemberModel(userId: $userId, username: $username, avatarUrl: $avatarUrl, role: $role, joinedAt: $joinedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupMemberModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, username, avatarUrl, role, joinedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupMemberModelImplCopyWith<_$GroupMemberModelImpl> get copyWith =>
      __$$GroupMemberModelImplCopyWithImpl<_$GroupMemberModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupMemberModelImplToJson(
      this,
    );
  }
}

abstract class _GroupMemberModel implements GroupMemberModel {
  const factory _GroupMemberModel(
          {@JsonKey(name: 'user_id') required final int userId,
          required final String username,
          @JsonKey(name: 'avatar_url') final String? avatarUrl,
          required final GroupRole role,
          @JsonKey(name: 'joined_at') required final String joinedAt}) =
      _$GroupMemberModelImpl;

  factory _GroupMemberModel.fromJson(Map<String, dynamic> json) =
      _$GroupMemberModelImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  String get username;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  GroupRole get role;
  @override
  @JsonKey(name: 'joined_at')
  String get joinedAt;
  @override
  @JsonKey(ignore: true)
  _$$GroupMemberModelImplCopyWith<_$GroupMemberModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UploaderInfo _$UploaderInfoFromJson(Map<String, dynamic> json) {
  return _UploaderInfo.fromJson(json);
}

/// @nodoc
mixin _$UploaderInfo {
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UploaderInfoCopyWith<UploaderInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UploaderInfoCopyWith<$Res> {
  factory $UploaderInfoCopyWith(
          UploaderInfo value, $Res Function(UploaderInfo) then) =
      _$UploaderInfoCopyWithImpl<$Res, UploaderInfo>;
  @useResult
  $Res call({@JsonKey(name: 'user_id') int userId, String username});
}

/// @nodoc
class _$UploaderInfoCopyWithImpl<$Res, $Val extends UploaderInfo>
    implements $UploaderInfoCopyWith<$Res> {
  _$UploaderInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UploaderInfoImplCopyWith<$Res>
    implements $UploaderInfoCopyWith<$Res> {
  factory _$$UploaderInfoImplCopyWith(
          _$UploaderInfoImpl value, $Res Function(_$UploaderInfoImpl) then) =
      __$$UploaderInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'user_id') int userId, String username});
}

/// @nodoc
class __$$UploaderInfoImplCopyWithImpl<$Res>
    extends _$UploaderInfoCopyWithImpl<$Res, _$UploaderInfoImpl>
    implements _$$UploaderInfoImplCopyWith<$Res> {
  __$$UploaderInfoImplCopyWithImpl(
      _$UploaderInfoImpl _value, $Res Function(_$UploaderInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
  }) {
    return _then(_$UploaderInfoImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UploaderInfoImpl implements _UploaderInfo {
  const _$UploaderInfoImpl(
      {@JsonKey(name: 'user_id') required this.userId, required this.username});

  factory _$UploaderInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$UploaderInfoImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  final String username;

  @override
  String toString() {
    return 'UploaderInfo(userId: $userId, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UploaderInfoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, userId, username);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UploaderInfoImplCopyWith<_$UploaderInfoImpl> get copyWith =>
      __$$UploaderInfoImplCopyWithImpl<_$UploaderInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UploaderInfoImplToJson(
      this,
    );
  }
}

abstract class _UploaderInfo implements UploaderInfo {
  const factory _UploaderInfo(
      {@JsonKey(name: 'user_id') required final int userId,
      required final String username}) = _$UploaderInfoImpl;

  factory _UploaderInfo.fromJson(Map<String, dynamic> json) =
      _$UploaderInfoImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  String get username;
  @override
  @JsonKey(ignore: true)
  _$$UploaderInfoImplCopyWith<_$UploaderInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupMediaModel _$GroupMediaModelFromJson(Map<String, dynamic> json) {
  return _GroupMediaModel.fromJson(json);
}

/// @nodoc
mixin _$GroupMediaModel {
  int get group_media_id => throw _privateConstructorUsedError;
  String? get caption => throw _privateConstructorUsedError;
  @JsonKey(name: 'shared_at')
  String get sharedAt => throw _privateConstructorUsedError;
  UploaderInfo get uploader => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_details')
  MediaResponse get mediaDetails => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupMediaModelCopyWith<GroupMediaModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupMediaModelCopyWith<$Res> {
  factory $GroupMediaModelCopyWith(
          GroupMediaModel value, $Res Function(GroupMediaModel) then) =
      _$GroupMediaModelCopyWithImpl<$Res, GroupMediaModel>;
  @useResult
  $Res call(
      {int group_media_id,
      String? caption,
      @JsonKey(name: 'shared_at') String sharedAt,
      UploaderInfo uploader,
      @JsonKey(name: 'media_details') MediaResponse mediaDetails});

  $UploaderInfoCopyWith<$Res> get uploader;
  $MediaResponseCopyWith<$Res> get mediaDetails;
}

/// @nodoc
class _$GroupMediaModelCopyWithImpl<$Res, $Val extends GroupMediaModel>
    implements $GroupMediaModelCopyWith<$Res> {
  _$GroupMediaModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? group_media_id = null,
    Object? caption = freezed,
    Object? sharedAt = null,
    Object? uploader = null,
    Object? mediaDetails = null,
  }) {
    return _then(_value.copyWith(
      group_media_id: null == group_media_id
          ? _value.group_media_id
          : group_media_id // ignore: cast_nullable_to_non_nullable
              as int,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      sharedAt: null == sharedAt
          ? _value.sharedAt
          : sharedAt // ignore: cast_nullable_to_non_nullable
              as String,
      uploader: null == uploader
          ? _value.uploader
          : uploader // ignore: cast_nullable_to_non_nullable
              as UploaderInfo,
      mediaDetails: null == mediaDetails
          ? _value.mediaDetails
          : mediaDetails // ignore: cast_nullable_to_non_nullable
              as MediaResponse,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UploaderInfoCopyWith<$Res> get uploader {
    return $UploaderInfoCopyWith<$Res>(_value.uploader, (value) {
      return _then(_value.copyWith(uploader: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $MediaResponseCopyWith<$Res> get mediaDetails {
    return $MediaResponseCopyWith<$Res>(_value.mediaDetails, (value) {
      return _then(_value.copyWith(mediaDetails: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GroupMediaModelImplCopyWith<$Res>
    implements $GroupMediaModelCopyWith<$Res> {
  factory _$$GroupMediaModelImplCopyWith(_$GroupMediaModelImpl value,
          $Res Function(_$GroupMediaModelImpl) then) =
      __$$GroupMediaModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int group_media_id,
      String? caption,
      @JsonKey(name: 'shared_at') String sharedAt,
      UploaderInfo uploader,
      @JsonKey(name: 'media_details') MediaResponse mediaDetails});

  @override
  $UploaderInfoCopyWith<$Res> get uploader;
  @override
  $MediaResponseCopyWith<$Res> get mediaDetails;
}

/// @nodoc
class __$$GroupMediaModelImplCopyWithImpl<$Res>
    extends _$GroupMediaModelCopyWithImpl<$Res, _$GroupMediaModelImpl>
    implements _$$GroupMediaModelImplCopyWith<$Res> {
  __$$GroupMediaModelImplCopyWithImpl(
      _$GroupMediaModelImpl _value, $Res Function(_$GroupMediaModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? group_media_id = null,
    Object? caption = freezed,
    Object? sharedAt = null,
    Object? uploader = null,
    Object? mediaDetails = null,
  }) {
    return _then(_$GroupMediaModelImpl(
      group_media_id: null == group_media_id
          ? _value.group_media_id
          : group_media_id // ignore: cast_nullable_to_non_nullable
              as int,
      caption: freezed == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String?,
      sharedAt: null == sharedAt
          ? _value.sharedAt
          : sharedAt // ignore: cast_nullable_to_non_nullable
              as String,
      uploader: null == uploader
          ? _value.uploader
          : uploader // ignore: cast_nullable_to_non_nullable
              as UploaderInfo,
      mediaDetails: null == mediaDetails
          ? _value.mediaDetails
          : mediaDetails // ignore: cast_nullable_to_non_nullable
              as MediaResponse,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupMediaModelImpl implements _GroupMediaModel {
  const _$GroupMediaModelImpl(
      {required this.group_media_id,
      this.caption,
      @JsonKey(name: 'shared_at') required this.sharedAt,
      required this.uploader,
      @JsonKey(name: 'media_details') required this.mediaDetails});

  factory _$GroupMediaModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupMediaModelImplFromJson(json);

  @override
  final int group_media_id;
  @override
  final String? caption;
  @override
  @JsonKey(name: 'shared_at')
  final String sharedAt;
  @override
  final UploaderInfo uploader;
  @override
  @JsonKey(name: 'media_details')
  final MediaResponse mediaDetails;

  @override
  String toString() {
    return 'GroupMediaModel(group_media_id: $group_media_id, caption: $caption, sharedAt: $sharedAt, uploader: $uploader, mediaDetails: $mediaDetails)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupMediaModelImpl &&
            (identical(other.group_media_id, group_media_id) ||
                other.group_media_id == group_media_id) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.sharedAt, sharedAt) ||
                other.sharedAt == sharedAt) &&
            (identical(other.uploader, uploader) ||
                other.uploader == uploader) &&
            (identical(other.mediaDetails, mediaDetails) ||
                other.mediaDetails == mediaDetails));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, group_media_id, caption, sharedAt, uploader, mediaDetails);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupMediaModelImplCopyWith<_$GroupMediaModelImpl> get copyWith =>
      __$$GroupMediaModelImplCopyWithImpl<_$GroupMediaModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupMediaModelImplToJson(
      this,
    );
  }
}

abstract class _GroupMediaModel implements GroupMediaModel {
  const factory _GroupMediaModel(
      {required final int group_media_id,
      final String? caption,
      @JsonKey(name: 'shared_at') required final String sharedAt,
      required final UploaderInfo uploader,
      @JsonKey(name: 'media_details')
      required final MediaResponse mediaDetails}) = _$GroupMediaModelImpl;

  factory _GroupMediaModel.fromJson(Map<String, dynamic> json) =
      _$GroupMediaModelImpl.fromJson;

  @override
  int get group_media_id;
  @override
  String? get caption;
  @override
  @JsonKey(name: 'shared_at')
  String get sharedAt;
  @override
  UploaderInfo get uploader;
  @override
  @JsonKey(name: 'media_details')
  MediaResponse get mediaDetails;
  @override
  @JsonKey(ignore: true)
  _$$GroupMediaModelImplCopyWith<_$GroupMediaModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) {
  return _CommentModel.fromJson(json);
}

/// @nodoc
mixin _$CommentModel {
  int get id => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  UploaderInfo get user => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CommentModelCopyWith<CommentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CommentModelCopyWith<$Res> {
  factory $CommentModelCopyWith(
          CommentModel value, $Res Function(CommentModel) then) =
      _$CommentModelCopyWithImpl<$Res, CommentModel>;
  @useResult
  $Res call(
      {int id,
      String content,
      @JsonKey(name: 'created_at') String createdAt,
      UploaderInfo user});

  $UploaderInfoCopyWith<$Res> get user;
}

/// @nodoc
class _$CommentModelCopyWithImpl<$Res, $Val extends CommentModel>
    implements $CommentModelCopyWith<$Res> {
  _$CommentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
    Object? user = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UploaderInfo,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UploaderInfoCopyWith<$Res> get user {
    return $UploaderInfoCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CommentModelImplCopyWith<$Res>
    implements $CommentModelCopyWith<$Res> {
  factory _$$CommentModelImplCopyWith(
          _$CommentModelImpl value, $Res Function(_$CommentModelImpl) then) =
      __$$CommentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String content,
      @JsonKey(name: 'created_at') String createdAt,
      UploaderInfo user});

  @override
  $UploaderInfoCopyWith<$Res> get user;
}

/// @nodoc
class __$$CommentModelImplCopyWithImpl<$Res>
    extends _$CommentModelCopyWithImpl<$Res, _$CommentModelImpl>
    implements _$$CommentModelImplCopyWith<$Res> {
  __$$CommentModelImplCopyWithImpl(
      _$CommentModelImpl _value, $Res Function(_$CommentModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? createdAt = null,
    Object? user = null,
  }) {
    return _then(_$CommentModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as UploaderInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentModelImpl implements _CommentModel {
  const _$CommentModelImpl(
      {required this.id,
      required this.content,
      @JsonKey(name: 'created_at') required this.createdAt,
      required this.user});

  factory _$CommentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentModelImplFromJson(json);

  @override
  final int id;
  @override
  final String content;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  final UploaderInfo user;

  @override
  String toString() {
    return 'CommentModel(id: $id, content: $content, createdAt: $createdAt, user: $user)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CommentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.user, user) || other.user == user));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, content, createdAt, user);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      __$$CommentModelImplCopyWithImpl<_$CommentModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CommentModelImplToJson(
      this,
    );
  }
}

abstract class _CommentModel implements CommentModel {
  const factory _CommentModel(
      {required final int id,
      required final String content,
      @JsonKey(name: 'created_at') required final String createdAt,
      required final UploaderInfo user}) = _$CommentModelImpl;

  factory _CommentModel.fromJson(Map<String, dynamic> json) =
      _$CommentModelImpl.fromJson;

  @override
  int get id;
  @override
  String get content;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  UploaderInfo get user;
  @override
  @JsonKey(ignore: true)
  _$$CommentModelImplCopyWith<_$CommentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InviteCodeModel _$InviteCodeModelFromJson(Map<String, dynamic> json) {
  return _InviteCodeModel.fromJson(json);
}

/// @nodoc
mixin _$InviteCodeModel {
  String get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'expires_at')
  String? get expiresAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'usage_limit')
  int? get usageLimit => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InviteCodeModelCopyWith<InviteCodeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InviteCodeModelCopyWith<$Res> {
  factory $InviteCodeModelCopyWith(
          InviteCodeModel value, $Res Function(InviteCodeModel) then) =
      _$InviteCodeModelCopyWithImpl<$Res, InviteCodeModel>;
  @useResult
  $Res call(
      {String code,
      @JsonKey(name: 'expires_at') String? expiresAt,
      @JsonKey(name: 'usage_limit') int? usageLimit});
}

/// @nodoc
class _$InviteCodeModelCopyWithImpl<$Res, $Val extends InviteCodeModel>
    implements $InviteCodeModelCopyWith<$Res> {
  _$InviteCodeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? expiresAt = freezed,
    Object? usageLimit = freezed,
  }) {
    return _then(_value.copyWith(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
      usageLimit: freezed == usageLimit
          ? _value.usageLimit
          : usageLimit // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InviteCodeModelImplCopyWith<$Res>
    implements $InviteCodeModelCopyWith<$Res> {
  factory _$$InviteCodeModelImplCopyWith(_$InviteCodeModelImpl value,
          $Res Function(_$InviteCodeModelImpl) then) =
      __$$InviteCodeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String code,
      @JsonKey(name: 'expires_at') String? expiresAt,
      @JsonKey(name: 'usage_limit') int? usageLimit});
}

/// @nodoc
class __$$InviteCodeModelImplCopyWithImpl<$Res>
    extends _$InviteCodeModelCopyWithImpl<$Res, _$InviteCodeModelImpl>
    implements _$$InviteCodeModelImplCopyWith<$Res> {
  __$$InviteCodeModelImplCopyWithImpl(
      _$InviteCodeModelImpl _value, $Res Function(_$InviteCodeModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? code = null,
    Object? expiresAt = freezed,
    Object? usageLimit = freezed,
  }) {
    return _then(_$InviteCodeModelImpl(
      code: null == code
          ? _value.code
          : code // ignore: cast_nullable_to_non_nullable
              as String,
      expiresAt: freezed == expiresAt
          ? _value.expiresAt
          : expiresAt // ignore: cast_nullable_to_non_nullable
              as String?,
      usageLimit: freezed == usageLimit
          ? _value.usageLimit
          : usageLimit // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InviteCodeModelImpl implements _InviteCodeModel {
  const _$InviteCodeModelImpl(
      {required this.code,
      @JsonKey(name: 'expires_at') this.expiresAt,
      @JsonKey(name: 'usage_limit') this.usageLimit});

  factory _$InviteCodeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$InviteCodeModelImplFromJson(json);

  @override
  final String code;
  @override
  @JsonKey(name: 'expires_at')
  final String? expiresAt;
  @override
  @JsonKey(name: 'usage_limit')
  final int? usageLimit;

  @override
  String toString() {
    return 'InviteCodeModel(code: $code, expiresAt: $expiresAt, usageLimit: $usageLimit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InviteCodeModelImpl &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.usageLimit, usageLimit) ||
                other.usageLimit == usageLimit));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, code, expiresAt, usageLimit);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InviteCodeModelImplCopyWith<_$InviteCodeModelImpl> get copyWith =>
      __$$InviteCodeModelImplCopyWithImpl<_$InviteCodeModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InviteCodeModelImplToJson(
      this,
    );
  }
}

abstract class _InviteCodeModel implements InviteCodeModel {
  const factory _InviteCodeModel(
          {required final String code,
          @JsonKey(name: 'expires_at') final String? expiresAt,
          @JsonKey(name: 'usage_limit') final int? usageLimit}) =
      _$InviteCodeModelImpl;

  factory _InviteCodeModel.fromJson(Map<String, dynamic> json) =
      _$InviteCodeModelImpl.fromJson;

  @override
  String get code;
  @override
  @JsonKey(name: 'expires_at')
  String? get expiresAt;
  @override
  @JsonKey(name: 'usage_limit')
  int? get usageLimit;
  @override
  @JsonKey(ignore: true)
  _$$InviteCodeModelImplCopyWith<_$InviteCodeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
