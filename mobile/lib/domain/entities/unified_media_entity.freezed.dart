// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_media_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UnifiedMediaEntity {
  int get id => throw _privateConstructorUsedError;
  String? get localId => throw _privateConstructorUsedError;
  String? get cloudUuid => throw _privateConstructorUsedError;
  String? get thumbnailUrl => throw _privateConstructorUsedError;
  SyncStatus get syncStatus => throw _privateConstructorUsedError;
  MediaType get assetType => throw _privateConstructorUsedError;
  String? get filePath => throw _privateConstructorUsedError;
  String? get fileName => throw _privateConstructorUsedError;
  bool get isRAW => throw _privateConstructorUsedError;
  int? get width => throw _privateConstructorUsedError;
  int? get height => throw _privateConstructorUsedError;
  int? get durationSec => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get mediaTakenAt => throw _privateConstructorUsedError; // 媒体拍摄时间（非空）
  AssetEntity? get assetEntity => throw _privateConstructorUsedError;
  LifecycleState? get lifecycleState => throw _privateConstructorUsedError;
  String? get trashPath => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $UnifiedMediaEntityCopyWith<UnifiedMediaEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedMediaEntityCopyWith<$Res> {
  factory $UnifiedMediaEntityCopyWith(
          UnifiedMediaEntity value, $Res Function(UnifiedMediaEntity) then) =
      _$UnifiedMediaEntityCopyWithImpl<$Res, UnifiedMediaEntity>;
  @useResult
  $Res call(
      {int id,
      String? localId,
      String? cloudUuid,
      String? thumbnailUrl,
      SyncStatus syncStatus,
      MediaType assetType,
      String? filePath,
      String? fileName,
      bool isRAW,
      int? width,
      int? height,
      int? durationSec,
      DateTime createdAt,
      DateTime mediaTakenAt,
      AssetEntity? assetEntity,
      LifecycleState? lifecycleState,
      String? trashPath});
}

/// @nodoc
class _$UnifiedMediaEntityCopyWithImpl<$Res, $Val extends UnifiedMediaEntity>
    implements $UnifiedMediaEntityCopyWith<$Res> {
  _$UnifiedMediaEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? localId = freezed,
    Object? cloudUuid = freezed,
    Object? thumbnailUrl = freezed,
    Object? syncStatus = null,
    Object? assetType = null,
    Object? filePath = freezed,
    Object? fileName = freezed,
    Object? isRAW = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? durationSec = freezed,
    Object? createdAt = null,
    Object? mediaTakenAt = null,
    Object? assetEntity = freezed,
    Object? lifecycleState = freezed,
    Object? trashPath = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      localId: freezed == localId
          ? _value.localId
          : localId // ignore: cast_nullable_to_non_nullable
              as String?,
      cloudUuid: freezed == cloudUuid
          ? _value.cloudUuid
          : cloudUuid // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as MediaType,
      filePath: freezed == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      isRAW: null == isRAW
          ? _value.isRAW
          : isRAW // ignore: cast_nullable_to_non_nullable
              as bool,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      durationSec: freezed == durationSec
          ? _value.durationSec
          : durationSec // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mediaTakenAt: null == mediaTakenAt
          ? _value.mediaTakenAt
          : mediaTakenAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      assetEntity: freezed == assetEntity
          ? _value.assetEntity
          : assetEntity // ignore: cast_nullable_to_non_nullable
              as AssetEntity?,
      lifecycleState: freezed == lifecycleState
          ? _value.lifecycleState
          : lifecycleState // ignore: cast_nullable_to_non_nullable
              as LifecycleState?,
      trashPath: freezed == trashPath
          ? _value.trashPath
          : trashPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UnifiedMediaEntityImplCopyWith<$Res>
    implements $UnifiedMediaEntityCopyWith<$Res> {
  factory _$$UnifiedMediaEntityImplCopyWith(_$UnifiedMediaEntityImpl value,
          $Res Function(_$UnifiedMediaEntityImpl) then) =
      __$$UnifiedMediaEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String? localId,
      String? cloudUuid,
      String? thumbnailUrl,
      SyncStatus syncStatus,
      MediaType assetType,
      String? filePath,
      String? fileName,
      bool isRAW,
      int? width,
      int? height,
      int? durationSec,
      DateTime createdAt,
      DateTime mediaTakenAt,
      AssetEntity? assetEntity,
      LifecycleState? lifecycleState,
      String? trashPath});
}

