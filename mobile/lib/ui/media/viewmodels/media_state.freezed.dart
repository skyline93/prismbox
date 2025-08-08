// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MediaState {
  bool get isLoading => throw _privateConstructorUsedError;
  List<UnifiedMediaEntity> get media => throw _privateConstructorUsedError;
  bool get isSyncingWithCloud => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  String? get cloudSyncError => throw _privateConstructorUsedError;

  /// Create a copy of MediaState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaStateCopyWith<MediaState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaStateCopyWith<$Res> {
  factory $MediaStateCopyWith(
          MediaState value, $Res Function(MediaState) then) =
      _$MediaStateCopyWithImpl<$Res, MediaState>;
  @useResult
  $Res call(
      {bool isLoading,
      List<UnifiedMediaEntity> media,
      bool isSyncingWithCloud,
      String? error,
      String? cloudSyncError});
}

/// @nodoc
class _$MediaStateCopyWithImpl<$Res, $Val extends MediaState>
    implements $MediaStateCopyWith<$Res> {
  _$MediaStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? media = null,
    Object? isSyncingWithCloud = null,
    Object? error = freezed,
    Object? cloudSyncError = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      media: null == media
          ? _value.media
          : media // ignore: cast_nullable_to_non_nullable
              as List<UnifiedMediaEntity>,
      isSyncingWithCloud: null == isSyncingWithCloud
          ? _value.isSyncingWithCloud
          : isSyncingWithCloud // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      cloudSyncError: freezed == cloudSyncError
          ? _value.cloudSyncError
          : cloudSyncError // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MediaStateImplCopyWith<$Res>
    implements $MediaStateCopyWith<$Res> {
  factory _$$MediaStateImplCopyWith(
          _$MediaStateImpl value, $Res Function(_$MediaStateImpl) then) =
      __$$MediaStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      List<UnifiedMediaEntity> media,
      bool isSyncingWithCloud,
      String? error,
      String? cloudSyncError});
}

/// @nodoc
class __$$MediaStateImplCopyWithImpl<$Res>
    extends _$MediaStateCopyWithImpl<$Res, _$MediaStateImpl>
    implements _$$MediaStateImplCopyWith<$Res> {
  __$$MediaStateImplCopyWithImpl(
      _$MediaStateImpl _value, $Res Function(_$MediaStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of MediaState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? media = null,
    Object? isSyncingWithCloud = null,
    Object? error = freezed,
    Object? cloudSyncError = freezed,
  }) {
    return _then(_$MediaStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      media: null == media
          ? _value._media
          : media // ignore: cast_nullable_to_non_nullable
              as List<UnifiedMediaEntity>,
      isSyncingWithCloud: null == isSyncingWithCloud
          ? _value.isSyncingWithCloud
          : isSyncingWithCloud // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      cloudSyncError: freezed == cloudSyncError
          ? _value.cloudSyncError
          : cloudSyncError // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$MediaStateImpl implements _MediaState {
  const _$MediaStateImpl(
      {required this.isLoading,
      required final List<UnifiedMediaEntity> media,
      required this.isSyncingWithCloud,
      this.error,
      this.cloudSyncError})
      : _media = media;

  @override
  final bool isLoading;
  final List<UnifiedMediaEntity> _media;
  @override
  List<UnifiedMediaEntity> get media {
    if (_media is EqualUnmodifiableListView) return _media;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_media);
  }

  @override
  final bool isSyncingWithCloud;
  @override
  final String? error;
  @override
  final String? cloudSyncError;

  @override
  String toString() {
    return 'MediaState(isLoading: $isLoading, media: $media, isSyncingWithCloud: $isSyncingWithCloud, error: $error, cloudSyncError: $cloudSyncError)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            const DeepCollectionEquality().equals(other._media, _media) &&
            (identical(other.isSyncingWithCloud, isSyncingWithCloud) ||
                other.isSyncingWithCloud == isSyncingWithCloud) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.cloudSyncError, cloudSyncError) ||
                other.cloudSyncError == cloudSyncError));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      const DeepCollectionEquality().hash(_media),
      isSyncingWithCloud,
      error,
      cloudSyncError);

  /// Create a copy of MediaState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaStateImplCopyWith<_$MediaStateImpl> get copyWith =>
      __$$MediaStateImplCopyWithImpl<_$MediaStateImpl>(this, _$identity);
}

abstract class _MediaState implements MediaState {
  const factory _MediaState(
      {required final bool isLoading,
      required final List<UnifiedMediaEntity> media,
      required final bool isSyncingWithCloud,
      final String? error,
      final String? cloudSyncError}) = _$MediaStateImpl;

  @override
  bool get isLoading;
  @override
  List<UnifiedMediaEntity> get media;
  @override
  bool get isSyncingWithCloud;
  @override
  String? get error;
  @override
  String? get cloudSyncError;

  /// Create a copy of MediaState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaStateImplCopyWith<_$MediaStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
