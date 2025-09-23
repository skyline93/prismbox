// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MediaResponse _$MediaResponseFromJson(Map<String, dynamic> json) {
  return _MediaResponse.fromJson(json);
}

/// @nodoc
mixin _$MediaResponse {
  String get uuid => throw _privateConstructorUsedError;
  String get filename => throw _privateConstructorUsedError;
  @JsonKey(name: 'original_filename')
  String get originalFilename => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_type')
  String get itemType => throw _privateConstructorUsedError;
  @JsonKey(name: 'hash')
  String get hash => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_taken_at')
  String? get mediaTakenAt => throw _privateConstructorUsedError;
  int get width => throw _privateConstructorUsedError;
  int get height => throw _privateConstructorUsedError;
  @JsonKey(name: 'download_url')
  String get downloadUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'preview_url')
  String get previewUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'thumbnail_url')
  String get thumbnailUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MediaResponseCopyWith<MediaResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaResponseCopyWith<$Res> {
  factory $MediaResponseCopyWith(
          MediaResponse value, $Res Function(MediaResponse) then) =
      _$MediaResponseCopyWithImpl<$Res, MediaResponse>;
  @useResult
  $Res call(
      {String uuid,
      String filename,
      @JsonKey(name: 'original_filename') String originalFilename,
      @JsonKey(name: 'item_type') String itemType,
      @JsonKey(name: 'hash') String hash,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      @JsonKey(name: 'media_taken_at') String? mediaTakenAt,
      int width,
      int height,
      @JsonKey(name: 'download_url') String downloadUrl,
      @JsonKey(name: 'preview_url') String previewUrl,
      @JsonKey(name: 'thumbnail_url') String thumbnailUrl});
}

/// @nodoc
class _$MediaResponseCopyWithImpl<$Res, $Val extends MediaResponse>
    implements $MediaResponseCopyWith<$Res> {
  _$MediaResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = null,
    Object? filename = null,
    Object? originalFilename = null,
    Object? itemType = null,
    Object? hash = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? mediaTakenAt = freezed,
    Object? width = null,
    Object? height = null,
    Object? downloadUrl = null,
    Object? previewUrl = null,
    Object? thumbnailUrl = null,
  }) {
    return _then(_value.copyWith(
      uuid: null == uuid
          ? _value.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      filename: null == filename
          ? _value.filename
          : filename // ignore: cast_nullable_to_non_nullable
              as String,
      originalFilename: null == originalFilename
          ? _value.originalFilename
          : originalFilename // ignore: cast_nullable_to_non_nullable
              as String,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      mediaTakenAt: freezed == mediaTakenAt
          ? _value.mediaTakenAt
          : mediaTakenAt // ignore: cast_nullable_to_non_nullable
              as String?,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      downloadUrl: null == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      previewUrl: null == previewUrl
          ? _value.previewUrl
          : previewUrl // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: null == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MediaResponseImplCopyWith<$Res>
    implements $MediaResponseCopyWith<$Res> {
  factory _$$MediaResponseImplCopyWith(
          _$MediaResponseImpl value, $Res Function(_$MediaResponseImpl) then) =
      __$$MediaResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uuid,
      String filename,
      @JsonKey(name: 'original_filename') String originalFilename,
      @JsonKey(name: 'item_type') String itemType,
      @JsonKey(name: 'hash') String hash,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'updated_at') String updatedAt,
      @JsonKey(name: 'media_taken_at') String? mediaTakenAt,
      int width,
      int height,
      @JsonKey(name: 'download_url') String downloadUrl,
      @JsonKey(name: 'preview_url') String previewUrl,
      @JsonKey(name: 'thumbnail_url') String thumbnailUrl});
}

