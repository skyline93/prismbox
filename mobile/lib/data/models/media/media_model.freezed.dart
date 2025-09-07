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

MediaDetail _$MediaDetailFromJson(Map<String, dynamic> json) {
  return _MediaDetail.fromJson(json);
}

/// @nodoc
mixin _$MediaDetail {
  int get id => throw _privateConstructorUsedError;
  String get uuid => throw _privateConstructorUsedError;
  String get filename => throw _privateConstructorUsedError;
  String get originalFilename => throw _privateConstructorUsedError;
  MediaType get itemType => throw _privateConstructorUsedError;
  String get mimeType => throw _privateConstructorUsedError;
  int get fileSize => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;
  String? get mediaTakenAt => throw _privateConstructorUsedError;
  String? get cameraMake => throw _privateConstructorUsedError;
  String? get cameraModel => throw _privateConstructorUsedError;
  String? get aperture => throw _privateConstructorUsedError;
  String? get shutterSpeed => throw _privateConstructorUsedError;
  int? get iso => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  String get hash => throw _privateConstructorUsedError;
  ProcessingStatus get processingStatus => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String get updatedAt => throw _privateConstructorUsedError;
  int get userID => throw _privateConstructorUsedError;

  /// Serializes this MediaDetail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaDetailCopyWith<MediaDetail> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaDetailCopyWith<$Res> {
  factory $MediaDetailCopyWith(
          MediaDetail value, $Res Function(MediaDetail) then) =
      _$MediaDetailCopyWithImpl<$Res, MediaDetail>;
  @useResult
  $Res call(
      {int id,
      String uuid,
      String filename,
      String originalFilename,
      MediaType itemType,
      String mimeType,
      int fileSize,
      int? width,
      int? height,
      String? mediaTakenAt,
      String? cameraMake,
      String? cameraModel,
      String? aperture,
      String? shutterSpeed,
      int? iso,
      double? latitude,
      double? longitude,
      String hash,
      ProcessingStatus processingStatus,
      String createdAt,
      String updatedAt,
      int userID});
}

/// @nodoc
class _$MediaDetailCopyWithImpl<$Res, $Val extends MediaDetail>
    implements $MediaDetailCopyWith<$Res> {
  _$MediaDetailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? uuid = null,
    Object? filename = null,
    Object? originalFilename = null,
    Object? itemType = null,
    Object? mimeType = null,
    Object? fileSize = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? mediaTakenAt = freezed,
    Object? cameraMake = freezed,
    Object? cameraModel = freezed,
    Object? aperture = freezed,
    Object? shutterSpeed = freezed,
    Object? iso = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? hash = null,
    Object? processingStatus = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? userID = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
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
              as MediaType,
      mimeType: null == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      mediaTakenAt: freezed == mediaTakenAt
          ? _value.mediaTakenAt
          : mediaTakenAt // ignore: cast_nullable_to_non_nullable
              as String?,
      cameraMake: freezed == cameraMake
          ? _value.cameraMake
          : cameraMake // ignore: cast_nullable_to_non_nullable
              as String?,
      cameraModel: freezed == cameraModel
          ? _value.cameraModel
          : cameraModel // ignore: cast_nullable_to_non_nullable
              as String?,
      aperture: freezed == aperture
          ? _value.aperture
          : aperture // ignore: cast_nullable_to_non_nullable
              as String?,
      shutterSpeed: freezed == shutterSpeed
          ? _value.shutterSpeed
          : shutterSpeed // ignore: cast_nullable_to_non_nullable
              as String?,
      iso: freezed == iso
          ? _value.iso
          : iso // ignore: cast_nullable_to_non_nullable
              as int?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      processingStatus: null == processingStatus
          ? _value.processingStatus
          : processingStatus // ignore: cast_nullable_to_non_nullable
              as ProcessingStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      userID: null == userID
          ? _value.userID
          : userID // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MediaDetailImplCopyWith<$Res>
    implements $MediaDetailCopyWith<$Res> {
  factory _$$MediaDetailImplCopyWith(
          _$MediaDetailImpl value, $Res Function(_$MediaDetailImpl) then) =
      __$$MediaDetailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String uuid,
      String filename,
      String originalFilename,
      MediaType itemType,
      String mimeType,
      int fileSize,
      int? width,
      int? height,
      String? mediaTakenAt,
      String? cameraMake,
      String? cameraModel,
      String? aperture,
      String? shutterSpeed,
      int? iso,
      double? latitude,
      double? longitude,
      String hash,
      ProcessingStatus processingStatus,
      String createdAt,
      String updatedAt,
      int userID});
}

