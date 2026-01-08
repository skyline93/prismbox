// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_sort_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timelineSortConfigProviderHash() =>
    r'5f5675fb9da7a0ee6b7c952d027ebc32a9d74f72';

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

abstract class _$TimelineSortConfigProvider
    extends BuildlessAutoDisposeNotifier<TimelineSortConfig> {
  late final String pageId;

  TimelineSortConfig build(
    String pageId,
  );
}

/// 时间线排序配置 Provider
///
/// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
/// 每个页面拥有独立的排序配置，页面切换时自动清理。
///
/// **页面标识符**：
/// - `'favorite'` - 收藏时间线页面
/// - `'video'` - 视频时间线页面
/// - `'recentlyAdded'` - 最近添加时间线页面（默认按更新时间降序）
/// - `'main'` - 主时间线页面（照片页面，默认按创建时间降序）
///
/// Copied from [TimelineSortConfigProvider].
@ProviderFor(TimelineSortConfigProvider)
const timelineSortConfigProviderProvider = TimelineSortConfigProviderFamily();

/// 时间线排序配置 Provider
///
/// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
/// 每个页面拥有独立的排序配置，页面切换时自动清理。
///
/// **页面标识符**：
/// - `'favorite'` - 收藏时间线页面
/// - `'video'` - 视频时间线页面
/// - `'recentlyAdded'` - 最近添加时间线页面（默认按更新时间降序）
/// - `'main'` - 主时间线页面（照片页面，默认按创建时间降序）
///
/// Copied from [TimelineSortConfigProvider].
class TimelineSortConfigProviderFamily extends Family<TimelineSortConfig> {
  /// 时间线排序配置 Provider
  ///
  /// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
  /// 每个页面拥有独立的排序配置，页面切换时自动清理。
  ///
  /// **页面标识符**：
  /// - `'favorite'` - 收藏时间线页面
  /// - `'video'` - 视频时间线页面
  /// - `'recentlyAdded'` - 最近添加时间线页面（默认按更新时间降序）
  /// - `'main'` - 主时间线页面（照片页面，默认按创建时间降序）
  ///
  /// Copied from [TimelineSortConfigProvider].
  const TimelineSortConfigProviderFamily();

  /// 时间线排序配置 Provider
  ///
  /// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
  /// 每个页面拥有独立的排序配置，页面切换时自动清理。
  ///
  /// **页面标识符**：
  /// - `'favorite'` - 收藏时间线页面
  /// - `'video'` - 视频时间线页面
  /// - `'recentlyAdded'` - 最近添加时间线页面（默认按更新时间降序）
  /// - `'main'` - 主时间线页面（照片页面，默认按创建时间降序）
  ///
  /// Copied from [TimelineSortConfigProvider].
  TimelineSortConfigProviderProvider call(
    String pageId,
  ) {
    return TimelineSortConfigProviderProvider(
      pageId,
    );
  }

  @override
  TimelineSortConfigProviderProvider getProviderOverride(
    covariant TimelineSortConfigProviderProvider provider,
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
  String? get name => r'timelineSortConfigProviderProvider';
}

/// 时间线排序配置 Provider
///
/// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
/// 每个页面拥有独立的排序配置，页面切换时自动清理。
///
/// **页面标识符**：
/// - `'favorite'` - 收藏时间线页面
/// - `'video'` - 视频时间线页面
/// - `'recentlyAdded'` - 最近添加时间线页面（默认按更新时间降序）
/// - `'main'` - 主时间线页面（照片页面，默认按创建时间降序）
///
/// Copied from [TimelineSortConfigProvider].
class TimelineSortConfigProviderProvider
    extends AutoDisposeNotifierProviderImpl<TimelineSortConfigProvider,
        TimelineSortConfig> {
  /// 时间线排序配置 Provider
  ///
  /// 使用 `family` 参数区分不同页面（如收藏、视频、最近添加等）。
  /// 每个页面拥有独立的排序配置，页面切换时自动清理。
  ///
  /// **页面标识符**：
  /// - `'favorite'` - 收藏时间线页面
  /// - `'video'` - 视频时间线页面
  /// - `'recentlyAdded'` - 最近添加时间线页面（默认按更新时间降序）
  /// - `'main'` - 主时间线页面（照片页面，默认按创建时间降序）
  ///
  /// Copied from [TimelineSortConfigProvider].
  TimelineSortConfigProviderProvider(
    String pageId,
  ) : this._internal(
          () => TimelineSortConfigProvider()..pageId = pageId,
          from: timelineSortConfigProviderProvider,
          name: r'timelineSortConfigProviderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$timelineSortConfigProviderHash,
          dependencies: TimelineSortConfigProviderFamily._dependencies,
          allTransitiveDependencies:
              TimelineSortConfigProviderFamily._allTransitiveDependencies,
          pageId: pageId,
        );

  TimelineSortConfigProviderProvider._internal(
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
  TimelineSortConfig runNotifierBuild(
    covariant TimelineSortConfigProvider notifier,
  ) {
    return notifier.build(
      pageId,
    );
  }

  @override
  Override overrideWith(TimelineSortConfigProvider Function() create) {
    return ProviderOverride(
      origin: this,
      override: TimelineSortConfigProviderProvider._internal(
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
  AutoDisposeNotifierProviderElement<TimelineSortConfigProvider,
      TimelineSortConfig> createElement() {
    return _TimelineSortConfigProviderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineSortConfigProviderProvider &&
        other.pageId == pageId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pageId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TimelineSortConfigProviderRef
    on AutoDisposeNotifierProviderRef<TimelineSortConfig> {
  /// The parameter `pageId` of this provider.
  String get pageId;
}

class _TimelineSortConfigProviderProviderElement
    extends AutoDisposeNotifierProviderElement<TimelineSortConfigProvider,
        TimelineSortConfig> with TimelineSortConfigProviderRef {
  _TimelineSortConfigProviderProviderElement(super.provider);

  @override
  String get pageId => (origin as TimelineSortConfigProviderProvider).pageId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