/// @nodoc
class __$$MediaResponseImplCopyWithImpl<$Res>
    extends _$MediaResponseCopyWithImpl<$Res, _$MediaResponseImpl>
    implements _$$MediaResponseImplCopyWith<$Res> {
  __$$MediaResponseImplCopyWithImpl(
      _$MediaResponseImpl _value, $Res Function(_$MediaResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uuid = null,
    Object? filename = null,
    Object? originalFilename = null,
    Object? itemType = null,
    Object? hash = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? mediaTakenAt = freezed,
    Object? width = null,
    Object? height = null,
    Object? downloadUrl = null,
    Object? previewUrl = null,
    Object? thumbnailUrl = null,
  }) {
    return _then(_$MediaResponseImpl(
      uuid: null == uuid
          ? _value.uuid
          : uuid // ignore: cast_nullable_to_non_nullable
              as String,
      filename: null == filename
          ? _value.filename
          : filename // ignore: cast_nullable_to_non_nullable
              as String,
      originalFilename: null == originalFilename
          ? _value.originalFilename
          : originalFilename // ignore: cast_nullable_to_non_nullable
              as String,
      itemType: null == itemType
          ? _value.itemType
          : itemType // ignore: cast_nullable_to_non_nullable
              as String,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      mediaTakenAt: freezed == mediaTakenAt
          ? _value.mediaTakenAt
          : mediaTakenAt // ignore: cast_nullable_to_non_nullable
              as String?,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      downloadUrl: null == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String,
      previewUrl: null == previewUrl
          ? _value.previewUrl
          : previewUrl // ignore: cast_nullable_to_non_nullable
              as String,
      thumbnailUrl: null == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaResponseImpl implements _MediaResponse {
  const _$MediaResponseImpl(
      {required this.uuid,
      required this.filename,
      @JsonKey(name: 'original_filename') required this.originalFilename,
      @JsonKey(name: 'item_type') required this.itemType,
      @JsonKey(name: 'hash') required this.hash,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'updated_at') required this.updatedAt,
      @JsonKey(name: 'media_taken_at') this.mediaTakenAt,
      required this.width,
      required this.height,
      @JsonKey(name: 'download_url') required this.downloadUrl,
      @JsonKey(name: 'preview_url') required this.previewUrl,
      @JsonKey(name: 'thumbnail_url') required this.thumbnailUrl});

  factory _$MediaResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaResponseImplFromJson(json);

  @override
  final String uuid;
  @override
  final String filename;
  @override
  @JsonKey(name: 'original_filename')
  final String originalFilename;
  @override
  @JsonKey(name: 'item_type')
  final String itemType;
  @override
  @JsonKey(name: 'hash')
  final String hash;
  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @override
  @JsonKey(name: 'media_taken_at')
  final String? mediaTakenAt;
  @override
  final int width;
  @override
  final int height;
  @override
  @JsonKey(name: 'download_url')
  final String downloadUrl;
  @override
  @JsonKey(name: 'preview_url')
  final String previewUrl;
  @override
  @JsonKey(name: 'thumbnail_url')
  final String thumbnailUrl;

  @override
  String toString() {
    return 'MediaResponse(uuid: $uuid, filename: $filename, originalFilename: $originalFilename, itemType: $itemType, hash: $hash, createdAt: $createdAt, updatedAt: $updatedAt, mediaTakenAt: $mediaTakenAt, width: $width, height: $height, downloadUrl: $downloadUrl, previewUrl: $previewUrl, thumbnailUrl: $thumbnailUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaResponseImpl &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.filename, filename) ||
                other.filename == filename) &&
            (identical(other.originalFilename, originalFilename) ||
                other.originalFilename == originalFilename) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.mediaTakenAt, mediaTakenAt) ||
                other.mediaTakenAt == mediaTakenAt) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.previewUrl, previewUrl) ||
                other.previewUrl == previewUrl) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      uuid,
      filename,
      originalFilename,
      itemType,
      hash,
      createdAt,
      updatedAt,
      mediaTakenAt,
      width,
      height,
      downloadUrl,
      previewUrl,
      thumbnailUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaResponseImplCopyWith<_$MediaResponseImpl> get copyWith =>
      __$$MediaResponseImplCopyWithImpl<_$MediaResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaResponseImplToJson(
      this,
    );
  }
}

