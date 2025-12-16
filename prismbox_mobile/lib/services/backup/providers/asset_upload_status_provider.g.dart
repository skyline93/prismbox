// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_upload_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$assetUploadStatusHash() => r'dc67daf8b73bdb50c5c39b15051e2a95ab1bc8e4';

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
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
///
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
///
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态）
///
/// **状态判断逻辑**：
/// 1. 如果 hasRemote == true → 已上传
/// 2. 如果是 LocalAsset，监听上传任务状态变化：
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
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
///
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
///
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态）
///
/// **状态判断逻辑**：
/// 1. 如果 hasRemote == true → 已上传
/// 2. 如果是 LocalAsset，监听上传任务状态变化：
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
  /// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
  /// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
  ///
  /// **优化措施**：
  /// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
  /// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
  /// - 状态去重，只在状态真正改变时才 yield
  ///
  /// **参数**：
  /// - [assetId] - 资产的唯一标识符（localId 或 id）
  /// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态）
  ///
  /// **状态判断逻辑**：
  /// 1. 如果 hasRemote == true → 已上传
  /// 2. 如果是 LocalAsset，监听上传任务状态变化：
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
  /// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
  /// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
  ///
  /// **优化措施**：
  /// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
  /// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
  /// - 状态去重，只在状态真正改变时才 yield
  ///
  /// **参数**：
  /// - [assetId] - 资产的唯一标识符（localId 或 id）
  /// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态）
  ///
  /// **状态判断逻辑**：
  /// 1. 如果 hasRemote == true → 已上传
  /// 2. 如果是 LocalAsset，监听上传任务状态变化：
  ///    - uploading/pending → 上传中
  ///    - failed/permanentlyFailed → 上传失败
  ///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
  /// 3. 否则 → 未上传
  ///
  /// Copied from [assetUploadStatus].
  AssetUploadStatusProvider call(
    String assetId,
    bool hasRemote,
  ) {
    return AssetUploadStatusProvider(
      assetId,
      hasRemote,
    );
  }

  @override
  AssetUploadStatusProvider getProviderOverride(
    covariant AssetUploadStatusProvider provider,
  ) {
    return call(
      provider.assetId,
      provider.hasRemote,
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
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
///
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
///
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态）
///
/// **状态判断逻辑**：
/// 1. 如果 hasRemote == true → 已上传
/// 2. 如果是 LocalAsset，监听上传任务状态变化：
///    - uploading/pending → 上传中
///    - failed/permanentlyFailed → 上传失败
///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
/// 3. 否则 → 未上传
///
/// Copied from [assetUploadStatus].
class AssetUploadStatusProvider
    extends AutoDisposeStreamProvider<AssetUploadStatusInfo> {
  /// 资产上传状态 Provider
  ///
  /// 根据资产查询上传状态，结合数据库和任务状态
  /// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
  /// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
  ///
  /// **优化措施**：
  /// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
  /// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
  /// - 状态去重，只在状态真正改变时才 yield
  ///
  /// **参数**：
  /// - [assetId] - 资产的唯一标识符（localId 或 id）
  /// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态）
  ///
  /// **状态判断逻辑**：
  /// 1. 如果 hasRemote == true → 已上传
  /// 2. 如果是 LocalAsset，监听上传任务状态变化：
  ///    - uploading/pending → 上传中
  ///    - failed/permanentlyFailed → 上传失败
  ///    - completed → 已上传（即使 remoteAssetId 为空，可能是数据不一致）
  /// 3. 否则 → 未上传
  ///
  /// Copied from [assetUploadStatus].
  AssetUploadStatusProvider(
    String assetId,
    bool hasRemote,
  ) : this._internal(
          (ref) => assetUploadStatus(
            ref as AssetUploadStatusRef,
            assetId,
            hasRemote,
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
          assetId: assetId,
          hasRemote: hasRemote,
        );

  AssetUploadStatusProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.assetId,
    required this.hasRemote,
  }) : super.internal();

  final String assetId;
  final bool hasRemote;

  @override
  Override overrideWith(
    Stream<AssetUploadStatusInfo> Function(AssetUploadStatusRef provider)
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
        assetId: assetId,
        hasRemote: hasRemote,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<AssetUploadStatusInfo> createElement() {
    return _AssetUploadStatusProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AssetUploadStatusProvider &&
        other.assetId == assetId &&
        other.hasRemote == hasRemote;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, assetId.hashCode);
    hash = _SystemHash.combine(hash, hasRemote.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AssetUploadStatusRef
    on AutoDisposeStreamProviderRef<AssetUploadStatusInfo> {
  /// The parameter `assetId` of this provider.
  String get assetId;

  /// The parameter `hasRemote` of this provider.
  bool get hasRemote;
}

class _AssetUploadStatusProviderElement
    extends AutoDisposeStreamProviderElement<AssetUploadStatusInfo>
    with AssetUploadStatusRef {
  _AssetUploadStatusProviderElement(super.provider);

  @override
  String get assetId => (origin as AssetUploadStatusProvider).assetId;
  @override
  bool get hasRemote => (origin as AssetUploadStatusProvider).hasRemote;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
