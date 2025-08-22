// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_album_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UnifiedAlbumEntity {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get assetCount => throw _privateConstructorUsedError;
  AlbumSource get source => throw _privateConstructorUsedError;
  String? get thumbnailId => throw _privateConstructorUsedError;

  /// Create a copy of UnifiedAlbumEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnifiedAlbumEntityCopyWith<UnifiedAlbumEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedAlbumEntityCopyWith<$Res> {
  factory $UnifiedAlbumEntityCopyWith(
          UnifiedAlbumEntity value, $Res Function(UnifiedAlbumEntity) then) =
      _$UnifiedAlbumEntityCopyWithImpl<$Res, UnifiedAlbumEntity>;
  @useResult
  $Res call(
      {String id,
      String name,
      int assetCount,
      AlbumSource source,
      String? thumbnailId});
}

/// @nodoc
class _$UnifiedAlbumEntityCopyWithImpl<$Res, $Val extends UnifiedAlbumEntity>
    implements $UnifiedAlbumEntityCopyWith<$Res> {
  _$UnifiedAlbumEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnifiedAlbumEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? assetCount = null,
    Object? source = null,
    Object? thumbnailId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      assetCount: null == assetCount
          ? _value.assetCount
          : assetCount // ignore: cast_nullable_to_non_nullable
              as int,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as AlbumSource,
      thumbnailId: freezed == thumbnailId
          ? _value.thumbnailId
          : thumbnailId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UnifiedAlbumEntityImplCopyWith<$Res>
    implements $UnifiedAlbumEntityCopyWith<$Res> {
  factory _$$UnifiedAlbumEntityImplCopyWith(_$UnifiedAlbumEntityImpl value,
          $Res Function(_$UnifiedAlbumEntityImpl) then) =
      __$$UnifiedAlbumEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      int assetCount,
      AlbumSource source,
      String? thumbnailId});
}

/// @nodoc
class __$$UnifiedAlbumEntityImplCopyWithImpl<$Res>
    extends _$UnifiedAlbumEntityCopyWithImpl<$Res, _$UnifiedAlbumEntityImpl>
    implements _$$UnifiedAlbumEntityImplCopyWith<$Res> {
  __$$UnifiedAlbumEntityImplCopyWithImpl(_$UnifiedAlbumEntityImpl _value,
      $Res Function(_$UnifiedAlbumEntityImpl) _then)
      : super(_value, _then);

  /// Create a copy of UnifiedAlbumEntity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? assetCount = null,
    Object? source = null,
    Object? thumbnailId = freezed,
  }) {
    return _then(_$UnifiedAlbumEntityImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      assetCount: null == assetCount
          ? _value.assetCount
          : assetCount // ignore: cast_nullable_to_non_nullable
              as int,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as AlbumSource,
      thumbnailId: freezed == thumbnailId
          ? _value.thumbnailId
          : thumbnailId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UnifiedAlbumEntityImpl implements _UnifiedAlbumEntity {
  const _$UnifiedAlbumEntityImpl(
      {required this.id,
      required this.name,
      required this.assetCount,
      required this.source,
      this.thumbnailId});

  @override
  final String id;
  @override
  final String name;
  @override
  final int assetCount;
  @override
  final AlbumSource source;
  @override
  final String? thumbnailId;

  @override
  String toString() {
    return 'UnifiedAlbumEntity(id: $id, name: $name, assetCount: $assetCount, source: $source, thumbnailId: $thumbnailId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedAlbumEntityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.assetCount, assetCount) ||
                other.assetCount == assetCount) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.thumbnailId, thumbnailId) ||
                other.thumbnailId == thumbnailId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, assetCount, source, thumbnailId);

  /// Create a copy of UnifiedAlbumEntity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedAlbumEntityImplCopyWith<_$UnifiedAlbumEntityImpl> get copyWith =>
      __$$UnifiedAlbumEntityImplCopyWithImpl<_$UnifiedAlbumEntityImpl>(
          this, _$identity);
}

abstract class _UnifiedAlbumEntity implements UnifiedAlbumEntity {
  const factory _UnifiedAlbumEntity(
      {required final String id,
      required final String name,
      required final int assetCount,
      required final AlbumSource source,
      final String? thumbnailId}) = _$UnifiedAlbumEntityImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  int get assetCount;
  @override
  AlbumSource get source;
  @override
  String? get thumbnailId;

  /// Create a copy of UnifiedAlbumEntity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnifiedAlbumEntityImplCopyWith<_$UnifiedAlbumEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