/// @nodoc
class __$$MediaDetailImplCopyWithImpl<$Res>
    extends _$MediaDetailCopyWithImpl<$Res, _$MediaDetailImpl>
    implements _$$MediaDetailImplCopyWith<$Res> {
  __$$MediaDetailImplCopyWithImpl(
      _$MediaDetailImpl _value, $Res Function(_$MediaDetailImpl) _then)
      : super(_value, _then);

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? uuid = null,
    Object? filename = null,
    Object? originalFilename = null,
    Object? itemType = null,
    Object? mimeType = null,
    Object? fileSize = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? mediaTakenAt = freezed,
    Object? cameraMake = freezed,
    Object? cameraModel = freezed,
    Object? aperture = freezed,
    Object? shutterSpeed = freezed,
    Object? iso = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? hash = null,
    Object? processingStatus = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? userID = null,
  }) {
    return _then(_$MediaDetailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
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
              as MediaType,
      mimeType: null == mimeType
          ? _value.mimeType
          : mimeType // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      mediaTakenAt: freezed == mediaTakenAt
          ? _value.mediaTakenAt
          : mediaTakenAt // ignore: cast_nullable_to_non_nullable
              as String?,
      cameraMake: freezed == cameraMake
          ? _value.cameraMake
          : cameraMake // ignore: cast_nullable_to_non_nullable
              as String?,
      cameraModel: freezed == cameraModel
          ? _value.cameraModel
          : cameraModel // ignore: cast_nullable_to_non_nullable
              as String?,
      aperture: freezed == aperture
          ? _value.aperture
          : aperture // ignore: cast_nullable_to_non_nullable
              as String?,
      shutterSpeed: freezed == shutterSpeed
          ? _value.shutterSpeed
          : shutterSpeed // ignore: cast_nullable_to_non_nullable
              as String?,
      iso: freezed == iso
          ? _value.iso
          : iso // ignore: cast_nullable_to_non_nullable
              as int?,
      latitude: freezed == latitude
          ? _value.latitude
          : latitude // ignore: cast_nullable_to_non_nullable
              as double?,
      longitude: freezed == longitude
          ? _value.longitude
          : longitude // ignore: cast_nullable_to_non_nullable
              as double?,
      hash: null == hash
          ? _value.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      processingStatus: null == processingStatus
          ? _value.processingStatus
          : processingStatus // ignore: cast_nullable_to_non_nullable
              as ProcessingStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String,
      userID: null == userID
          ? _value.userID
          : userID // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaDetailImpl implements _MediaDetail {
  const _$MediaDetailImpl(
      {required this.id,
      required this.uuid,
      required this.filename,
      required this.originalFilename,
      required this.itemType,
      required this.mimeType,
      required this.fileSize,
      this.width,
      this.height,
      this.mediaTakenAt,
      this.cameraMake,
      this.cameraModel,
      this.aperture,
      this.shutterSpeed,
      this.iso,
      this.latitude,
      this.longitude,
      required this.hash,
      required this.processingStatus,
      required this.createdAt,
      required this.updatedAt,
      required this.userID});

  factory _$MediaDetailImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaDetailImplFromJson(json);

  @override
  final int id;
  @override
  final String uuid;
  @override
  final String filename;
  @override
  final String originalFilename;
  @override
  final MediaType itemType;
  @override
  final String mimeType;
  @override
  final int fileSize;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final String? mediaTakenAt;
  @override
  final String? cameraMake;
  @override
  final String? cameraModel;
  @override
  final String? aperture;
  @override
  final String? shutterSpeed;
  @override
  final int? iso;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  final String hash;
  @override
  final ProcessingStatus processingStatus;
  @override
  final String createdAt;
  @override
  final String updatedAt;
  @override
  final int userID;

  @override
  String toString() {
    return 'MediaDetail(id: $id, uuid: $uuid, filename: $filename, originalFilename: $originalFilename, itemType: $itemType, mimeType: $mimeType, fileSize: $fileSize, width: $width, height: $height, mediaTakenAt: $mediaTakenAt, cameraMake: $cameraMake, cameraModel: $cameraModel, aperture: $aperture, shutterSpeed: $shutterSpeed, iso: $iso, latitude: $latitude, longitude: $longitude, hash: $hash, processingStatus: $processingStatus, createdAt: $createdAt, updatedAt: $updatedAt, userID: $userID)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaDetailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.uuid, uuid) || other.uuid == uuid) &&
            (identical(other.filename, filename) ||
                other.filename == filename) &&
            (identical(other.originalFilename, originalFilename) ||
                other.originalFilename == originalFilename) &&
            (identical(other.itemType, itemType) ||
                other.itemType == itemType) &&
            (identical(other.mimeType, mimeType) ||
                other.mimeType == mimeType) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.mediaTakenAt, mediaTakenAt) ||
                other.mediaTakenAt == mediaTakenAt) &&
            (identical(other.cameraMake, cameraMake) ||
                other.cameraMake == cameraMake) &&
            (identical(other.cameraModel, cameraModel) ||
                other.cameraModel == cameraModel) &&
            (identical(other.aperture, aperture) ||
                other.aperture == aperture) &&
            (identical(other.shutterSpeed, shutterSpeed) ||
                other.shutterSpeed == shutterSpeed) &&
            (identical(other.iso, iso) || other.iso == iso) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.processingStatus, processingStatus) ||
                other.processingStatus == processingStatus) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.userID, userID) || other.userID == userID));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        uuid,
        filename,
        originalFilename,
        itemType,
        mimeType,
        fileSize,
        width,
        height,
        mediaTakenAt,
        cameraMake,
        cameraModel,
        aperture,
        shutterSpeed,
        iso,
        latitude,
        longitude,
        hash,
        processingStatus,
        createdAt,
        updatedAt,
        userID
      ]);

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaDetailImplCopyWith<_$MediaDetailImpl> get copyWith =>
      __$$MediaDetailImplCopyWithImpl<_$MediaDetailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaDetailImplToJson(
      this,
    );
  }
}