abstract class _MediaResponse implements MediaResponse {
  const factory _MediaResponse(
          {required final String uuid,
          required final String filename,
          @JsonKey(name: 'original_filename')
          required final String originalFilename,
          @JsonKey(name: 'item_type') required final String itemType,
          @JsonKey(name: 'hash') required final String hash,
          @JsonKey(name: 'created_at') required final String createdAt,
          @JsonKey(name: 'updated_at') required final String updatedAt,
          @JsonKey(name: 'media_taken_at') final String? mediaTakenAt,
          required final int width,
          required final int height,
          @JsonKey(name: 'download_url') required final String downloadUrl,
          @JsonKey(name: 'preview_url') required final String previewUrl,
          @JsonKey(name: 'thumbnail_url') required final String thumbnailUrl}) =
      _$MediaResponseImpl;

  factory _MediaResponse.fromJson(Map<String, dynamic> json) =
      _$MediaResponseImpl.fromJson;

  @override
  String get uuid;
  @override
  String get filename;
  @override
  @JsonKey(name: 'original_filename')
  String get originalFilename;
  @override
  @JsonKey(name: 'item_type')
  String get itemType;
  @override
  @JsonKey(name: 'hash')
  String get hash;
  @override
  @JsonKey(name: 'created_at')
  String get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String get updatedAt;
  @override
  @JsonKey(name: 'media_taken_at')
  String? get mediaTakenAt;
  @override
  int get width;
  @override
  int get height;
  @override
  @JsonKey(name: 'download_url')
  String get downloadUrl;
  @override
  @JsonKey(name: 'preview_url')
  String get previewUrl;
  @override
  @JsonKey(name: 'thumbnail_url')
  String get thumbnailUrl;
  @override
  @JsonKey(ignore: true)
  _$$MediaResponseImplCopyWith<_$MediaResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CheckHashesRequest _$CheckHashesRequestFromJson(Map<String, dynamic> json) {
  return _CheckHashesRequest.fromJson(json);
}

/// @nodoc
mixin _$CheckHashesRequest {
  List<String> get hashes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CheckHashesRequestCopyWith<CheckHashesRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckHashesRequestCopyWith<$Res> {
  factory $CheckHashesRequestCopyWith(
          CheckHashesRequest value, $Res Function(CheckHashesRequest) then) =
      _$CheckHashesRequestCopyWithImpl<$Res, CheckHashesRequest>;
  @useResult
  $Res call({List<String> hashes});
}

/// @nodoc
class _$CheckHashesRequestCopyWithImpl<$Res, $Val extends CheckHashesRequest>
    implements $CheckHashesRequestCopyWith<$Res> {
  _$CheckHashesRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hashes = null,
  }) {
    return _then(_value.copyWith(
      hashes: null == hashes
          ? _value.hashes
          : hashes // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CheckHashesRequestImplCopyWith<$Res>
    implements $CheckHashesRequestCopyWith<$Res> {
  factory _$$CheckHashesRequestImplCopyWith(_$CheckHashesRequestImpl value,
          $Res Function(_$CheckHashesRequestImpl) then) =
      __$$CheckHashesRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<String> hashes});
}

/// @nodoc
class __$$CheckHashesRequestImplCopyWithImpl<$Res>
    extends _$CheckHashesRequestCopyWithImpl<$Res, _$CheckHashesRequestImpl>
    implements _$$CheckHashesRequestImplCopyWith<$Res> {
  __$$CheckHashesRequestImplCopyWithImpl(_$CheckHashesRequestImpl _value,
      $Res Function(_$CheckHashesRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hashes = null,
  }) {
    return _then(_$CheckHashesRequestImpl(
      hashes: null == hashes
          ? _value._hashes
          : hashes // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CheckHashesRequestImpl implements _CheckHashesRequest {
  const _$CheckHashesRequestImpl({required final List<String> hashes})
      : _hashes = hashes;

  factory _$CheckHashesRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckHashesRequestImplFromJson(json);

  final List<String> _hashes;
  @override
  List<String> get hashes {
    if (_hashes is EqualUnmodifiableListView) return _hashes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_hashes);
  }

  @override
  String toString() {
    return 'CheckHashesRequest(hashes: $hashes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckHashesRequestImpl &&
            const DeepCollectionEquality().equals(other._hashes, _hashes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_hashes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckHashesRequestImplCopyWith<_$CheckHashesRequestImpl> get copyWith =>
      __$$CheckHashesRequestImplCopyWithImpl<_$CheckHashesRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckHashesRequestImplToJson(
      this,
    );
  }
}

abstract class _CheckHashesRequest implements CheckHashesRequest {
  const factory _CheckHashesRequest({required final List<String> hashes}) =
      _$CheckHashesRequestImpl;

  factory _CheckHashesRequest.fromJson(Map<String, dynamic> json) =
      _$CheckHashesRequestImpl.fromJson;

  @override
  List<String> get hashes;
  @override
  @JsonKey(ignore: true)
  _$$CheckHashesRequestImplCopyWith<_$CheckHashesRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CheckHashesResponse _$CheckHashesResponseFromJson(Map<String, dynamic> json) {
  return _CheckHashesResponse.fromJson(json);
}

/// @nodoc
mixin _$CheckHashesResponse {
  @JsonKey(name: 'existing_hashes')
  List<String> get existingHashes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CheckHashesResponseCopyWith<CheckHashesResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckHashesResponseCopyWith<$Res> {
  factory $CheckHashesResponseCopyWith(
          CheckHashesResponse value, $Res Function(CheckHashesResponse) then) =
      _$CheckHashesResponseCopyWithImpl<$Res, CheckHashesResponse>;
  @useResult
  $Res call({@JsonKey(name: 'existing_hashes') List<String> existingHashes});
}

/// @nodoc
class _$CheckHashesResponseCopyWithImpl<$Res, $Val extends CheckHashesResponse>
    implements $CheckHashesResponseCopyWith<$Res> {
  _$CheckHashesResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? existingHashes = null,
  }) {
    return _then(_value.copyWith(
      existingHashes: null == existingHashes
          ? _value.existingHashes
          : existingHashes // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CheckHashesResponseImplCopyWith<$Res>
    implements $CheckHashesResponseCopyWith<$Res> {
  factory _$$CheckHashesResponseImplCopyWith(_$CheckHashesResponseImpl value,
          $Res Function(_$CheckHashesResponseImpl) then) =
      __$$CheckHashesResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'existing_hashes') List<String> existingHashes});
}

/// @nodoc
class __$$CheckHashesResponseImplCopyWithImpl<$Res>
    extends _$CheckHashesResponseCopyWithImpl<$Res, _$CheckHashesResponseImpl>
    implements _$$CheckHashesResponseImplCopyWith<$Res> {
  __$$CheckHashesResponseImplCopyWithImpl(_$CheckHashesResponseImpl _value,
      $Res Function(_$CheckHashesResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? existingHashes = null,
  }) {
    return _then(_$CheckHashesResponseImpl(
      existingHashes: null == existingHashes
          ? _value._existingHashes
          : existingHashes // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CheckHashesResponseImpl implements _CheckHashesResponse {
  const _$CheckHashesResponseImpl(
      {@JsonKey(name: 'existing_hashes')
      required final List<String> existingHashes})
      : _existingHashes = existingHashes;

  factory _$CheckHashesResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckHashesResponseImplFromJson(json);

  final List<String> _existingHashes;
  @override
  @JsonKey(name: 'existing_hashes')
  List<String> get existingHashes {
    if (_existingHashes is EqualUnmodifiableListView) return _existingHashes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_existingHashes);
  }

  @override
  String toString() {
    return 'CheckHashesResponse(existingHashes: $existingHashes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CheckHashesResponseImpl &&
            const DeepCollectionEquality()
                .equals(other._existingHashes, _existingHashes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_existingHashes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckHashesResponseImplCopyWith<_$CheckHashesResponseImpl> get copyWith =>
      __$$CheckHashesResponseImplCopyWithImpl<_$CheckHashesResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CheckHashesResponseImplToJson(
      this,
    );
  }
}

abstract class _CheckHashesResponse implements CheckHashesResponse {
  const factory _CheckHashesResponse(
      {@JsonKey(name: 'existing_hashes')
      required final List<String> existingHashes}) = _$CheckHashesResponseImpl;

  factory _CheckHashesResponse.fromJson(Map<String, dynamic> json) =
      _$CheckHashesResponseImpl.fromJson;

  @override
  @JsonKey(name: 'existing_hashes')
  List<String> get existingHashes;
  @override
  @JsonKey(ignore: true)
  _$$CheckHashesResponseImplCopyWith<_$CheckHashesResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
