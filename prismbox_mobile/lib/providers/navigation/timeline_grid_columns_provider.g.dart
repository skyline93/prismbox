// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_grid_columns_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timelineGridColumnsHash() =>
    r'2539ed567418f003e7b8a03bdddfd7f7009af880';

/// 时间线网格列数 Provider
/// 支持 2、3、4、5、6 列，默认 4 列
///
/// Copied from [TimelineGridColumns].
@ProviderFor(TimelineGridColumns)
final timelineGridColumnsProvider =
    AutoDisposeNotifierProvider<TimelineGridColumns, int>.internal(
  TimelineGridColumns.new,
  name: r'timelineGridColumnsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timelineGridColumnsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TimelineGridColumns = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
