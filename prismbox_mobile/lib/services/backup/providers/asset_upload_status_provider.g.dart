// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_upload_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$assetUploadStatusHash() => r'4897466c5810c32808444ca0c3e1871d1ffffdbb';

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

/// 资产上传状态 Provider
///
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用 family 参数化，每个资产有独立的状态实例
///
/// **状态判断逻辑**：
/// 1. 如果 asset.hasRemote == true → 已上传
/// 2. 如果是 LocalAsset，查询上传任务状态：
///    - uploading/pending → 上传中
///    - failed/permanentlyFailed → 上传失败
///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
/// 3. 否则 → 未上传
///
/// Copied from [assetUploadStatus].
@ProviderFor(assetUploadStatus)
const assetUploadStatusProvider = AssetUploadStatusFamily();

/// 资产上传状态 Provider
///
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用 family 参数化，每个资产有独立的状态实例
///
/// **状态判断逻辑**：
/// 1. 如果 asset.hasRemote == true → 已上传
/// 2. 如果是 LocalAsset，查询上传任务状态：
///    - uploading/pending → 上传中
///    - failed/permanentlyFailed → 上传失败
///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
/// 3. 否则 → 未上传
///
/// Copied from [assetUploadStatus].
class AssetUploadStatusFamily
    extends Family<AsyncValue<AssetUploadStatusInfo>> {
  /// 资产上传状态 Provider
  ///
  /// 根据资产查询上传状态，结合数据库和任务状态
  /// 使用 family 参数化，每个资产有独立的状态实例
  ///
  /// **状态判断逻辑**：
  /// 1. 如果 asset.hasRemote == true → 已上传
  /// 2. 如果是 LocalAsset，查询上传任务状态：
  ///    - uploading/pending → 上传中
  ///    - failed/permanentlyFailed → 上传失败
  ///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
  /// 3. 否则 → 未上传
  ///
  /// Copied from [assetUploadStatus].
  const AssetUploadStatusFamily();

  /// 资产上传状态 Provider
  ///
  /// 根据资产查询上传状态，结合数据库和任务状态
  /// 使用 family 参数化，每个资产有独立的状态实例
  ///
  /// **状态判断逻辑**：
  /// 1. 如果 asset.hasRemote == true → 已上传
  /// 2. 如果是 LocalAsset，查询上传任务状态：
  ///    - uploading/pending → 上传中
  ///    - failed/permanentlyFailed → 上传失败
  ///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
  /// 3. 否则 → 未上传
  ///
  /// Copied from [assetUploadStatus].
  AssetUploadStatusProvider call(
    BaseAsset asset,
  ) {
    return AssetUploadStatusProvider(
      asset,
    );
  }

  @override
  AssetUploadStatusProvider getProviderOverride(
    covariant AssetUploadStatusProvider provider,
  ) {
    return call(
      provider.asset,
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
  String? get name => r'assetUploadStatusProvider';
}

/// 资产上传状态 Provider
///
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用 family 参数化，每个资产有独立的状态实例
///
/// **状态判断逻辑**：
/// 1. 如果 asset.hasRemote == true → 已上传
/// 2. 如果是 LocalAsset，查询上传任务状态：
///    - uploading/pending → 上传中
///    - failed/permanentlyFailed → 上传失败
///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
/// 3. 否则 → 未上传
///
/// Copied from [assetUploadStatus].
class AssetUploadStatusProvider
    extends AutoDisposeFutureProvider<AssetUploadStatusInfo> {
  /// 资产上传状态 Provider
  ///
  /// 根据资产查询上传状态，结合数据库和任务状态
  /// 使用 family 参数化，每个资产有独立的状态实例
  ///
  /// **状态判断逻辑**：
  /// 1. 如果 asset.hasRemote == true → 已上传
  /// 2. 如果是 LocalAsset，查询上传任务状态：
  ///    - uploading/pending → 上传中
  ///    - failed/permanentlyFailed → 上传失败
  ///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
  /// 3. 否则 → 未上传
  ///
  /// Copied from [assetUploadStatus].
  AssetUploadStatusProvider(
    BaseAsset asset,
  ) : this._internal(
          (ref) => assetUploadStatus(
            ref as AssetUploadStatusRef,
            asset,
          ),
          from: assetUploadStatusProvider,
          name: r'assetUploadStatusProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$assetUploadStatusHash,
          dependencies: AssetUploadStatusFamily._dependencies,
          allTransitiveDependencies:
              AssetUploadStatusFamily._allTransitiveDependencies,
          asset: asset,
        );

  AssetUploadStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.asset,
  }) : super.internal();

  final BaseAsset asset;

  @override
  Override overrideWith(
    FutureOr<AssetUploadStatusInfo> Function(AssetUploadStatusRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AssetUploadStatusProvider._internal(
        (ref) => create(ref as AssetUploadStatusRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        asset: asset,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<AssetUploadStatusInfo> createElement() {
    return _AssetUploadStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AssetUploadStatusProvider && other.asset == asset;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, asset.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AssetUploadStatusRef
    on AutoDisposeFutureProviderRef<AssetUploadStatusInfo> {
  /// The parameter `asset` of this provider.
  BaseAsset get asset;
}

class _AssetUploadStatusProviderElement
    extends AutoDisposeFutureProviderElement<AssetUploadStatusInfo>
    with AssetUploadStatusRef {
  _AssetUploadStatusProviderElement(super.provider);

  @override
  BaseAsset get asset => (origin as AssetUploadStatusProvider).asset;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