abstract class _MediaDetail implements MediaDetail {
  const factory _MediaDetail(
      {required final int id,
      required final String uuid,
      required final String filename,
      required final String originalFilename,
      required final MediaType itemType,
      required final String mimeType,
      required final int fileSize,
      final int? width,
      final int? height,
      final String? mediaTakenAt,
      final String? cameraMake,
      final String? cameraModel,
      final String? aperture,
      final String? shutterSpeed,
      final int? iso,
      final double? latitude,
      final double? longitude,
      required final String hash,
      required final ProcessingStatus processingStatus,
      required final String createdAt,
      required final String updatedAt,
      required final int userID}) = _$MediaDetailImpl;

  factory _MediaDetail.fromJson(Map<String, dynamic> json) =
      _$MediaDetailImpl.fromJson;

  @override
  int get id;
  @override
  String get uuid;
  @override
  String get filename;
  @override
  String get originalFilename;
  @override
  MediaType get itemType;
  @override
  String get mimeType;
  @override
  int get fileSize;
  @override
  int? get width;
  @override
  int? get height;
  @override
  String? get mediaTakenAt;
  @override
  String? get cameraMake;
  @override
  String? get cameraModel;
  @override
  String? get aperture;
  @override
  String? get shutterSpeed;
  @override
  int? get iso;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  String get hash;
  @override
  ProcessingStatus get processingStatus;
  @override
  String get createdAt;
  @override
  String get updatedAt;
  @override
  int get userID;

  /// Create a copy of MediaDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaDetailImplCopyWith<_$MediaDetailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

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

  /// Serializes this MediaResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of MediaResponse
  /// with the given fields replaced by the non-null parameter values.
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

