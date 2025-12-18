// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_upload_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$assetUploadStatusHash() => r'c7e0a4bf9d966743c4d658384c253108be61c2eb';

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
/// **⚠️ 架构问题：此接口负担过重**
///
/// 此 Provider 承担了过多职责，包括：
/// 1. 查询上传任务状态（upload_task_entity 表）
/// 2. 查询远程资产表（remote_asset_entity 表）
/// 3. 查询本地资产表（local_asset_entity 表，用于获取 checksum）
/// 4. 同时监听多个数据源的变化
/// 5. 合并多个数据源的状态判断逻辑
/// 6. 处理状态去重和错误处理
///
/// **建议重构方向**：
/// - 将状态判断逻辑提取到独立的 Service 层
/// - 使用组合模式，将不同数据源的查询分离
/// - 考虑使用 StateNotifier 替代 StreamProvider，提供更细粒度的控制
/// - 将状态合并逻辑提取为独立的函数或类
///
/// **当前实现说明**：
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
///
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
/// - 同时监听上传任务表和远程资产表，确保状态实时更新
///
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态，但不作为唯一依据）
/// - [checksum] - 资产的 checksum（可选，用于查询远程资产表）
///
/// **状态判断逻辑（优先级顺序）**：
/// 1. 优先查询上传任务状态（最可靠的数据源）
/// 2. 如果没有任务记录，查询远程资产表（通过 checksum）
/// 3. 如果 hasRemote == true，也显示已上传（快速路径，但不作为唯一依据）
/// 4. 否则显示未上传
///
/// Copied from [assetUploadStatus].
@ProviderFor(assetUploadStatus)
const assetUploadStatusProvider = AssetUploadStatusFamily();