/// @nodoc
class __$$UnifiedMediaEntityImplCopyWithImpl<$Res>
    extends _$UnifiedMediaEntityCopyWithImpl<$Res, _$UnifiedMediaEntityImpl>
    implements _$$UnifiedMediaEntityImplCopyWith<$Res> {
  __$$UnifiedMediaEntityImplCopyWithImpl(_$UnifiedMediaEntityImpl _value,
      $Res Function(_$UnifiedMediaEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? localId = freezed,
    Object? cloudUuid = freezed,
    Object? thumbnailUrl = freezed,
    Object? syncStatus = null,
    Object? assetType = null,
    Object? filePath = freezed,
    Object? fileName = freezed,
    Object? isRAW = null,
    Object? width = freezed,
    Object? height = freezed,
    Object? durationSec = freezed,
    Object? createdAt = null,
    Object? mediaTakenAt = null,
    Object? assetEntity = freezed,
    Object? lifecycleState = freezed,
    Object? trashPath = freezed,
  }) {
    return _then(_$UnifiedMediaEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      localId: freezed == localId
          ? _value.localId
          : localId // ignore: cast_nullable_to_non_nullable
              as String?,
      cloudUuid: freezed == cloudUuid
          ? _value.cloudUuid
          : cloudUuid // ignore: cast_nullable_to_non_nullable
              as String?,
      thumbnailUrl: freezed == thumbnailUrl
          ? _value.thumbnailUrl
          : thumbnailUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SyncStatus,
      assetType: null == assetType
          ? _value.assetType
          : assetType // ignore: cast_nullable_to_non_nullable
              as MediaType,
      filePath: freezed == filePath
          ? _value.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String?,
      fileName: freezed == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String?,
      isRAW: null == isRAW
          ? _value.isRAW
          : isRAW // ignore: cast_nullable_to_non_nullable
              as bool,
      width: freezed == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int?,
      height: freezed == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int?,
      durationSec: freezed == durationSec
          ? _value.durationSec
          : durationSec // ignore: cast_nullable_to_non_nullable
              as int?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mediaTakenAt: null == mediaTakenAt
          ? _value.mediaTakenAt
          : mediaTakenAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      assetEntity: freezed == assetEntity
          ? _value.assetEntity
          : assetEntity // ignore: cast_nullable_to_non_nullable
              as AssetEntity?,
      lifecycleState: freezed == lifecycleState
          ? _value.lifecycleState
          : lifecycleState // ignore: cast_nullable_to_non_nullable
              as LifecycleState?,
      trashPath: freezed == trashPath
          ? _value.trashPath
          : trashPath // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UnifiedMediaEntityImpl extends _UnifiedMediaEntity {
  const _$UnifiedMediaEntityImpl(
      {required this.id,
      this.localId,
      this.cloudUuid,
      this.thumbnailUrl,
      required this.syncStatus,
      required this.assetType,
      this.filePath,
      this.fileName,
      this.isRAW = false,
      this.width,
      this.height,
      this.durationSec,
      required this.createdAt,
      required this.mediaTakenAt,
      this.assetEntity = null,
      this.lifecycleState,
      this.trashPath})
      : super._();

  @override
  final int id;
  @override
  final String? localId;
  @override
  final String? cloudUuid;
  @override
  final String? thumbnailUrl;
  @override
  final SyncStatus syncStatus;
  @override
  final MediaType assetType;
  @override
  final String? filePath;
  @override
  final String? fileName;
  @override
  @JsonKey()
  final bool isRAW;
  @override
  final int? width;
  @override
  final int? height;
  @override
  final int? durationSec;
  @override
  final DateTime createdAt;
  @override
  final DateTime mediaTakenAt;
// 媒体拍摄时间（非空）
  @override
  @JsonKey()
  final AssetEntity? assetEntity;
  @override
  final LifecycleState? lifecycleState;
  @override
  final String? trashPath;

  @override
  String toString() {
    return 'UnifiedMediaEntity(id: $id, localId: $localId, cloudUuid: $cloudUuid, thumbnailUrl: $thumbnailUrl, syncStatus: $syncStatus, assetType: $assetType, filePath: $filePath, fileName: $fileName, isRAW: $isRAW, width: $width, height: $height, durationSec: $durationSec, createdAt: $createdAt, mediaTakenAt: $mediaTakenAt, assetEntity: $assetEntity, lifecycleState: $lifecycleState, trashPath: $trashPath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedMediaEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.localId, localId) || other.localId == localId) &&
            (identical(other.cloudUuid, cloudUuid) ||
                other.cloudUuid == cloudUuid) &&
            (identical(other.thumbnailUrl, thumbnailUrl) ||
                other.thumbnailUrl == thumbnailUrl) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus) &&
            (identical(other.assetType, assetType) ||
                other.assetType == assetType) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.isRAW, isRAW) || other.isRAW == isRAW) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.durationSec, durationSec) ||
                other.durationSec == durationSec) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.mediaTakenAt, mediaTakenAt) ||
                other.mediaTakenAt == mediaTakenAt) &&
            (identical(other.assetEntity, assetEntity) ||
                other.assetEntity == assetEntity) &&
            (identical(other.lifecycleState, lifecycleState) ||
                other.lifecycleState == lifecycleState) &&
            (identical(other.trashPath, trashPath) ||
                other.trashPath == trashPath));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      localId,
      cloudUuid,
      thumbnailUrl,
      syncStatus,
      assetType,
      filePath,
      fileName,
      isRAW,
      width,
      height,
      durationSec,
      createdAt,
      mediaTakenAt,
      assetEntity,
      lifecycleState,
      trashPath);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedMediaEntityImplCopyWith<_$UnifiedMediaEntityImpl> get copyWith =>
      __$$UnifiedMediaEntityImplCopyWithImpl<_$UnifiedMediaEntityImpl>(
          this, _$identity);
}