  /// Create a copy of MediaResponse
  /// with the given fields replaced by the non-null parameter values.
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

  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of MediaResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of MediaResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaResponseImplCopyWith<_$MediaResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MediaListResponse _$MediaListResponseFromJson(Map<String, dynamic> json) {
  return _MediaListResponse.fromJson(json);
}

/// @nodoc
mixin _$MediaListResponse {
  List<MediaResponse> get data => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get limit => throw _privateConstructorUsedError;

  /// Serializes this MediaListResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaListResponseCopyWith<MediaListResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaListResponseCopyWith<$Res> {
  factory $MediaListResponseCopyWith(
          MediaListResponse value, $Res Function(MediaListResponse) then) =
      _$MediaListResponseCopyWithImpl<$Res, MediaListResponse>;
  @useResult
  $Res call({List<MediaResponse> data, int total, int page, int limit});
}

/// @nodoc
class _$MediaListResponseCopyWithImpl<$Res, $Val extends MediaListResponse>
    implements $MediaListResponseCopyWith<$Res> {
  _$MediaListResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_value.copyWith(
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as List<MediaResponse>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MediaListResponseImplCopyWith<$Res>
    implements $MediaListResponseCopyWith<$Res> {
  factory _$$MediaListResponseImplCopyWith(_$MediaListResponseImpl value,
          $Res Function(_$MediaListResponseImpl) then) =
      __$$MediaListResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MediaResponse> data, int total, int page, int limit});
}

/// @nodoc
class __$$MediaListResponseImplCopyWithImpl<$Res>
    extends _$MediaListResponseCopyWithImpl<$Res, _$MediaListResponseImpl>
    implements _$$MediaListResponseImplCopyWith<$Res> {
  __$$MediaListResponseImplCopyWithImpl(_$MediaListResponseImpl _value,
      $Res Function(_$MediaListResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of MediaListResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
    Object? total = null,
    Object? page = null,
    Object? limit = null,
  }) {
    return _then(_$MediaListResponseImpl(
      data: null == data
          ? _value._data
          : data // ignore: cast_nullable_to_non_nullable
              as List<MediaResponse>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      limit: null == limit
          ? _value.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaListResponseImpl implements _MediaListResponse {
  const _$MediaListResponseImpl(
      {required final List<MediaResponse> data,
      required this.total,
      required this.page,
      required this.limit})
      : _data = data;

  factory _$MediaListResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaListResponseImplFromJson(json);

  final List<MediaResponse> _data;
  @override
  List<MediaResponse> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  final int total;
  @override
  final int page;
  @override
  final int limit;

  @override
  String toString() {
    return 'MediaListResponse(data: $data, total: $total, page: $page, limit: $limit)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaListResponseImpl &&
            const DeepCollectionEquality().equals(other._data, _data) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_data), total, page, limit);

  /// Create a copy of MediaListResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaListResponseImplCopyWith<_$MediaListResponseImpl> get copyWith =>
      __$$MediaListResponseImplCopyWithImpl<_$MediaListResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaListResponseImplToJson(
      this,
    );
  }
}

abstract class _MediaListResponse implements MediaListResponse {
  const factory _MediaListResponse(
      {required final List<MediaResponse> data,
      required final int total,
      required final int page,
      required final int limit}) = _$MediaListResponseImpl;

  factory _MediaListResponse.fromJson(Map<String, dynamic> json) =
      _$MediaListResponseImpl.fromJson;

  @override
  List<MediaResponse> get data;
  @override
  int get total;
  @override
  int get page;
  @override
  int get limit;

  /// Create a copy of MediaListResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaListResponseImplCopyWith<_$MediaListResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CheckHashesRequest {
  List<String> get hashes => throw _privateConstructorUsedError;

  /// Create a copy of CheckHashesRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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

  /// Create a copy of CheckHashesRequest
  /// with the given fields replaced by the non-null parameter values.
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

  /// Create a copy of CheckHashesRequest
  /// with the given fields replaced by the non-null parameter values.
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

class _$CheckHashesRequestImpl implements _CheckHashesRequest {
  const _$CheckHashesRequestImpl({required final List<String> hashes})
      : _hashes = hashes;

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

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_hashes));

  /// Create a copy of CheckHashesRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CheckHashesRequestImplCopyWith<_$CheckHashesRequestImpl> get copyWith =>
      __$$CheckHashesRequestImplCopyWithImpl<_$CheckHashesRequestImpl>(
          this, _$identity);
}

abstract class _CheckHashesRequest implements CheckHashesRequest {
  const factory _CheckHashesRequest({required final List<String> hashes}) =
      _$CheckHashesRequestImpl;

  @override
  List<String> get hashes;

  /// Create a copy of CheckHashesRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckHashesRequestImplCopyWith<_$CheckHashesRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CheckHashesResponse _$CheckHashesResponseFromJson(Map<String, dynamic> json) {
  return _CheckHashesResponse.fromJson(json);
}

/// @nodoc
mixin _$CheckHashesResponse {
  List<String> get existingHashes => throw _privateConstructorUsedError;

  /// Serializes this CheckHashesResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CheckHashesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CheckHashesResponseCopyWith<CheckHashesResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CheckHashesResponseCopyWith<$Res> {
  factory $CheckHashesResponseCopyWith(
          CheckHashesResponse value, $Res Function(CheckHashesResponse) then) =
      _$CheckHashesResponseCopyWithImpl<$Res, CheckHashesResponse>;
  @useResult
  $Res call({List<String> existingHashes});
}

/// @nodoc
class _$CheckHashesResponseCopyWithImpl<$Res, $Val extends CheckHashesResponse>
    implements $CheckHashesResponseCopyWith<$Res> {
  _$CheckHashesResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CheckHashesResponse
  /// with the given fields replaced by the non-null parameter values.
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
  $Res call({List<String> existingHashes});
}

/// @nodoc
class __$$CheckHashesResponseImplCopyWithImpl<$Res>
    extends _$CheckHashesResponseCopyWithImpl<$Res, _$CheckHashesResponseImpl>
    implements _$$CheckHashesResponseImplCopyWith<$Res> {
  __$$CheckHashesResponseImplCopyWithImpl(_$CheckHashesResponseImpl _value,
      $Res Function(_$CheckHashesResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of CheckHashesResponse
  /// with the given fields replaced by the non-null parameter values.
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
  const _$CheckHashesResponseImpl({required final List<String> existingHashes})
      : _existingHashes = existingHashes;

  factory _$CheckHashesResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$CheckHashesResponseImplFromJson(json);

  final List<String> _existingHashes;
  @override
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, const DeepCollectionEquality().hash(_existingHashes));

  /// Create a copy of CheckHashesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
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
      {required final List<String> existingHashes}) = _$CheckHashesResponseImpl;

  factory _CheckHashesResponse.fromJson(Map<String, dynamic> json) =
      _$CheckHashesResponseImpl.fromJson;

  @override
  List<String> get existingHashes;

  /// Create a copy of CheckHashesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CheckHashesResponseImplCopyWith<_$CheckHashesResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MediaChangesResponse _$MediaChangesResponseFromJson(Map<String, dynamic> json) {
  return _MediaChangesResponse.fromJson(json);
}

/// @nodoc
mixin _$MediaChangesResponse {
  List<MediaResponse> get created => throw _privateConstructorUsedError;
  List<MediaResponse> get updated => throw _privateConstructorUsedError;
  List<String> get deleted => throw _privateConstructorUsedError;

  /// Serializes this MediaChangesResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaChangesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaChangesResponseCopyWith<MediaChangesResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaChangesResponseCopyWith<$Res> {
  factory $MediaChangesResponseCopyWith(MediaChangesResponse value,
          $Res Function(MediaChangesResponse) then) =
      _$MediaChangesResponseCopyWithImpl<$Res, MediaChangesResponse>;
  @useResult
  $Res call(
      {List<MediaResponse> created,
      List<MediaResponse> updated,
      List<String> deleted});
}

/// @nodoc
class _$MediaChangesResponseCopyWithImpl<$Res,
        $Val extends MediaChangesResponse>
    implements $MediaChangesResponseCopyWith<$Res> {
  _$MediaChangesResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaChangesResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? created = null,
    Object? updated = null,
    Object? deleted = null,
  }) {
    return _then(_value.copyWith(
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as List<MediaResponse>,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as List<MediaResponse>,
      deleted: null == deleted
          ? _value.deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MediaChangesResponseImplCopyWith<$Res>
    implements $MediaChangesResponseCopyWith<$Res> {
  factory _$$MediaChangesResponseImplCopyWith(_$MediaChangesResponseImpl value,
          $Res Function(_$MediaChangesResponseImpl) then) =
      __$$MediaChangesResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<MediaResponse> created,
      List<MediaResponse> updated,
      List<String> deleted});
}

/// @nodoc
class __$$MediaChangesResponseImplCopyWithImpl<$Res>
    extends _$MediaChangesResponseCopyWithImpl<$Res, _$MediaChangesResponseImpl>
    implements _$$MediaChangesResponseImplCopyWith<$Res> {
  __$$MediaChangesResponseImplCopyWithImpl(_$MediaChangesResponseImpl _value,
      $Res Function(_$MediaChangesResponseImpl) _then)
      : super(_value, _then);

  /// Create a copy of MediaChangesResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? created = null,
    Object? updated = null,
    Object? deleted = null,
  }) {
    return _then(_$MediaChangesResponseImpl(
      created: null == created
          ? _value._created
          : created // ignore: cast_nullable_to_non_nullable
              as List<MediaResponse>,
      updated: null == updated
          ? _value._updated
          : updated // ignore: cast_nullable_to_non_nullable
              as List<MediaResponse>,
      deleted: null == deleted
          ? _value._deleted
          : deleted // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaChangesResponseImpl implements _MediaChangesResponse {
  const _$MediaChangesResponseImpl(
      {required final List<MediaResponse> created,
      required final List<MediaResponse> updated,
      required final List<String> deleted})
      : _created = created,
        _updated = updated,
        _deleted = deleted;

  factory _$MediaChangesResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaChangesResponseImplFromJson(json);

  final List<MediaResponse> _created;
  @override
  List<MediaResponse> get created {
    if (_created is EqualUnmodifiableListView) return _created;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_created);
  }

  final List<MediaResponse> _updated;
  @override
  List<MediaResponse> get updated {
    if (_updated is EqualUnmodifiableListView) return _updated;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_updated);
  }

  final List<String> _deleted;
  @override
  List<String> get deleted {
    if (_deleted is EqualUnmodifiableListView) return _deleted;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deleted);
  }

