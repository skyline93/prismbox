// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$assetPathResolverHash() => r'bf169edadb165331e970548fee1598ebf5f9832d';

/// AssetPathResolver Provider
///
/// Copied from [assetPathResolver].
@ProviderFor(assetPathResolver)
final assetPathResolverProvider =
    AutoDisposeFutureProvider<AssetPathResolver>.internal(
  assetPathResolver,
  name: r'assetPathResolverProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$assetPathResolverHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AssetPathResolverRef = AutoDisposeFutureProviderRef<AssetPathResolver>;
String _$assetServiceHash() => r'c0e2b1cd2fda3fa312685049b98d7cd11a6013de';

/// AssetService Provider
///
/// Copied from [assetService].
@ProviderFor(assetService)
final assetServiceProvider = AutoDisposeFutureProvider<AssetService>.internal(
  assetService,
  name: r'assetServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$assetServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AssetServiceRef = AutoDisposeFutureProviderRef<AssetService>;
String _$assetFavoriteServiceHash() =>
    r'61616d525e651ea7e5440d80fdb1501ca0b956f2';

/// AssetFavoriteService Provider
///
/// Copied from [assetFavoriteService].
@ProviderFor(assetFavoriteService)
final assetFavoriteServiceProvider =
    AutoDisposeFutureProvider<AssetFavoriteService>.internal(
  assetFavoriteService,
  name: r'assetFavoriteServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$assetFavoriteServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AssetFavoriteServiceRef
    = AutoDisposeFutureProviderRef<AssetFavoriteService>;
String _$assetFavoriteStatusHash() =>
    r'f84441048dc0dfcd5f2befd30de24ce089198b75';

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

/// 按 assetId 从本地媒体表读取收藏状态，供缩略图等单独监听
/// 收藏/取消收藏成功后 invalidate 本 provider(assetId)，即可驱动所有显示该资产的收藏图标更新
///
/// Copied from [assetFavoriteStatus].
@ProviderFor(assetFavoriteStatus)
const assetFavoriteStatusProvider = AssetFavoriteStatusFamily();

/// 按 assetId 从本地媒体表读取收藏状态，供缩略图等单独监听
/// 收藏/取消收藏成功后 invalidate 本 provider(assetId)，即可驱动所有显示该资产的收藏图标更新
///
/// Copied from [assetFavoriteStatus].
class AssetFavoriteStatusFamily extends Family<AsyncValue<bool>> {
  /// 按 assetId 从本地媒体表读取收藏状态，供缩略图等单独监听
  /// 收藏/取消收藏成功后 invalidate 本 provider(assetId)，即可驱动所有显示该资产的收藏图标更新
  ///
  /// Copied from [assetFavoriteStatus].
  const AssetFavoriteStatusFamily();

  /// 按 assetId 从本地媒体表读取收藏状态，供缩略图等单独监听
  /// 收藏/取消收藏成功后 invalidate 本 provider(assetId)，即可驱动所有显示该资产的收藏图标更新
  ///
  /// Copied from [assetFavoriteStatus].
  AssetFavoriteStatusProvider call(
    String assetId,
  ) {
    return AssetFavoriteStatusProvider(
      assetId,
    );
  }

  @override
  AssetFavoriteStatusProvider getProviderOverride(
    covariant AssetFavoriteStatusProvider provider,
  ) {
    return call(
      provider.assetId,
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
  String? get name => r'assetFavoriteStatusProvider';
}

/// 按 assetId 从本地媒体表读取收藏状态，供缩略图等单独监听
/// 收藏/取消收藏成功后 invalidate 本 provider(assetId)，即可驱动所有显示该资产的收藏图标更新
///
/// Copied from [assetFavoriteStatus].
class AssetFavoriteStatusProvider extends AutoDisposeFutureProvider<bool> {
  /// 按 assetId 从本地媒体表读取收藏状态，供缩略图等单独监听
  /// 收藏/取消收藏成功后 invalidate 本 provider(assetId)，即可驱动所有显示该资产的收藏图标更新
  ///
  /// Copied from [assetFavoriteStatus].
  AssetFavoriteStatusProvider(
    String assetId,
  ) : this._internal(
          (ref) => assetFavoriteStatus(
            ref as AssetFavoriteStatusRef,
            assetId,
          ),
          from: assetFavoriteStatusProvider,
          name: r'assetFavoriteStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$assetFavoriteStatusHash,
          dependencies: AssetFavoriteStatusFamily._dependencies,
          allTransitiveDependencies:
              AssetFavoriteStatusFamily._allTransitiveDependencies,
          assetId: assetId,
        );

  AssetFavoriteStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.assetId,
  }) : super.internal();

  final String assetId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(AssetFavoriteStatusRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AssetFavoriteStatusProvider._internal(
        (ref) => create(ref as AssetFavoriteStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        assetId: assetId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _AssetFavoriteStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AssetFavoriteStatusProvider && other.assetId == assetId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, assetId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AssetFavoriteStatusRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `assetId` of this provider.
  String get assetId;
}

class _AssetFavoriteStatusProviderElement
    extends AutoDisposeFutureProviderElement<bool> with AssetFavoriteStatusRef {
  _AssetFavoriteStatusProviderElement(super.provider);

  @override
  String get assetId => (origin as AssetFavoriteStatusProvider).assetId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
