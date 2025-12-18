// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$timelineAssetsHash() => r'74d6cd07cd275ade34820c63be674b1e7b3da1fd';

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

/// 时间线数据 Provider
/// 提供时间线数据（BaseAsset 列表）
///
/// Copied from [timelineAssets].
@ProviderFor(timelineAssets)
const timelineAssetsProvider = TimelineAssetsFamily();

/// 时间线数据 Provider
/// 提供时间线数据（BaseAsset 列表）
///
/// Copied from [timelineAssets].
class TimelineAssetsFamily extends Family<AsyncValue<List<BaseAsset>>> {
  /// 时间线数据 Provider
  /// 提供时间线数据（BaseAsset 列表）
  ///
  /// Copied from [timelineAssets].
  const TimelineAssetsFamily();

  /// 时间线数据 Provider
  /// 提供时间线数据（BaseAsset 列表）
  ///
  /// Copied from [timelineAssets].
  TimelineAssetsProvider call({
    bool forcePhotoManager = false,
  }) {
    return TimelineAssetsProvider(
      forcePhotoManager: forcePhotoManager,
    );
  }

  @override
  TimelineAssetsProvider getProviderOverride(
    covariant TimelineAssetsProvider provider,
  ) {
    return call(
      forcePhotoManager: provider.forcePhotoManager,
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
  String? get name => r'timelineAssetsProvider';
}

/// 时间线数据 Provider
/// 提供时间线数据（BaseAsset 列表）
///
/// Copied from [timelineAssets].
class TimelineAssetsProvider
    extends AutoDisposeFutureProvider<List<BaseAsset>> {
  /// 时间线数据 Provider
  /// 提供时间线数据（BaseAsset 列表）
  ///
  /// Copied from [timelineAssets].
  TimelineAssetsProvider({
    bool forcePhotoManager = false,
  }) : this._internal(
          (ref) => timelineAssets(
            ref as TimelineAssetsRef,
            forcePhotoManager: forcePhotoManager,
          ),
          from: timelineAssetsProvider,
          name: r'timelineAssetsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$timelineAssetsHash,
          dependencies: TimelineAssetsFamily._dependencies,
          allTransitiveDependencies:
              TimelineAssetsFamily._allTransitiveDependencies,
          forcePhotoManager: forcePhotoManager,
        );

  TimelineAssetsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.forcePhotoManager,
  }) : super.internal();

  final bool forcePhotoManager;

  @override
  Override overrideWith(
    FutureOr<List<BaseAsset>> Function(TimelineAssetsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TimelineAssetsProvider._internal(
        (ref) => create(ref as TimelineAssetsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        forcePhotoManager: forcePhotoManager,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<BaseAsset>> createElement() {
    return _TimelineAssetsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TimelineAssetsProvider &&
        other.forcePhotoManager == forcePhotoManager;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, forcePhotoManager.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TimelineAssetsRef on AutoDisposeFutureProviderRef<List<BaseAsset>> {
  /// The parameter `forcePhotoManager` of this provider.
  bool get forcePhotoManager;
}

class _TimelineAssetsProviderElement
    extends AutoDisposeFutureProviderElement<List<BaseAsset>>
    with TimelineAssetsRef {
  _TimelineAssetsProviderElement(super.provider);

  @override
  bool get forcePhotoManager =>
      (origin as TimelineAssetsProvider).forcePhotoManager;
}

String _$timelineSectionsHash() => r'038781495d2516c189de12f1441d8176ce8d5eb0';

/// 时间线分组数据 Provider
///
/// 将原始的时间线数据转换为按时间分组的 TimelineSection 列表
/// 依赖 timelineAssetsProvider 获取原始数据，然后通过 TimelineGroupingService 进行分组转换
/// 支持根据筛选模式（全部/已备份/未备份）过滤照片
///
/// Copied from [timelineSections].
@ProviderFor(timelineSections)
final timelineSectionsProvider =
    AutoDisposeFutureProvider<List<TimelineSection>>.internal(
  timelineSections,
  name: r'timelineSectionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$timelineSectionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TimelineSectionsRef
    = AutoDisposeFutureProviderRef<List<TimelineSection>>;
String _$syncStatusHash() => r'bb068acf9f97f8b63ded82b67827d085cd2b0e56';

/// 同步状态 Provider
///
/// Copied from [syncStatus].
@ProviderFor(syncStatus)
final syncStatusProvider = AutoDisposeStreamProvider<SyncStatusInfo>.internal(
  syncStatus,
  name: r'syncStatusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$syncStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SyncStatusRef = AutoDisposeStreamProviderRef<SyncStatusInfo>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
