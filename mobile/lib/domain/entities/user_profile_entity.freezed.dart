// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfileEntity _$UserProfileEntityFromJson(Map<String, dynamic> json) {
  return _UserProfileEntity.fromJson(json);
}

/// @nodoc
mixin _$UserProfileEntity {
// [合并] 从 UserEntity 中添加了 'id' 字段
  int get id =>
      throw _privateConstructorUsedError; // 保留 UserProfileEntity 的所有字段
  String get username => throw _privateConstructorUsedError;
  String get email =>
      throw _privateConstructorUsedError; // [修改] 将 avatarUrl 改为可空，以处理用户未设置头像的情况
// 这也与原 UserEntity 的定义保持了一致，增加了灵活性
  String? get avatarUrl => throw _privateConstructorUsedError;
  double get usedStorage => throw _privateConstructorUsedError;
  double get totalStorage => throw _privateConstructorUsedError;

  /// Serializes this UserProfileEntity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileEntityCopyWith<UserProfileEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileEntityCopyWith<$Res> {
  factory $UserProfileEntityCopyWith(
          UserProfileEntity value, $Res Function(UserProfileEntity) then) =
      _$UserProfileEntityCopyWithImpl<$Res, UserProfileEntity>;
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      String? avatarUrl,
      double usedStorage,
      double totalStorage});
}

/// @nodoc
class _$UserProfileEntityCopyWithImpl<$Res, $Val extends UserProfileEntity>
    implements $UserProfileEntityCopyWith<$Res> {
  _$UserProfileEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? avatarUrl = freezed,
    Object? usedStorage = null,
    Object? totalStorage = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      usedStorage: null == usedStorage
          ? _value.usedStorage
          : usedStorage // ignore: cast_nullable_to_non_nullable
              as double,
      totalStorage: null == totalStorage
          ? _value.totalStorage
          : totalStorage // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProfileEntityImplCopyWith<$Res>
    implements $UserProfileEntityCopyWith<$Res> {
  factory _$$UserProfileEntityImplCopyWith(_$UserProfileEntityImpl value,
          $Res Function(_$UserProfileEntityImpl) then) =
      __$$UserProfileEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      String? avatarUrl,
      double usedStorage,
      double totalStorage});
}

/// @nodoc
class __$$UserProfileEntityImplCopyWithImpl<$Res>
    extends _$UserProfileEntityCopyWithImpl<$Res, _$UserProfileEntityImpl>
    implements _$$UserProfileEntityImplCopyWith<$Res> {
  __$$UserProfileEntityImplCopyWithImpl(_$UserProfileEntityImpl _value,
      $Res Function(_$UserProfileEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? avatarUrl = freezed,
    Object? usedStorage = null,
    Object? totalStorage = null,
  }) {
    return _then(_$UserProfileEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      usedStorage: null == usedStorage
          ? _value.usedStorage
          : usedStorage // ignore: cast_nullable_to_non_nullable
              as double,
      totalStorage: null == totalStorage
          ? _value.totalStorage
          : totalStorage // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileEntityImpl extends _UserProfileEntity {
  const _$UserProfileEntityImpl(
      {required this.id,
      required this.username,
      required this.email,
      this.avatarUrl,
      required this.usedStorage,
      required this.totalStorage})
      : super._();

  factory _$UserProfileEntityImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileEntityImplFromJson(json);

// [合并] 从 UserEntity 中添加了 'id' 字段
  @override
  final int id;
// 保留 UserProfileEntity 的所有字段
  @override
  final String username;
  @override
  final String email;
// [修改] 将 avatarUrl 改为可空，以处理用户未设置头像的情况
// 这也与原 UserEntity 的定义保持了一致，增加了灵活性
  @override
  final String? avatarUrl;
  @override
  final double usedStorage;
  @override
  final double totalStorage;

  @override
  String toString() {
    return 'UserProfileEntity(id: $id, username: $username, email: $email, avatarUrl: $avatarUrl, usedStorage: $usedStorage, totalStorage: $totalStorage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.usedStorage, usedStorage) ||
                other.usedStorage == usedStorage) &&
            (identical(other.totalStorage, totalStorage) ||
                other.totalStorage == totalStorage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, username, email, avatarUrl, usedStorage, totalStorage);

  /// Create a copy of UserProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileEntityImplCopyWith<_$UserProfileEntityImpl> get copyWith =>
      __$$UserProfileEntityImplCopyWithImpl<_$UserProfileEntityImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileEntityImplToJson(
      this,
    );
  }
}

abstract class _UserProfileEntity extends UserProfileEntity {
  const factory _UserProfileEntity(
      {required final int id,
      required final String username,
      required final String email,
      final String? avatarUrl,
      required final double usedStorage,
      required final double totalStorage}) = _$UserProfileEntityImpl;
  const _UserProfileEntity._() : super._();

  factory _UserProfileEntity.fromJson(Map<String, dynamic> json) =
      _$UserProfileEntityImpl.fromJson;

// [合并] 从 UserEntity 中添加了 'id' 字段
  @override
  int get id; // 保留 UserProfileEntity 的所有字段
  @override
  String get username;
  @override
  String get email; // [修改] 将 avatarUrl 改为可空，以处理用户未设置头像的情况
// 这也与原 UserEntity 的定义保持了一致，增加了灵活性
  @override
  String? get avatarUrl;
  @override
  double get usedStorage;
  @override
  double get totalStorage;

  /// Create a copy of UserProfileEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileEntityImplCopyWith<_$UserProfileEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
