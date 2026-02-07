// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_grouping_mode_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timelineGroupingModeNotifierHash() =>
    r'82a691c3154809b93b027bd779f065b90a1cc93a';

/// 时间线分组粒度 Provider
///
/// 当前默认按日分组；后续可在设置或时间线页提供切换入口，
/// 通过 [setMode] 切换为按日/月/年。
///
/// Copied from [TimelineGroupingModeNotifier].
@ProviderFor(TimelineGroupingModeNotifier)
final timelineGroupingModeNotifierProvider = AutoDisposeNotifierProvider<
    TimelineGroupingModeNotifier, TimelineGroupingMode>.internal(
  TimelineGroupingModeNotifier.new,
  name: r'timelineGroupingModeNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timelineGroupingModeNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TimelineGroupingModeNotifier
    = AutoDisposeNotifier<TimelineGroupingMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