abstract class _UnifiedMediaEntity extends UnifiedMediaEntity {
  const factory _UnifiedMediaEntity(
      {required final int id,
      final String? localId,
      final String? cloudUuid,
      final String? thumbnailUrl,
      required final SyncStatus syncStatus,
      required final MediaType assetType,
      final String? filePath,
      final String? fileName,
      final bool isRAW,
      final int? width,
      final int? height,
      final int? durationSec,
      required final DateTime createdAt,
      required final DateTime mediaTakenAt,
      final AssetEntity? assetEntity,
      final LifecycleState? lifecycleState,
      final String? trashPath}) = _$UnifiedMediaEntityImpl;
  const _UnifiedMediaEntity._() : super._();

  @override
  int get id;
  @override
  String? get localId;
  @override
  String? get cloudUuid;
  @override
  String? get thumbnailUrl;
  @override
  SyncStatus get syncStatus;
  @override
  MediaType get assetType;
  @override
  String? get filePath;
  @override
  String? get fileName;
  @override
  bool get isRAW;
  @override
  int? get width;
  @override
  int? get height;
  @override
  int? get durationSec;
  @override
  DateTime get createdAt;
  @override
  DateTime get mediaTakenAt;
  @override // 媒体拍摄时间（非空）
  AssetEntity? get assetEntity;
  @override
  LifecycleState? get lifecycleState;
  @override
  String? get trashPath;
  @override
  @JsonKey(ignore: true)
  _$$UnifiedMediaEntityImplCopyWith<_$UnifiedMediaEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
