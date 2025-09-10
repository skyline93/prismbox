// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) {
  return _UserProfileModel.fromJson(json);
}

/// @nodoc
mixin _$UserProfileModel {
// [保留] 原有字段
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError; // [新增] 添加 email 字段
  String get email =>
      throw _privateConstructorUsedError; // [保留] avatarUrl 字段，并确保 @JsonKey 正确
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl =>
      throw _privateConstructorUsedError; // [新增] 添加存储信息的字段，并使用 @JsonKey 映射API响应的 snake_case 命名
  @JsonKey(name: 'used_storage')
  double get usedStorage => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_storage')
  double get totalStorage => throw _privateConstructorUsedError;

  /// Serializes this UserProfileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileModelCopyWith<UserProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileModelCopyWith<$Res> {
  factory $UserProfileModelCopyWith(
          UserProfileModel value, $Res Function(UserProfileModel) then) =
      _$UserProfileModelCopyWithImpl<$Res, UserProfileModel>;
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'used_storage') double usedStorage,
      @JsonKey(name: 'total_storage') double totalStorage});
}

/// @nodoc
class _$UserProfileModelCopyWithImpl<$Res, $Val extends UserProfileModel>
    implements $UserProfileModelCopyWith<$Res> {
  _$UserProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfileModel
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
abstract class _$$UserProfileModelImplCopyWith<$Res>
    implements $UserProfileModelCopyWith<$Res> {
  factory _$$UserProfileModelImplCopyWith(_$UserProfileModelImpl value,
          $Res Function(_$UserProfileModelImpl) then) =
      __$$UserProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      @JsonKey(name: 'avatar_url') String? avatarUrl,
      @JsonKey(name: 'used_storage') double usedStorage,
      @JsonKey(name: 'total_storage') double totalStorage});
}

/// @nodoc
class __$$UserProfileModelImplCopyWithImpl<$Res>
    extends _$UserProfileModelCopyWithImpl<$Res, _$UserProfileModelImpl>
    implements _$$UserProfileModelImplCopyWith<$Res> {
  __$$UserProfileModelImplCopyWithImpl(_$UserProfileModelImpl _value,
      $Res Function(_$UserProfileModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfileModel
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
    return _then(_$UserProfileModelImpl(
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
class _$UserProfileModelImpl extends _UserProfileModel {
  const _$UserProfileModelImpl(
      {required this.id,
      required this.username,
      required this.email,
      @JsonKey(name: 'avatar_url') this.avatarUrl,
      @JsonKey(name: 'used_storage') required this.usedStorage,
      @JsonKey(name: 'total_storage') required this.totalStorage})
      : super._();

  factory _$UserProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileModelImplFromJson(json);

// [保留] 原有字段
  @override
  final int id;
  @override
  final String username;
// [新增] 添加 email 字段
  @override
  final String email;
// [保留] avatarUrl 字段，并确保 @JsonKey 正确
  @override
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
// [新增] 添加存储信息的字段，并使用 @JsonKey 映射API响应的 snake_case 命名
  @override
  @JsonKey(name: 'used_storage')
  final double usedStorage;
  @override
  @JsonKey(name: 'total_storage')
  final double totalStorage;

  @override
  String toString() {
    return 'UserProfileModel(id: $id, username: $username, email: $email, avatarUrl: $avatarUrl, usedStorage: $usedStorage, totalStorage: $totalStorage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileModelImpl &&
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

  /// Create a copy of UserProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileModelImplCopyWith<_$UserProfileModelImpl> get copyWith =>
      __$$UserProfileModelImplCopyWithImpl<_$UserProfileModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileModelImplToJson(
      this,
    );
  }
}

abstract class _UserProfileModel extends UserProfileModel {
  const factory _UserProfileModel(
          {required final int id,
          required final String username,
          required final String email,
          @JsonKey(name: 'avatar_url') final String? avatarUrl,
          @JsonKey(name: 'used_storage') required final double usedStorage,
          @JsonKey(name: 'total_storage') required final double totalStorage}) =
      _$UserProfileModelImpl;
  const _UserProfileModel._() : super._();

  factory _UserProfileModel.fromJson(Map<String, dynamic> json) =
      _$UserProfileModelImpl.fromJson;

// [保留] 原有字段
  @override
  int get id;
  @override
  String get username; // [新增] 添加 email 字段
  @override
  String get email; // [保留] avatarUrl 字段，并确保 @JsonKey 正确
  @override
  @JsonKey(name: 'avatar_url')
  String? get avatarUrl; // [新增] 添加存储信息的字段，并使用 @JsonKey 映射API响应的 snake_case 命名
  @override
  @JsonKey(name: 'used_storage')
  double get usedStorage;
  @override
  @JsonKey(name: 'total_storage')
  double get totalStorage;

  /// Create a copy of UserProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileModelImplCopyWith<_$UserProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
