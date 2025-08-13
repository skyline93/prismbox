// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_detail_viewmodel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MediaData {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List bytes) bytes,
    required TResult Function(File file) file,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List bytes)? bytes,
    TResult? Function(File file)? file,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List bytes)? bytes,
    TResult Function(File file)? file,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_MediaDataBytes value) bytes,
    required TResult Function(_MediaDataFile value) file,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_MediaDataBytes value)? bytes,
    TResult? Function(_MediaDataFile value)? file,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_MediaDataBytes value)? bytes,
    TResult Function(_MediaDataFile value)? file,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaDataCopyWith<$Res> {
  factory $MediaDataCopyWith(MediaData value, $Res Function(MediaData) then) =
      _$MediaDataCopyWithImpl<$Res, MediaData>;
}

/// @nodoc
class _$MediaDataCopyWithImpl<$Res, $Val extends MediaData>
    implements $MediaDataCopyWith<$Res> {
  _$MediaDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaData
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$MediaDataBytesImplCopyWith<$Res> {
  factory _$$MediaDataBytesImplCopyWith(_$MediaDataBytesImpl value,
          $Res Function(_$MediaDataBytesImpl) then) =
      __$$MediaDataBytesImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Uint8List bytes});
}

/// @nodoc
class __$$MediaDataBytesImplCopyWithImpl<$Res>
    extends _$MediaDataCopyWithImpl<$Res, _$MediaDataBytesImpl>
    implements _$$MediaDataBytesImplCopyWith<$Res> {
  __$$MediaDataBytesImplCopyWithImpl(
      _$MediaDataBytesImpl _value, $Res Function(_$MediaDataBytesImpl) _then)
      : super(_value, _then);

  /// Create a copy of MediaData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bytes = null,
  }) {
    return _then(_$MediaDataBytesImpl(
      null == bytes
          ? _value.bytes
          : bytes // ignore: cast_nullable_to_non_nullable
              as Uint8List,
    ));
  }
}

/// @nodoc

class _$MediaDataBytesImpl
    with DiagnosticableTreeMixin
    implements _MediaDataBytes {
  const _$MediaDataBytesImpl(this.bytes);

  @override
  final Uint8List bytes;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MediaData.bytes(bytes: $bytes)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'MediaData.bytes'))
      ..add(DiagnosticsProperty('bytes', bytes));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaDataBytesImpl &&
            const DeepCollectionEquality().equals(other.bytes, bytes));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(bytes));

  /// Create a copy of MediaData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaDataBytesImplCopyWith<_$MediaDataBytesImpl> get copyWith =>
      __$$MediaDataBytesImplCopyWithImpl<_$MediaDataBytesImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List bytes) bytes,
    required TResult Function(File file) file,
  }) {
    return bytes(this.bytes);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List bytes)? bytes,
    TResult? Function(File file)? file,
  }) {
    return bytes?.call(this.bytes);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List bytes)? bytes,
    TResult Function(File file)? file,
    required TResult orElse(),
  }) {
    if (bytes != null) {
      return bytes(this.bytes);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_MediaDataBytes value) bytes,
    required TResult Function(_MediaDataFile value) file,
  }) {
    return bytes(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_MediaDataBytes value)? bytes,
    TResult? Function(_MediaDataFile value)? file,
  }) {
    return bytes?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_MediaDataBytes value)? bytes,
    TResult Function(_MediaDataFile value)? file,
    required TResult orElse(),
  }) {
    if (bytes != null) {
      return bytes(this);
    }
    return orElse();
  }
}

abstract class _MediaDataBytes implements MediaData {
  const factory _MediaDataBytes(final Uint8List bytes) = _$MediaDataBytesImpl;

  Uint8List get bytes;

  /// Create a copy of MediaData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaDataBytesImplCopyWith<_$MediaDataBytesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$MediaDataFileImplCopyWith<$Res> {
  factory _$$MediaDataFileImplCopyWith(
          _$MediaDataFileImpl value, $Res Function(_$MediaDataFileImpl) then) =
      __$$MediaDataFileImplCopyWithImpl<$Res>;
  @useResult
  $Res call({File file});
}

/// @nodoc
class __$$MediaDataFileImplCopyWithImpl<$Res>
    extends _$MediaDataCopyWithImpl<$Res, _$MediaDataFileImpl>
    implements _$$MediaDataFileImplCopyWith<$Res> {
  __$$MediaDataFileImplCopyWithImpl(
      _$MediaDataFileImpl _value, $Res Function(_$MediaDataFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of MediaData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? file = null,
  }) {
    return _then(_$MediaDataFileImpl(
      null == file
          ? _value.file
          : file // ignore: cast_nullable_to_non_nullable
              as File,
    ));
  }
}

/// @nodoc

class _$MediaDataFileImpl
    with DiagnosticableTreeMixin
    implements _MediaDataFile {
  const _$MediaDataFileImpl(this.file);

  @override
  final File file;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'MediaData.file(file: $file)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'MediaData.file'))
      ..add(DiagnosticsProperty('file', file));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaDataFileImpl &&
            (identical(other.file, file) || other.file == file));
  }

  @override
  int get hashCode => Object.hash(runtimeType, file);

  /// Create a copy of MediaData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaDataFileImplCopyWith<_$MediaDataFileImpl> get copyWith =>
      __$$MediaDataFileImplCopyWithImpl<_$MediaDataFileImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(Uint8List bytes) bytes,
    required TResult Function(File file) file,
  }) {
    return file(this.file);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(Uint8List bytes)? bytes,
    TResult? Function(File file)? file,
  }) {
    return file?.call(this.file);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(Uint8List bytes)? bytes,
    TResult Function(File file)? file,
    required TResult orElse(),
  }) {
    if (file != null) {
      return file(this.file);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_MediaDataBytes value) bytes,
    required TResult Function(_MediaDataFile value) file,
  }) {
    return file(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_MediaDataBytes value)? bytes,
    TResult? Function(_MediaDataFile value)? file,
  }) {
    return file?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_MediaDataBytes value)? bytes,
    TResult Function(_MediaDataFile value)? file,
    required TResult orElse(),
  }) {
    if (file != null) {
      return file(this);
    }
    return orElse();
  }
}

abstract class _MediaDataFile implements MediaData {
  const factory _MediaDataFile(final File file) = _$MediaDataFileImpl;

  File get file;

  /// Create a copy of MediaData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaDataFileImplCopyWith<_$MediaDataFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
