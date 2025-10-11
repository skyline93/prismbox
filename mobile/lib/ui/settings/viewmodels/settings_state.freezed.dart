// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SettingsState {
// Default to 3 for initial UI display before loading
  int get maxConcurrentUploads => throw _privateConstructorUsedError;
  int get maxConcurrentDownloads => throw _privateConstructorUsedError;
  bool get isAutoBackupEnabled => throw _privateConstructorUsedError;
  BackupFrequency get backupFrequency => throw _privateConstructorUsedError;
  bool get isBackupOnWifiOnly =>
      throw _privateConstructorUsedError; // 备份时间段的开始日期，可为空
  DateTime? get backupStartDate =>
      throw _privateConstructorUsedError; // 备份时间段的结束日期，可为空
  DateTime? get backupEndDate =>
      throw _privateConstructorUsedError; // Indicates if settings are being loaded from the database
  bool get isLoading => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SettingsStateCopyWith<SettingsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SettingsStateCopyWith<$Res> {
  factory $SettingsStateCopyWith(
          SettingsState value, $Res Function(SettingsState) then) =
      _$SettingsStateCopyWithImpl<$Res, SettingsState>;
  @useResult
  $Res call(
      {int maxConcurrentUploads,
      int maxConcurrentDownloads,
      bool isAutoBackupEnabled,
      BackupFrequency backupFrequency,
      bool isBackupOnWifiOnly,
      DateTime? backupStartDate,
      DateTime? backupEndDate,
      bool isLoading});
}

