// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserLoginInput _$UserLoginInputFromJson(Map<String, dynamic> json) {
  return _UserLoginInput.fromJson(json);
}

/// @nodoc
mixin _$UserLoginInput {
  String get username => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;

  /// Serializes this UserLoginInput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserLoginInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserLoginInputCopyWith<UserLoginInput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserLoginInputCopyWith<$Res> {
  factory $UserLoginInputCopyWith(
          UserLoginInput value, $Res Function(UserLoginInput) then) =
      _$UserLoginInputCopyWithImpl<$Res, UserLoginInput>;
  @useResult
  $Res call({String username, String password});
}

/// @nodoc
class _$UserLoginInputCopyWithImpl<$Res, $Val extends UserLoginInput>
    implements $UserLoginInputCopyWith<$Res> {
  _$UserLoginInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserLoginInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? password = null,
  }) {
    return _then(_value.copyWith(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserLoginInputImplCopyWith<$Res>
    implements $UserLoginInputCopyWith<$Res> {
  factory _$$UserLoginInputImplCopyWith(_$UserLoginInputImpl value,
          $Res Function(_$UserLoginInputImpl) then) =
      __$$UserLoginInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String username, String password});
}

/// @nodoc
class __$$UserLoginInputImplCopyWithImpl<$Res>
    extends _$UserLoginInputCopyWithImpl<$Res, _$UserLoginInputImpl>
    implements _$$UserLoginInputImplCopyWith<$Res> {
  __$$UserLoginInputImplCopyWithImpl(
      _$UserLoginInputImpl _value, $Res Function(_$UserLoginInputImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserLoginInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? password = null,
  }) {
    return _then(_$UserLoginInputImpl(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserLoginInputImpl implements _UserLoginInput {
  const _$UserLoginInputImpl({required this.username, required this.password});

  factory _$UserLoginInputImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserLoginInputImplFromJson(json);

  @override
  final String username;
  @override
  final String password;

  @override
  String toString() {
    return 'UserLoginInput(username: $username, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserLoginInputImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, username, password);

  /// Create a copy of UserLoginInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserLoginInputImplCopyWith<_$UserLoginInputImpl> get copyWith =>
      __$$UserLoginInputImplCopyWithImpl<_$UserLoginInputImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserLoginInputImplToJson(
      this,
    );
  }
}

abstract class _UserLoginInput implements UserLoginInput {
  const factory _UserLoginInput(
      {required final String username,
      required final String password}) = _$UserLoginInputImpl;

  factory _UserLoginInput.fromJson(Map<String, dynamic> json) =
      _$UserLoginInputImpl.fromJson;

  @override
  String get username;
  @override
  String get password;

  /// Create a copy of UserLoginInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserLoginInputImplCopyWith<_$UserLoginInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserRegisterInput _$UserRegisterInputFromJson(Map<String, dynamic> json) {
  return _UserRegisterInput.fromJson(json);
}

/// @nodoc
mixin _$UserRegisterInput {
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;

  /// Serializes this UserRegisterInput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserRegisterInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserRegisterInputCopyWith<UserRegisterInput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserRegisterInputCopyWith<$Res> {
  factory $UserRegisterInputCopyWith(
          UserRegisterInput value, $Res Function(UserRegisterInput) then) =
      _$UserRegisterInputCopyWithImpl<$Res, UserRegisterInput>;
  @useResult
  $Res call({String username, String email, String password});
}

/// @nodoc
class _$UserRegisterInputCopyWithImpl<$Res, $Val extends UserRegisterInput>
    implements $UserRegisterInputCopyWith<$Res> {
  _$UserRegisterInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserRegisterInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? email = null,
    Object? password = null,
  }) {
    return _then(_value.copyWith(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserRegisterInputImplCopyWith<$Res>
    implements $UserRegisterInputCopyWith<$Res> {
  factory _$$UserRegisterInputImplCopyWith(_$UserRegisterInputImpl value,
          $Res Function(_$UserRegisterInputImpl) then) =
      __$$UserRegisterInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String username, String email, String password});
}

/// @nodoc
class __$$UserRegisterInputImplCopyWithImpl<$Res>
    extends _$UserRegisterInputCopyWithImpl<$Res, _$UserRegisterInputImpl>
    implements _$$UserRegisterInputImplCopyWith<$Res> {
  __$$UserRegisterInputImplCopyWithImpl(_$UserRegisterInputImpl _value,
      $Res Function(_$UserRegisterInputImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserRegisterInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? email = null,
    Object? password = null,
  }) {
    return _then(_$UserRegisterInputImpl(
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserRegisterInputImpl implements _UserRegisterInput {
  const _$UserRegisterInputImpl(
      {required this.username, required this.email, required this.password});

  factory _$UserRegisterInputImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserRegisterInputImplFromJson(json);

  @override
  final String username;
  @override
  final String email;
  @override
  final String password;

  @override
  String toString() {
    return 'UserRegisterInput(username: $username, email: $email, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserRegisterInputImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, username, email, password);

  /// Create a copy of UserRegisterInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserRegisterInputImplCopyWith<_$UserRegisterInputImpl> get copyWith =>
      __$$UserRegisterInputImplCopyWithImpl<_$UserRegisterInputImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserRegisterInputImplToJson(
      this,
    );
  }
}

abstract class _UserRegisterInput implements UserRegisterInput {
  const factory _UserRegisterInput(
      {required final String username,
      required final String email,
      required final String password}) = _$UserRegisterInputImpl;

  factory _UserRegisterInput.fromJson(Map<String, dynamic> json) =
      _$UserRegisterInputImpl.fromJson;

  @override
  String get username;
  @override
  String get email;
  @override
  String get password;

  /// Create a copy of UserRegisterInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserRegisterInputImplCopyWith<_$UserRegisterInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RefreshTokenInput _$RefreshTokenInputFromJson(Map<String, dynamic> json) {
  return _RefreshTokenInput.fromJson(json);
}

/// @nodoc
mixin _$RefreshTokenInput {
  @JsonKey(name: 'refresh_token')
  String get refreshToken => throw _privateConstructorUsedError;

  /// Serializes this RefreshTokenInput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RefreshTokenInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RefreshTokenInputCopyWith<RefreshTokenInput> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RefreshTokenInputCopyWith<$Res> {
  factory $RefreshTokenInputCopyWith(
          RefreshTokenInput value, $Res Function(RefreshTokenInput) then) =
      _$RefreshTokenInputCopyWithImpl<$Res, RefreshTokenInput>;
  @useResult
  $Res call({@JsonKey(name: 'refresh_token') String refreshToken});
}

/// @nodoc
class _$RefreshTokenInputCopyWithImpl<$Res, $Val extends RefreshTokenInput>
    implements $RefreshTokenInputCopyWith<$Res> {
  _$RefreshTokenInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RefreshTokenInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? refreshToken = null,
  }) {
    return _then(_value.copyWith(
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RefreshTokenInputImplCopyWith<$Res>
    implements $RefreshTokenInputCopyWith<$Res> {
  factory _$$RefreshTokenInputImplCopyWith(_$RefreshTokenInputImpl value,
          $Res Function(_$RefreshTokenInputImpl) then) =
      __$$RefreshTokenInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'refresh_token') String refreshToken});
}

/// @nodoc
class __$$RefreshTokenInputImplCopyWithImpl<$Res>
    extends _$RefreshTokenInputCopyWithImpl<$Res, _$RefreshTokenInputImpl>
    implements _$$RefreshTokenInputImplCopyWith<$Res> {
  __$$RefreshTokenInputImplCopyWithImpl(_$RefreshTokenInputImpl _value,
      $Res Function(_$RefreshTokenInputImpl) _then)
      : super(_value, _then);

  /// Create a copy of RefreshTokenInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? refreshToken = null,
  }) {
    return _then(_$RefreshTokenInputImpl(
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RefreshTokenInputImpl implements _RefreshTokenInput {
  const _$RefreshTokenInputImpl(
      {@JsonKey(name: 'refresh_token') required this.refreshToken});

  factory _$RefreshTokenInputImpl.fromJson(Map<String, dynamic> json) =>
      _$$RefreshTokenInputImplFromJson(json);

  @override
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @override
  String toString() {
    return 'RefreshTokenInput(refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RefreshTokenInputImpl &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, refreshToken);

  /// Create a copy of RefreshTokenInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RefreshTokenInputImplCopyWith<_$RefreshTokenInputImpl> get copyWith =>
      __$$RefreshTokenInputImplCopyWithImpl<_$RefreshTokenInputImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RefreshTokenInputImplToJson(
      this,
    );
  }
}

abstract class _RefreshTokenInput implements RefreshTokenInput {
  const factory _RefreshTokenInput(
      {@JsonKey(name: 'refresh_token')
      required final String refreshToken}) = _$RefreshTokenInputImpl;

  factory _RefreshTokenInput.fromJson(Map<String, dynamic> json) =
      _$RefreshTokenInputImpl.fromJson;

  @override
  @JsonKey(name: 'refresh_token')
  String get refreshToken;

  /// Create a copy of RefreshTokenInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RefreshTokenInputImplCopyWith<_$RefreshTokenInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserLoginSuccessData _$UserLoginSuccessDataFromJson(Map<String, dynamic> json) {
  return _UserLoginSuccessData.fromJson(json);
}

/// @nodoc
mixin _$UserLoginSuccessData {
  @JsonKey(name: 'access_token')
  String get accessToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'refresh_token')
  String get refreshToken => throw _privateConstructorUsedError;

  /// Serializes this UserLoginSuccessData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserLoginSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserLoginSuccessDataCopyWith<UserLoginSuccessData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserLoginSuccessDataCopyWith<$Res> {
  factory $UserLoginSuccessDataCopyWith(UserLoginSuccessData value,
          $Res Function(UserLoginSuccessData) then) =
      _$UserLoginSuccessDataCopyWithImpl<$Res, UserLoginSuccessData>;
  @useResult
  $Res call(
      {@JsonKey(name: 'access_token') String accessToken,
      @JsonKey(name: 'refresh_token') String refreshToken});
}

/// @nodoc
class _$UserLoginSuccessDataCopyWithImpl<$Res,
        $Val extends UserLoginSuccessData>
    implements $UserLoginSuccessDataCopyWith<$Res> {
  _$UserLoginSuccessDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserLoginSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
  }) {
    return _then(_value.copyWith(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserLoginSuccessDataImplCopyWith<$Res>
    implements $UserLoginSuccessDataCopyWith<$Res> {
  factory _$$UserLoginSuccessDataImplCopyWith(_$UserLoginSuccessDataImpl value,
          $Res Function(_$UserLoginSuccessDataImpl) then) =
      __$$UserLoginSuccessDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'access_token') String accessToken,
      @JsonKey(name: 'refresh_token') String refreshToken});
}

/// @nodoc
class __$$UserLoginSuccessDataImplCopyWithImpl<$Res>
    extends _$UserLoginSuccessDataCopyWithImpl<$Res, _$UserLoginSuccessDataImpl>
    implements _$$UserLoginSuccessDataImplCopyWith<$Res> {
  __$$UserLoginSuccessDataImplCopyWithImpl(_$UserLoginSuccessDataImpl _value,
      $Res Function(_$UserLoginSuccessDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserLoginSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
  }) {
    return _then(_$UserLoginSuccessDataImpl(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
      refreshToken: null == refreshToken
          ? _value.refreshToken
          : refreshToken // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserLoginSuccessDataImpl implements _UserLoginSuccessData {
  const _$UserLoginSuccessDataImpl(
      {@JsonKey(name: 'access_token') required this.accessToken,
      @JsonKey(name: 'refresh_token') required this.refreshToken});

  factory _$UserLoginSuccessDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserLoginSuccessDataImplFromJson(json);

  @override
  @JsonKey(name: 'access_token')
  final String accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @override
  String toString() {
    return 'UserLoginSuccessData(accessToken: $accessToken, refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserLoginSuccessDataImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, accessToken, refreshToken);

  /// Create a copy of UserLoginSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserLoginSuccessDataImplCopyWith<_$UserLoginSuccessDataImpl>
      get copyWith =>
          __$$UserLoginSuccessDataImplCopyWithImpl<_$UserLoginSuccessDataImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserLoginSuccessDataImplToJson(
      this,
    );
  }
}

abstract class _UserLoginSuccessData implements UserLoginSuccessData {
  const factory _UserLoginSuccessData(
          {@JsonKey(name: 'access_token') required final String accessToken,
          @JsonKey(name: 'refresh_token') required final String refreshToken}) =
      _$UserLoginSuccessDataImpl;

  factory _UserLoginSuccessData.fromJson(Map<String, dynamic> json) =
      _$UserLoginSuccessDataImpl.fromJson;

  @override
  @JsonKey(name: 'access_token')
  String get accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  String get refreshToken;

  /// Create a copy of UserLoginSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserLoginSuccessDataImplCopyWith<_$UserLoginSuccessDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}

UserRegisterSuccessData _$UserRegisterSuccessDataFromJson(
    Map<String, dynamic> json) {
  return _UserRegisterSuccessData.fromJson(json);
}

/// @nodoc
mixin _$UserRegisterSuccessData {
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;

  /// Serializes this UserRegisterSuccessData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserRegisterSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserRegisterSuccessDataCopyWith<UserRegisterSuccessData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserRegisterSuccessDataCopyWith<$Res> {
  factory $UserRegisterSuccessDataCopyWith(UserRegisterSuccessData value,
          $Res Function(UserRegisterSuccessData) then) =
      _$UserRegisterSuccessDataCopyWithImpl<$Res, UserRegisterSuccessData>;
  @useResult
  $Res call({@JsonKey(name: 'user_id') int userId, String username});
}

/// @nodoc
class _$UserRegisterSuccessDataCopyWithImpl<$Res,
        $Val extends UserRegisterSuccessData>
    implements $UserRegisterSuccessDataCopyWith<$Res> {
  _$UserRegisterSuccessDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserRegisterSuccessData
  /// with the given fields replaced by the non-null parameter values.
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
abstract class _$$UserRegisterSuccessDataImplCopyWith<$Res>
    implements $UserRegisterSuccessDataCopyWith<$Res> {
  factory _$$UserRegisterSuccessDataImplCopyWith(
          _$UserRegisterSuccessDataImpl value,
          $Res Function(_$UserRegisterSuccessDataImpl) then) =
      __$$UserRegisterSuccessDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'user_id') int userId, String username});
}

/// @nodoc
class __$$UserRegisterSuccessDataImplCopyWithImpl<$Res>
    extends _$UserRegisterSuccessDataCopyWithImpl<$Res,
        _$UserRegisterSuccessDataImpl>
    implements _$$UserRegisterSuccessDataImplCopyWith<$Res> {
  __$$UserRegisterSuccessDataImplCopyWithImpl(
      _$UserRegisterSuccessDataImpl _value,
      $Res Function(_$UserRegisterSuccessDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserRegisterSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? username = null,
  }) {
    return _then(_$UserRegisterSuccessDataImpl(
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
class _$UserRegisterSuccessDataImpl implements _UserRegisterSuccessData {
  const _$UserRegisterSuccessDataImpl(
      {@JsonKey(name: 'user_id') required this.userId, required this.username});

  factory _$UserRegisterSuccessDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserRegisterSuccessDataImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  final String username;

  @override
  String toString() {
    return 'UserRegisterSuccessData(userId: $userId, username: $username)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserRegisterSuccessDataImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.username, username) ||
                other.username == username));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, userId, username);

  /// Create a copy of UserRegisterSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserRegisterSuccessDataImplCopyWith<_$UserRegisterSuccessDataImpl>
      get copyWith => __$$UserRegisterSuccessDataImplCopyWithImpl<
          _$UserRegisterSuccessDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserRegisterSuccessDataImplToJson(
      this,
    );
  }
}

abstract class _UserRegisterSuccessData implements UserRegisterSuccessData {
  const factory _UserRegisterSuccessData(
      {@JsonKey(name: 'user_id') required final int userId,
      required final String username}) = _$UserRegisterSuccessDataImpl;

  factory _UserRegisterSuccessData.fromJson(Map<String, dynamic> json) =
      _$UserRegisterSuccessDataImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  String get username;

  /// Create a copy of UserRegisterSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserRegisterSuccessDataImplCopyWith<_$UserRegisterSuccessDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}

RefreshTokenSuccessData _$RefreshTokenSuccessDataFromJson(
    Map<String, dynamic> json) {
  return _RefreshTokenSuccessData.fromJson(json);
}

/// @nodoc
mixin _$RefreshTokenSuccessData {
  @JsonKey(name: 'access_token')
  String get accessToken => throw _privateConstructorUsedError;

  /// Serializes this RefreshTokenSuccessData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RefreshTokenSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RefreshTokenSuccessDataCopyWith<RefreshTokenSuccessData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RefreshTokenSuccessDataCopyWith<$Res> {
  factory $RefreshTokenSuccessDataCopyWith(RefreshTokenSuccessData value,
          $Res Function(RefreshTokenSuccessData) then) =
      _$RefreshTokenSuccessDataCopyWithImpl<$Res, RefreshTokenSuccessData>;
  @useResult
  $Res call({@JsonKey(name: 'access_token') String accessToken});
}

/// @nodoc
class _$RefreshTokenSuccessDataCopyWithImpl<$Res,
        $Val extends RefreshTokenSuccessData>
    implements $RefreshTokenSuccessDataCopyWith<$Res> {
  _$RefreshTokenSuccessDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RefreshTokenSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
  }) {
    return _then(_value.copyWith(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RefreshTokenSuccessDataImplCopyWith<$Res>
    implements $RefreshTokenSuccessDataCopyWith<$Res> {
  factory _$$RefreshTokenSuccessDataImplCopyWith(
          _$RefreshTokenSuccessDataImpl value,
          $Res Function(_$RefreshTokenSuccessDataImpl) then) =
      __$$RefreshTokenSuccessDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'access_token') String accessToken});
}

/// @nodoc
class __$$RefreshTokenSuccessDataImplCopyWithImpl<$Res>
    extends _$RefreshTokenSuccessDataCopyWithImpl<$Res,
        _$RefreshTokenSuccessDataImpl>
    implements _$$RefreshTokenSuccessDataImplCopyWith<$Res> {
  __$$RefreshTokenSuccessDataImplCopyWithImpl(
      _$RefreshTokenSuccessDataImpl _value,
      $Res Function(_$RefreshTokenSuccessDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of RefreshTokenSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
  }) {
    return _then(_$RefreshTokenSuccessDataImpl(
      accessToken: null == accessToken
          ? _value.accessToken
          : accessToken // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RefreshTokenSuccessDataImpl implements _RefreshTokenSuccessData {
  const _$RefreshTokenSuccessDataImpl(
      {@JsonKey(name: 'access_token') required this.accessToken});

  factory _$RefreshTokenSuccessDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$RefreshTokenSuccessDataImplFromJson(json);

  @override
  @JsonKey(name: 'access_token')
  final String accessToken;

  @override
  String toString() {
    return 'RefreshTokenSuccessData(accessToken: $accessToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RefreshTokenSuccessDataImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, accessToken);

  /// Create a copy of RefreshTokenSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RefreshTokenSuccessDataImplCopyWith<_$RefreshTokenSuccessDataImpl>
      get copyWith => __$$RefreshTokenSuccessDataImplCopyWithImpl<
          _$RefreshTokenSuccessDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RefreshTokenSuccessDataImplToJson(
      this,
    );
  }
}

abstract class _RefreshTokenSuccessData implements RefreshTokenSuccessData {
  const factory _RefreshTokenSuccessData(
          {@JsonKey(name: 'access_token') required final String accessToken}) =
      _$RefreshTokenSuccessDataImpl;

  factory _RefreshTokenSuccessData.fromJson(Map<String, dynamic> json) =
      _$RefreshTokenSuccessDataImpl.fromJson;

  @override
  @JsonKey(name: 'access_token')
  String get accessToken;

  /// Create a copy of RefreshTokenSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RefreshTokenSuccessDataImplCopyWith<_$RefreshTokenSuccessDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}

GetProfileSuccessData _$GetProfileSuccessDataFromJson(
    Map<String, dynamic> json) {
  return _GetProfileSuccessData.fromJson(json);
}

/// @nodoc
mixin _$GetProfileSuccessData {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this GetProfileSuccessData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GetProfileSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GetProfileSuccessDataCopyWith<GetProfileSuccessData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GetProfileSuccessDataCopyWith<$Res> {
  factory $GetProfileSuccessDataCopyWith(GetProfileSuccessData value,
          $Res Function(GetProfileSuccessData) then) =
      _$GetProfileSuccessDataCopyWithImpl<$Res, GetProfileSuccessData>;
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class _$GetProfileSuccessDataCopyWithImpl<$Res,
        $Val extends GetProfileSuccessData>
    implements $GetProfileSuccessDataCopyWith<$Res> {
  _$GetProfileSuccessDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GetProfileSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? createdAt = null,
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GetProfileSuccessDataImplCopyWith<$Res>
    implements $GetProfileSuccessDataCopyWith<$Res> {
  factory _$$GetProfileSuccessDataImplCopyWith(
          _$GetProfileSuccessDataImpl value,
          $Res Function(_$GetProfileSuccessDataImpl) then) =
      __$$GetProfileSuccessDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String username,
      String email,
      @JsonKey(name: 'created_at') DateTime createdAt});
}

/// @nodoc
class __$$GetProfileSuccessDataImplCopyWithImpl<$Res>
    extends _$GetProfileSuccessDataCopyWithImpl<$Res,
        _$GetProfileSuccessDataImpl>
    implements _$$GetProfileSuccessDataImplCopyWith<$Res> {
  __$$GetProfileSuccessDataImplCopyWithImpl(_$GetProfileSuccessDataImpl _value,
      $Res Function(_$GetProfileSuccessDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of GetProfileSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? email = null,
    Object? createdAt = null,
  }) {
    return _then(_$GetProfileSuccessDataImpl(
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GetProfileSuccessDataImpl implements _GetProfileSuccessData {
  const _$GetProfileSuccessDataImpl(
      {required this.id,
      required this.username,
      required this.email,
      @JsonKey(name: 'created_at') required this.createdAt});

  factory _$GetProfileSuccessDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$GetProfileSuccessDataImplFromJson(json);

  @override
  final int id;
  @override
  final String username;
  @override
  final String email;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'GetProfileSuccessData(id: $id, username: $username, email: $email, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GetProfileSuccessDataImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, username, email, createdAt);

  /// Create a copy of GetProfileSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GetProfileSuccessDataImplCopyWith<_$GetProfileSuccessDataImpl>
      get copyWith => __$$GetProfileSuccessDataImplCopyWithImpl<
          _$GetProfileSuccessDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GetProfileSuccessDataImplToJson(
      this,
    );
  }
}

abstract class _GetProfileSuccessData implements GetProfileSuccessData {
  const factory _GetProfileSuccessData(
          {required final int id,
          required final String username,
          required final String email,
          @JsonKey(name: 'created_at') required final DateTime createdAt}) =
      _$GetProfileSuccessDataImpl;

  factory _GetProfileSuccessData.fromJson(Map<String, dynamic> json) =
      _$GetProfileSuccessDataImpl.fromJson;

  @override
  int get id;
  @override
  String get username;
  @override
  String get email;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of GetProfileSuccessData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GetProfileSuccessDataImplCopyWith<_$GetProfileSuccessDataImpl>
      get copyWith => throw _privateConstructorUsedError;
}
