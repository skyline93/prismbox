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
  int? get memberCount => throw _privateConstructorUsedError;

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
  @override

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

AuthorModel _$AuthorModelFromJson(Map<String, dynamic> json) {
  return _AuthorModel.fromJson(json);
}

/// @nodoc
mixin _$AuthorModel {
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AuthorModelCopyWith<AuthorModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthorModelCopyWith<$Res> {
  factory $AuthorModelCopyWith(
          AuthorModel value, $Res Function(AuthorModel) then) =
      _$AuthorModelCopyWithImpl<$Res, AuthorModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') int userId,
      String username,
      @JsonKey(name: 'avatar_url') String? avatarUrl});
}

/// @nodoc
class _$AuthorModelCopyWithImpl<$Res, $Val extends AuthorModel>
    implements $AuthorModelCopyWith<$Res> {
  _$AuthorModelCopyWithImpl(this._value, this._then);

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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AuthorModelImplCopyWith<$Res>
    implements $AuthorModelCopyWith<$Res> {
  factory _$$AuthorModelImplCopyWith(
          _$AuthorModelImpl value, $Res Function(_$AuthorModelImpl) then) =
      __$$AuthorModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'user_id') int userId,
      String username,
      @JsonKey(name: 'avatar_url') String? avatarUrl});
}