/// @nodoc
class _$SettingsStateCopyWithImpl<$Res, $Val extends SettingsState>
    implements $SettingsStateCopyWith<$Res> {
  _$SettingsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxConcurrentUploads = null,
    Object? maxConcurrentDownloads = null,
    Object? isAutoBackupEnabled = null,
    Object? backupFrequency = null,
    Object? isBackupOnWifiOnly = null,
    Object? backupStartDate = freezed,
    Object? backupEndDate = freezed,
    Object? isLoading = null,
  }) {
    return _then(_value.copyWith(
      maxConcurrentUploads: null == maxConcurrentUploads
          ? _value.maxConcurrentUploads
          : maxConcurrentUploads // ignore: cast_nullable_to_non_nullable
              as int,
      maxConcurrentDownloads: null == maxConcurrentDownloads
          ? _value.maxConcurrentDownloads
          : maxConcurrentDownloads // ignore: cast_nullable_to_non_nullable
              as int,
      isAutoBackupEnabled: null == isAutoBackupEnabled
          ? _value.isAutoBackupEnabled
          : isAutoBackupEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      backupFrequency: null == backupFrequency
          ? _value.backupFrequency
          : backupFrequency // ignore: cast_nullable_to_non_nullable
              as BackupFrequency,
      isBackupOnWifiOnly: null == isBackupOnWifiOnly
          ? _value.isBackupOnWifiOnly
          : isBackupOnWifiOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      backupStartDate: freezed == backupStartDate
          ? _value.backupStartDate
          : backupStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      backupEndDate: freezed == backupEndDate
          ? _value.backupEndDate
          : backupEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SettingsStateImplCopyWith<$Res>
    implements $SettingsStateCopyWith<$Res> {
  factory _$$SettingsStateImplCopyWith(
          _$SettingsStateImpl value, $Res Function(_$SettingsStateImpl) then) =
      __$$SettingsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int maxConcurrentUploads,
      int maxConcurrentDownloads,
      bool isAutoBackupEnabled,
      BackupFrequency backupFrequency,
      bool isBackupOnWifiOnly,
      DateTime? backupStartDate,
      DateTime? backupEndDate,
      bool isLoading});
}

/// @nodoc
class __$$SettingsStateImplCopyWithImpl<$Res>
    extends _$SettingsStateCopyWithImpl<$Res, _$SettingsStateImpl>
    implements _$$SettingsStateImplCopyWith<$Res> {
  __$$SettingsStateImplCopyWithImpl(
      _$SettingsStateImpl _value, $Res Function(_$SettingsStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxConcurrentUploads = null,
    Object? maxConcurrentDownloads = null,
    Object? isAutoBackupEnabled = null,
    Object? backupFrequency = null,
    Object? isBackupOnWifiOnly = null,
    Object? backupStartDate = freezed,
    Object? backupEndDate = freezed,
    Object? isLoading = null,
  }) {
    return _then(_$SettingsStateImpl(
      maxConcurrentUploads: null == maxConcurrentUploads
          ? _value.maxConcurrentUploads
          : maxConcurrentUploads // ignore: cast_nullable_to_non_nullable
              as int,
      maxConcurrentDownloads: null == maxConcurrentDownloads
          ? _value.maxConcurrentDownloads
          : maxConcurrentDownloads // ignore: cast_nullable_to_non_nullable
              as int,
      isAutoBackupEnabled: null == isAutoBackupEnabled
          ? _value.isAutoBackupEnabled
          : isAutoBackupEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      backupFrequency: null == backupFrequency
          ? _value.backupFrequency
          : backupFrequency // ignore: cast_nullable_to_non_nullable
              as BackupFrequency,
      isBackupOnWifiOnly: null == isBackupOnWifiOnly
          ? _value.isBackupOnWifiOnly
          : isBackupOnWifiOnly // ignore: cast_nullable_to_non_nullable
              as bool,
      backupStartDate: freezed == backupStartDate
          ? _value.backupStartDate
          : backupStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      backupEndDate: freezed == backupEndDate
          ? _value.backupEndDate
          : backupEndDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$SettingsStateImpl implements _SettingsState {
  const _$SettingsStateImpl(
      {this.maxConcurrentUploads = 3,
      this.maxConcurrentDownloads = 3,
      this.isAutoBackupEnabled = false,
      this.backupFrequency = BackupFrequency.daily,
      this.isBackupOnWifiOnly = true,
      this.backupStartDate,
      this.backupEndDate,
      this.isLoading = true});

// Default to 3 for initial UI display before loading
  @override
  @JsonKey()
  final int maxConcurrentUploads;
  @override
  @JsonKey()
  final int maxConcurrentDownloads;
  @override
  @JsonKey()
  final bool isAutoBackupEnabled;
  @override
  @JsonKey()
  final BackupFrequency backupFrequency;
  @override
  @JsonKey()
  final bool isBackupOnWifiOnly;
// 备份时间段的开始日期，可为空
  @override
  final DateTime? backupStartDate;
// 备份时间段的结束日期，可为空
  @override
  final DateTime? backupEndDate;
// Indicates if settings are being loaded from the database
  @override
  @JsonKey()
  final bool isLoading;

  @override
  String toString() {
    return 'SettingsState(maxConcurrentUploads: $maxConcurrentUploads, maxConcurrentDownloads: $maxConcurrentDownloads, isAutoBackupEnabled: $isAutoBackupEnabled, backupFrequency: $backupFrequency, isBackupOnWifiOnly: $isBackupOnWifiOnly, backupStartDate: $backupStartDate, backupEndDate: $backupEndDate, isLoading: $isLoading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SettingsStateImpl &&
            (identical(other.maxConcurrentUploads, maxConcurrentUploads) ||
                other.maxConcurrentUploads == maxConcurrentUploads) &&
            (identical(other.maxConcurrentDownloads, maxConcurrentDownloads) ||
                other.maxConcurrentDownloads == maxConcurrentDownloads) &&
            (identical(other.isAutoBackupEnabled, isAutoBackupEnabled) ||
                other.isAutoBackupEnabled == isAutoBackupEnabled) &&
            (identical(other.backupFrequency, backupFrequency) ||
                other.backupFrequency == backupFrequency) &&
            (identical(other.isBackupOnWifiOnly, isBackupOnWifiOnly) ||
                other.isBackupOnWifiOnly == isBackupOnWifiOnly) &&
            (identical(other.backupStartDate, backupStartDate) ||
                other.backupStartDate == backupStartDate) &&
            (identical(other.backupEndDate, backupEndDate) ||
                other.backupEndDate == backupEndDate) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      maxConcurrentUploads,
      maxConcurrentDownloads,
      isAutoBackupEnabled,
      backupFrequency,
      isBackupOnWifiOnly,
      backupStartDate,
      backupEndDate,
      isLoading);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SettingsStateImplCopyWith<_$SettingsStateImpl> get copyWith =>
      __$$SettingsStateImplCopyWithImpl<_$SettingsStateImpl>(this, _$identity);
}

abstract class _SettingsState implements SettingsState {
  const factory _SettingsState(
      {final int maxConcurrentUploads,
      final int maxConcurrentDownloads,
      final bool isAutoBackupEnabled,
      final BackupFrequency backupFrequency,
      final bool isBackupOnWifiOnly,
      final DateTime? backupStartDate,
      final DateTime? backupEndDate,
      final bool isLoading}) = _$SettingsStateImpl;

  @override // Default to 3 for initial UI display before loading
  int get maxConcurrentUploads;
  @override
  int get maxConcurrentDownloads;
  @override
  bool get isAutoBackupEnabled;
  @override
  BackupFrequency get backupFrequency;
  @override
  bool get isBackupOnWifiOnly;
  @override // 备份时间段的开始日期，可为空
  DateTime? get backupStartDate;
  @override // 备份时间段的结束日期，可为空
  DateTime? get backupEndDate;
  @override // Indicates if settings are being loaded from the database
  bool get isLoading;
  @override
  @JsonKey(ignore: true)
  _$$SettingsStateImplCopyWith<_$SettingsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