  @override
  String toString() {
    return 'MediaChangesResponse(created: $created, updated: $updated, deleted: $deleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaChangesResponseImpl &&
            const DeepCollectionEquality().equals(other._created, _created) &&
            const DeepCollectionEquality().equals(other._updated, _updated) &&
            const DeepCollectionEquality().equals(other._deleted, _deleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_created),
      const DeepCollectionEquality().hash(_updated),
      const DeepCollectionEquality().hash(_deleted));

  /// Create a copy of MediaChangesResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaChangesResponseImplCopyWith<_$MediaChangesResponseImpl>
      get copyWith =>
          __$$MediaChangesResponseImplCopyWithImpl<_$MediaChangesResponseImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaChangesResponseImplToJson(
      this,
    );
  }
}

abstract class _MediaChangesResponse implements MediaChangesResponse {
  const factory _MediaChangesResponse(
      {required final List<MediaResponse> created,
      required final List<MediaResponse> updated,
      required final List<String> deleted}) = _$MediaChangesResponseImpl;

  factory _MediaChangesResponse.fromJson(Map<String, dynamic> json) =
      _$MediaChangesResponseImpl.fromJson;

  @override
  List<MediaResponse> get created;
  @override
  List<MediaResponse> get updated;
  @override
  List<String> get deleted;

  /// Create a copy of MediaChangesResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaChangesResponseImplCopyWith<_$MediaChangesResponseImpl>
      get copyWith => throw _privateConstructorUsedError;
}