/// @nodoc
class __$$AuthorModelImplCopyWithImpl<$Res>
    extends _$AuthorModelCopyWithImpl<$Res, _$AuthorModelImpl>
    implements _$$AuthorModelImplCopyWith<$Res> {
  __$$AuthorModelImplCopyWithImpl(
      _$AuthorModelImpl _value, $Res Function(_$AuthorModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
    Object? avatarUrl = freezed,
  }) {
    return _then(_$AuthorModelImpl(
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthorModelImpl extends _AuthorModel {
  const _$AuthorModelImpl(
      {@JsonKey(name: 'user_id') required this.userId,
      required this.username,
      @JsonKey(name: 'avatar_url') this.avatarUrl})
      : super._();

  factory _$AuthorModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthorModelImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  final String username;
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  @override
  String toString() {
    return 'AuthorModel(userId: $userId, username: $username, avatarUrl: $avatarUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthorModelImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, userId, username, avatarUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthorModelImplCopyWith<_$AuthorModelImpl> get copyWith =>
      __$$AuthorModelImplCopyWithImpl<_$AuthorModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthorModelImplToJson(
      this,
    );
  }
}

abstract class _AuthorModel extends AuthorModel {
  const factory _AuthorModel(
          {@JsonKey(name: 'user_id') required final int userId,
          required final String username,
          @JsonKey(name: 'avatar_url') final String? avatarUrl}) =
      _$AuthorModelImpl;
  const _AuthorModel._() : super._();

  factory _AuthorModel.fromJson(Map<String, dynamic> json) =
      _$AuthorModelImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  String get username;
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl;
  @override
  @JsonKey(ignore: true)
  _$$AuthorModelImplCopyWith<_$AuthorModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupPostModel _$GroupPostModelFromJson(Map<String, dynamic> json) {
  return _GroupPostModel.fromJson(json);
}

/// @nodoc
mixin _$GroupPostModel {
  int get id => throw _privateConstructorUsedError;
  String get caption => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  AuthorModel get creator => throw _privateConstructorUsedError;
  List<MediaResponse> get media => throw _privateConstructorUsedError;
  @JsonKey(name: 'likes_count')
  int get likesCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'comments_count')
  int get commentsCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_liked')
  bool? get hasLiked => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroupPostModelCopyWith<GroupPostModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupPostModelCopyWith<$Res> {
  factory $GroupPostModelCopyWith(
          GroupPostModel value, $Res Function(GroupPostModel) then) =
      _$GroupPostModelCopyWithImpl<$Res, GroupPostModel>;
  @useResult
  $Res call(
      {int id,
      String caption,
      @JsonKey(name: 'created_at') DateTime createdAt,
      AuthorModel creator,
      List<MediaResponse> media,
      @JsonKey(name: 'likes_count') int likesCount,
      @JsonKey(name: 'comments_count') int commentsCount,
      @JsonKey(name: 'has_liked') bool? hasLiked});

  $AuthorModelCopyWith<$Res> get creator;
}

/// @nodoc
class _$GroupPostModelCopyWithImpl<$Res, $Val extends GroupPostModel>
    implements $GroupPostModelCopyWith<$Res> {
  _$GroupPostModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? caption = null,
    Object? createdAt = null,
    Object? creator = null,
    Object? media = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? hasLiked = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      caption: null == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      creator: null == creator
          ? _value.creator
          : creator // ignore: cast_nullable_to_non_nullable
              as AuthorModel,
      media: null == media
          ? _value.media
          : media // ignore: cast_nullable_to_non_nullable
              as List<MediaResponse>,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      hasLiked: freezed == hasLiked
          ? _value.hasLiked
          : hasLiked // ignore: cast_nullable_to_non_nullable
              as bool?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $AuthorModelCopyWith<$Res> get creator {
    return $AuthorModelCopyWith<$Res>(_value.creator, (value) {
      return _then(_value.copyWith(creator: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$GroupPostModelImplCopyWith<$Res>
    implements $GroupPostModelCopyWith<$Res> {
  factory _$$GroupPostModelImplCopyWith(_$GroupPostModelImpl value,
          $Res Function(_$GroupPostModelImpl) then) =
      __$$GroupPostModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String caption,
      @JsonKey(name: 'created_at') DateTime createdAt,
      AuthorModel creator,
      List<MediaResponse> media,
      @JsonKey(name: 'likes_count') int likesCount,
      @JsonKey(name: 'comments_count') int commentsCount,
      @JsonKey(name: 'has_liked') bool? hasLiked});

  @override
  $AuthorModelCopyWith<$Res> get creator;
}

/// @nodoc
class __$$GroupPostModelImplCopyWithImpl<$Res>
    extends _$GroupPostModelCopyWithImpl<$Res, _$GroupPostModelImpl>
    implements _$$GroupPostModelImplCopyWith<$Res> {
  __$$GroupPostModelImplCopyWithImpl(
      _$GroupPostModelImpl _value, $Res Function(_$GroupPostModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? caption = null,
    Object? createdAt = null,
    Object? creator = null,
    Object? media = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? hasLiked = freezed,
  }) {
    return _then(_$GroupPostModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      caption: null == caption
          ? _value.caption
          : caption // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      creator: null == creator
          ? _value.creator
          : creator // ignore: cast_nullable_to_non_nullable
              as AuthorModel,
      media: null == media
          ? _value._media
          : media // ignore: cast_nullable_to_non_nullable
              as List<MediaResponse>,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      commentsCount: null == commentsCount
          ? _value.commentsCount
          : commentsCount // ignore: cast_nullable_to_non_nullable
              as int,
      hasLiked: freezed == hasLiked
          ? _value.hasLiked
          : hasLiked // ignore: cast_nullable_to_non_nullable
              as bool?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupPostModelImpl implements _GroupPostModel {
  const _$GroupPostModelImpl(
      {required this.id,
      required this.caption,
      @JsonKey(name: 'created_at') required this.createdAt,
      required this.creator,
      required final List<MediaResponse> media,
      @JsonKey(name: 'likes_count') required this.likesCount,
      @JsonKey(name: 'comments_count') required this.commentsCount,
      @JsonKey(name: 'has_liked') this.hasLiked})
      : _media = media;

  factory _$GroupPostModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupPostModelImplFromJson(json);

  @override
  final int id;
  @override
  final String caption;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  final AuthorModel creator;
  final List<MediaResponse> _media;
  @override
  List<MediaResponse> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  @JsonKey(name: 'likes_count')
  final int likesCount;
  @override
  @JsonKey(name: 'comments_count')
  final int commentsCount;
  @override
  @JsonKey(name: 'has_liked')
  final bool? hasLiked;

  @override
  String toString() {
    return 'GroupPostModel(id: $id, caption: $caption, createdAt: $createdAt, creator: $creator, media: $media, likesCount: $likesCount, commentsCount: $commentsCount, hasLiked: $hasLiked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupPostModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.caption, caption) || other.caption == caption) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.creator, creator) || other.creator == creator) &&
            const DeepCollectionEquality().equals(other._media, _media) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount) &&
            (identical(other.hasLiked, hasLiked) ||
                other.hasLiked == hasLiked));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      caption,
      createdAt,
      creator,
      const DeepCollectionEquality().hash(_media),
      likesCount,
      commentsCount,
      hasLiked);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupPostModelImplCopyWith<_$GroupPostModelImpl> get copyWith =>
      __$$GroupPostModelImplCopyWithImpl<_$GroupPostModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupPostModelImplToJson(
      this,
    );
  }
}

abstract class _GroupPostModel implements GroupPostModel {
  const factory _GroupPostModel(
      {required final int id,
      required final String caption,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      required final AuthorModel creator,
      required final List<MediaResponse> media,
      @JsonKey(name: 'likes_count') required final int likesCount,
      @JsonKey(name: 'comments_count') required final int commentsCount,
      @JsonKey(name: 'has_liked') final bool? hasLiked}) = _$GroupPostModelImpl;

  factory _GroupPostModel.fromJson(Map<String, dynamic> json) =
      _$GroupPostModelImpl.fromJson;

  @override
  int get id;
  @override
  String get caption;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  AuthorModel get creator;
  @override
  List<MediaResponse> get media;
  @override
  @JsonKey(name: 'likes_count')
  int get likesCount;
  @override
  @JsonKey(name: 'comments_count')
  int get commentsCount;
  @override
  @JsonKey(name: 'has_liked')
  bool? get hasLiked;
  @override
  @JsonKey(ignore: true)
  _$$GroupPostModelImplCopyWith<_$GroupPostModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CommentModel _$CommentModelFromJson(Map<String, dynamic> json) {
  return _CommentModel.fromJson(json);
}

/// @nodoc
mixin _$CommentModel {
// id 类型改为 String 以支持 UUID
  String get id => throw _privateConstructorUsedError;
  String get content =>
      throw _privateConstructorUsedError; // created_at 类型改为 DateTime
  @JsonKey(name: 'created_at')
  DateTime get createdAt =>
      throw _privateConstructorUsedError; // user 字段重命名为 author
  AuthorModel get author =>
      throw _privateConstructorUsedError; // 新增 likes_count 字段
  @JsonKey(name: 'likes_count', defaultValue: 0)
  int get likesCount =>
      throw _privateConstructorUsedError; // 新增 replies 列表以支持嵌套
  @JsonKey(defaultValue: [])
  List<CommentModel> get replies => throw _privateConstructorUsedError;

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
      {String id,
      String content,
      @JsonKey(name: 'created_at') DateTime createdAt,
      AuthorModel author,
      @JsonKey(name: 'likes_count', defaultValue: 0) int likesCount,
      @JsonKey(defaultValue: []) List<CommentModel> replies});

  $AuthorModelCopyWith<$Res> get author;
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
    Object? author = null,
    Object? likesCount = null,
    Object? replies = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as AuthorModel,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      replies: null == replies
          ? _value.replies
          : replies // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $AuthorModelCopyWith<$Res> get author {
    return $AuthorModelCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
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
      {String id,
      String content,
      @JsonKey(name: 'created_at') DateTime createdAt,
      AuthorModel author,
      @JsonKey(name: 'likes_count', defaultValue: 0) int likesCount,
      @JsonKey(defaultValue: []) List<CommentModel> replies});

  @override
  $AuthorModelCopyWith<$Res> get author;
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
    Object? author = null,
    Object? likesCount = null,
    Object? replies = null,
  }) {
    return _then(_$CommentModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as AuthorModel,
      likesCount: null == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int,
      replies: null == replies
          ? _value._replies
          : replies // ignore: cast_nullable_to_non_nullable
              as List<CommentModel>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CommentModelImpl extends _CommentModel {
  const _$CommentModelImpl(
      {required this.id,
      required this.content,
      @JsonKey(name: 'created_at') required this.createdAt,
      required this.author,
      @JsonKey(name: 'likes_count', defaultValue: 0) required this.likesCount,
      @JsonKey(defaultValue: []) required final List<CommentModel> replies})
      : _replies = replies,
        super._();

  factory _$CommentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$CommentModelImplFromJson(json);

// id 类型改为 String 以支持 UUID
  @override
  final String id;
  @override
  final String content;
// created_at 类型改为 DateTime
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
// user 字段重命名为 author
  @override
  final AuthorModel author;
// 新增 likes_count 字段
  @override
  @JsonKey(name: 'likes_count', defaultValue: 0)
  final int likesCount;
// 新增 replies 列表以支持嵌套
  final List<CommentModel> _replies;
// 新增 replies 列表以支持嵌套
  @override
  @JsonKey(defaultValue: [])
  List<CommentModel> get replies {
    if (_replies is EqualUnmodifiableListView) return _replies;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_replies);
  }

  @override
  String toString() {
    return 'CommentModel(id: $id, content: $content, createdAt: $createdAt, author: $author, likesCount: $likesCount, replies: $replies)';
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
            (identical(other.author, author) || other.author == author) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            const DeepCollectionEquality().equals(other._replies, _replies));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, content, createdAt, author,
      likesCount, const DeepCollectionEquality().hash(_replies));

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

abstract class _CommentModel extends CommentModel {
  const factory _CommentModel(
      {required final String id,
      required final String content,
      @JsonKey(name: 'created_at') required final DateTime createdAt,
      required final AuthorModel author,
      @JsonKey(name: 'likes_count', defaultValue: 0)
      required final int likesCount,
      @JsonKey(defaultValue: [])
      required final List<CommentModel> replies}) = _$CommentModelImpl;
  const _CommentModel._() : super._();

  factory _CommentModel.fromJson(Map<String, dynamic> json) =
      _$CommentModelImpl.fromJson;

  @override // id 类型改为 String 以支持 UUID
  String get id;
  @override
  String get content;
  @override // created_at 类型改为 DateTime
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override // user 字段重命名为 author
  AuthorModel get author;
  @override // 新增 likes_count 字段
  @JsonKey(name: 'likes_count', defaultValue: 0)
  int get likesCount;
  @override // 新增 replies 列表以支持嵌套
  @JsonKey(defaultValue: [])
  List<CommentModel> get replies;
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
