// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_content_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timelineContentFilterConfigProviderHash() =>
    r'947d012a3f77427190b1d00c6fab631f5df1a037';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$TimelineContentFilterConfigProvider
    extends BuildlessAutoDisposeNotifier<TimelineContentFilterConfig> {
  late final String pageId;

  TimelineContentFilterConfig build(
    String pageId,
  );
}

/// 时间线内容过滤配置 Provider
///
/// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
/// 每个页面拥有独立的过滤配置，页面切换时自动清理。
///
/// **页面标识符**：
/// - `'favorite'` - 收藏时间线页面
/// - `'video'` - 视频时间线页面
/// - `'recentlyAdded'` - 最近添加时间线页面
/// - `'main'` - 主时间线页面（照片页面，默认无内容过滤）
/// - `'raw'` - RAW 时间线页面（仅 RAW 照片）
/// - `'live'` - Live Photo 时间线页面（仅 Live 资产）
///
/// Copied from [TimelineContentFilterConfigProvider].
@ProviderFor(TimelineContentFilterConfigProvider)
const timelineContentFilterConfigProviderProvider =
    TimelineContentFilterConfigProviderFamily();

/// 时间线内容过滤配置 Provider
///
/// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
/// 每个页面拥有独立的过滤配置，页面切换时自动清理。
///
/// **页面标识符**：
/// - `'favorite'` - 收藏时间线页面
/// - `'video'` - 视频时间线页面
/// - `'recentlyAdded'` - 最近添加时间线页面
/// - `'main'` - 主时间线页面（照片页面，默认无内容过滤）
/// - `'raw'` - RAW 时间线页面（仅 RAW 照片）
/// - `'live'` - Live Photo 时间线页面（仅 Live 资产）
///
/// Copied from [TimelineContentFilterConfigProvider].
class TimelineContentFilterConfigProviderFamily
    extends Family<TimelineContentFilterConfig> {
  /// 时间线内容过滤配置 Provider
  ///
  /// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
  /// 每个页面拥有独立的过滤配置，页面切换时自动清理。
  ///
  /// **页面标识符**：
  /// - `'favorite'` - 收藏时间线页面
  /// - `'video'` - 视频时间线页面
  /// - `'recentlyAdded'` - 最近添加时间线页面
  /// - `'main'` - 主时间线页面（照片页面，默认无内容过滤）
  /// - `'raw'` - RAW 时间线页面（仅 RAW 照片）
  /// - `'live'` - Live Photo 时间线页面（仅 Live 资产）
  ///
  /// Copied from [TimelineContentFilterConfigProvider].
  const TimelineContentFilterConfigProviderFamily();

  /// 时间线内容过滤配置 Provider
  ///
  /// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
  /// 每个页面拥有独立的过滤配置，页面切换时自动清理。
  ///
  /// **页面标识符**：
  /// - `'favorite'` - 收藏时间线页面
  /// - `'video'` - 视频时间线页面
  /// - `'recentlyAdded'` - 最近添加时间线页面
  /// - `'main'` - 主时间线页面（照片页面，默认无内容过滤）
  /// - `'raw'` - RAW 时间线页面（仅 RAW 照片）
  /// - `'live'` - Live Photo 时间线页面（仅 Live 资产）
  ///
  /// Copied from [TimelineContentFilterConfigProvider].
  TimelineContentFilterConfigProviderProvider call(
    String pageId,
  ) {
    return TimelineContentFilterConfigProviderProvider(
      pageId,
    );
  }

  @override
  TimelineContentFilterConfigProviderProvider getProviderOverride(
    covariant TimelineContentFilterConfigProviderProvider provider,
  ) {
    return call(
      provider.pageId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'timelineContentFilterConfigProviderProvider';
}

/// 时间线内容过滤配置 Provider
///
/// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
/// 每个页面拥有独立的过滤配置，页面切换时自动清理。
///
/// **页面标识符**：
/// - `'favorite'` - 收藏时间线页面
/// - `'video'` - 视频时间线页面
/// - `'recentlyAdded'` - 最近添加时间线页面
/// - `'main'` - 主时间线页面（照片页面，默认无内容过滤）
/// - `'raw'` - RAW 时间线页面（仅 RAW 照片）
/// - `'live'` - Live Photo 时间线页面（仅 Live 资产）
///
/// Copied from [TimelineContentFilterConfigProvider].
class TimelineContentFilterConfigProviderProvider
    extends AutoDisposeNotifierProviderImpl<TimelineContentFilterConfigProvider,
        TimelineContentFilterConfig> {
  /// 时间线内容过滤配置 Provider
  ///
  /// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
  /// 每个页面拥有独立的过滤配置，页面切换时自动清理。
  ///
  /// **页面标识符**：
  /// - `'favorite'` - 收藏时间线页面
  /// - `'video'` - 视频时间线页面
  /// - `'recentlyAdded'` - 最近添加时间线页面
  /// - `'main'` - 主时间线页面（照片页面，默认无内容过滤）
  /// - `'raw'` - RAW 时间线页面（仅 RAW 照片）
  /// - `'live'` - Live Photo 时间线页面（仅 Live 资产）
  ///
  /// Copied from [TimelineContentFilterConfigProvider].
  TimelineContentFilterConfigProviderProvider(
    String pageId,
  ) : this._internal(
          () => TimelineContentFilterConfigProvider()..pageId = pageId,
          from: timelineContentFilterConfigProviderProvider,
          name: r'timelineContentFilterConfigProviderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$timelineContentFilterConfigProviderHash,
          dependencies: TimelineContentFilterConfigProviderFamily._dependencies,
          allTransitiveDependencies: TimelineContentFilterConfigProviderFamily
              ._allTransitiveDependencies,
          pageId: pageId,
        );

  TimelineContentFilterConfigProviderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pageId,
  }) : super.internal();

  final String pageId;

  @override
  TimelineContentFilterConfig runNotifierBuild(
    covariant TimelineContentFilterConfigProvider notifier,
  ) {
    return notifier.build(
      pageId,
    );
  }

  @override
  Override overrideWith(TimelineContentFilterConfigProvider Function() create) {
    return ProviderOverride(
      origin: this,
      override: TimelineContentFilterConfigProviderProvider._internal(
        () => create()..pageId = pageId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pageId: pageId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<TimelineContentFilterConfigProvider,
      TimelineContentFilterConfig> createElement() {
    return _TimelineContentFilterConfigProviderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineContentFilterConfigProviderProvider &&
        other.pageId == pageId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pageId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TimelineContentFilterConfigProviderRef
    on AutoDisposeNotifierProviderRef<TimelineContentFilterConfig> {
  /// The parameter `pageId` of this provider.
  String get pageId;
}

class _TimelineContentFilterConfigProviderProviderElement
    extends AutoDisposeNotifierProviderElement<
        TimelineContentFilterConfigProvider, TimelineContentFilterConfig>
    with TimelineContentFilterConfigProviderRef {
  _TimelineContentFilterConfigProviderProviderElement(super.provider);

  @override
  String get pageId =>
      (origin as TimelineContentFilterConfigProviderProvider).pageId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