/// 资产上传状态 Provider
///
/// **⚠️ 架构问题：此接口负担过重**
///
/// 此 Provider 承担了过多职责，包括：
/// 1. 查询上传任务状态（upload_task_entity 表）
/// 2. 查询远程资产表（remote_asset_entity 表）
/// 3. 查询本地资产表（local_asset_entity 表，用于获取 checksum）
/// 4. 同时监听多个数据源的变化
/// 5. 合并多个数据源的状态判断逻辑
/// 6. 处理状态去重和错误处理
///
/// **建议重构方向**：
/// - 将状态判断逻辑提取到独立的 Service 层
/// - 使用组合模式，将不同数据源的查询分离
/// - 考虑使用 StateNotifier 替代 StreamProvider，提供更细粒度的控制
/// - 将状态合并逻辑提取为独立的函数或类
///
/// **当前实现说明**：
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
///
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
/// - 同时监听上传任务表和远程资产表，确保状态实时更新
///
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态，但不作为唯一依据）
/// - [checksum] - 资产的 checksum（可选，用于查询远程资产表）
///
/// **状态判断逻辑（优先级顺序）**：
/// 1. 优先查询上传任务状态（最可靠的数据源）
/// 2. 如果没有任务记录，查询远程资产表（通过 checksum）
/// 3. 如果 hasRemote == true，也显示已上传（快速路径，但不作为唯一依据）
/// 4. 否则显示未上传
///
/// Copied from [assetUploadStatus].
class AssetUploadStatusFamily
    extends Family<AsyncValue<AssetUploadStatusInfo>> {
  /// 资产上传状态 Provider
  ///
  /// **⚠️ 架构问题：此接口负担过重**
  ///
  /// 此 Provider 承担了过多职责，包括：
  /// 1. 查询上传任务状态（upload_task_entity 表）
  /// 2. 查询远程资产表（remote_asset_entity 表）
  /// 3. 查询本地资产表（local_asset_entity 表，用于获取 checksum）
  /// 4. 同时监听多个数据源的变化
  /// 5. 合并多个数据源的状态判断逻辑
  /// 6. 处理状态去重和错误处理
  ///
  /// **建议重构方向**：
  /// - 将状态判断逻辑提取到独立的 Service 层
  /// - 使用组合模式，将不同数据源的查询分离
  /// - 考虑使用 StateNotifier 替代 StreamProvider，提供更细粒度的控制
  /// - 将状态合并逻辑提取为独立的函数或类
  ///
  /// **当前实现说明**：
  /// 根据资产查询上传状态，结合数据库和任务状态
  /// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
  /// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
  ///
  /// **优化措施**：
  /// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
  /// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
  /// - 状态去重，只在状态真正改变时才 yield
  /// - 同时监听上传任务表和远程资产表，确保状态实时更新
  ///
  /// **参数**：
  /// - [assetId] - 资产的唯一标识符（localId 或 id）
  /// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态，但不作为唯一依据）
  /// - [checksum] - 资产的 checksum（可选，用于查询远程资产表）
  ///
  /// **状态判断逻辑（优先级顺序）**：
  /// 1. 优先查询上传任务状态（最可靠的数据源）
  /// 2. 如果没有任务记录，查询远程资产表（通过 checksum）
  /// 3. 如果 hasRemote == true，也显示已上传（快速路径，但不作为唯一依据）
  /// 4. 否则显示未上传
  ///
  /// Copied from [assetUploadStatus].
  const AssetUploadStatusFamily();

  /// 资产上传状态 Provider
  ///
  /// **⚠️ 架构问题：此接口负担过重**
  ///
  /// 此 Provider 承担了过多职责，包括：
  /// 1. 查询上传任务状态（upload_task_entity 表）
  /// 2. 查询远程资产表（remote_asset_entity 表）
  /// 3. 查询本地资产表（local_asset_entity 表，用于获取 checksum）
  /// 4. 同时监听多个数据源的变化
  /// 5. 合并多个数据源的状态判断逻辑
  /// 6. 处理状态去重和错误处理
  ///
  /// **建议重构方向**：
  /// - 将状态判断逻辑提取到独立的 Service 层
  /// - 使用组合模式，将不同数据源的查询分离
  /// - 考虑使用 StateNotifier 替代 StreamProvider，提供更细粒度的控制
  /// - 将状态合并逻辑提取为独立的函数或类
  ///
  /// **当前实现说明**：
  /// 根据资产查询上传状态，结合数据库和任务状态
  /// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
  /// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
  ///
  /// **优化措施**：
  /// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
  /// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
  /// - 状态去重，只在状态真正改变时才 yield
  /// - 同时监听上传任务表和远程资产表，确保状态实时更新
  ///
  /// **参数**：
  /// - [assetId] - 资产的唯一标识符（localId 或 id）
  /// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态，但不作为唯一依据）
  /// - [checksum] - 资产的 checksum（可选，用于查询远程资产表）
  ///
  /// **状态判断逻辑（优先级顺序）**：
  /// 1. 优先查询上传任务状态（最可靠的数据源）
  /// 2. 如果没有任务记录，查询远程资产表（通过 checksum）
  /// 3. 如果 hasRemote == true，也显示已上传（快速路径，但不作为唯一依据）
  /// 4. 否则显示未上传
  ///
  /// Copied from [assetUploadStatus].
  AssetUploadStatusProvider call(
    String assetId,
    bool hasRemote,
    String? checksum,
  ) {
    return AssetUploadStatusProvider(
      assetId,
      hasRemote,
      checksum,
    );
  }

  @override
  AssetUploadStatusProvider getProviderOverride(
    covariant AssetUploadStatusProvider provider,
  ) {
    return call(
      provider.assetId,
      provider.hasRemote,
      provider.checksum,
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
/// **⚠️ 架构问题：此接口负担过重**
///
/// 此 Provider 承担了过多职责，包括：
/// 1. 查询上传任务状态（upload_task_entity 表）
/// 2. 查询远程资产表（remote_asset_entity 表）
/// 3. 查询本地资产表（local_asset_entity 表，用于获取 checksum）
/// 4. 同时监听多个数据源的变化
/// 5. 合并多个数据源的状态判断逻辑
/// 6. 处理状态去重和错误处理
///
/// **建议重构方向**：
/// - 将状态判断逻辑提取到独立的 Service 层
/// - 使用组合模式，将不同数据源的查询分离
/// - 考虑使用 StateNotifier 替代 StreamProvider，提供更细粒度的控制
/// - 将状态合并逻辑提取为独立的函数或类
///
/// **当前实现说明**：
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
///
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
/// - 同时监听上传任务表和远程资产表，确保状态实时更新
///
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态，但不作为唯一依据）
/// - [checksum] - 资产的 checksum（可选，用于查询远程资产表）
///
/// **状态判断逻辑（优先级顺序）**：
/// 1. 优先查询上传任务状态（最可靠的数据源）
/// 2. 如果没有任务记录，查询远程资产表（通过 checksum）
/// 3. 如果 hasRemote == true，也显示已上传（快速路径，但不作为唯一依据）
/// 4. 否则显示未上传
///
/// Copied from [assetUploadStatus].
class AssetUploadStatusProvider
    extends AutoDisposeStreamProvider<AssetUploadStatusInfo> {
  /// 资产上传状态 Provider
  ///
  /// **⚠️ 架构问题：此接口负担过重**
  ///
  /// 此 Provider 承担了过多职责，包括：
  /// 1. 查询上传任务状态（upload_task_entity 表）
  /// 2. 查询远程资产表（remote_asset_entity 表）
  /// 3. 查询本地资产表（local_asset_entity 表，用于获取 checksum）
  /// 4. 同时监听多个数据源的变化
  /// 5. 合并多个数据源的状态判断逻辑
  /// 6. 处理状态去重和错误处理
  ///
  /// **建议重构方向**：
  /// - 将状态判断逻辑提取到独立的 Service 层
  /// - 使用组合模式，将不同数据源的查询分离
  /// - 考虑使用 StateNotifier 替代 StreamProvider，提供更细粒度的控制
  /// - 将状态合并逻辑提取为独立的函数或类
  ///
  /// **当前实现说明**：
  /// 根据资产查询上传状态，结合数据库和任务状态
  /// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
  /// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
  ///
  /// **优化措施**：
  /// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
  /// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
  /// - 状态去重，只在状态真正改变时才 yield
  /// - 同时监听上传任务表和远程资产表，确保状态实时更新
  ///
  /// **参数**：
  /// - [assetId] - 资产的唯一标识符（localId 或 id）
  /// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态，但不作为唯一依据）
  /// - [checksum] - 资产的 checksum（可选，用于查询远程资产表）
  ///
  /// **状态判断逻辑（优先级顺序）**：
  /// 1. 优先查询上传任务状态（最可靠的数据源）
  /// 2. 如果没有任务记录，查询远程资产表（通过 checksum）
  /// 3. 如果 hasRemote == true，也显示已上传（快速路径，但不作为唯一依据）
  /// 4. 否则显示未上传
  ///
  /// Copied from [assetUploadStatus].
  AssetUploadStatusProvider(
    String assetId,
    bool hasRemote,
    String? checksum,
  ) : this._internal(
          (ref) => assetUploadStatus(
            ref as AssetUploadStatusRef,
            assetId,
            hasRemote,
            checksum,
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
          checksum: checksum,
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
    required this.checksum,
  }) : super.internal();

  final String assetId;
  final bool hasRemote;
  final String? checksum;

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
        checksum: checksum,
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
        other.hasRemote == hasRemote &&
        other.checksum == checksum;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, assetId.hashCode);
    hash = _SystemHash.combine(hash, hasRemote.hashCode);
    hash = _SystemHash.combine(hash, checksum.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AssetUploadStatusRef
    on AutoDisposeStreamProviderRef<AssetUploadStatusInfo> {
  /// The parameter `assetId` of this provider.
  String get assetId;

  /// The parameter `hasRemote` of this provider.
  bool get hasRemote;

  /// The parameter `checksum` of this provider.
  String? get checksum;
}

class _AssetUploadStatusProviderElement
    extends AutoDisposeStreamProviderElement<AssetUploadStatusInfo>
    with AssetUploadStatusRef {
  _AssetUploadStatusProviderElement(super.provider);

  @override
  String get assetId => (origin as AssetUploadStatusProvider).assetId;
  @override
  bool get hasRemote => (origin as AssetUploadStatusProvider).hasRemote;
  @override
  String? get checksum => (origin as AssetUploadStatusProvider).checksum;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
