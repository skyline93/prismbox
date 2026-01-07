// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trash_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$trashAssetsHash() => r'da12e5cf184af77561bf656973a91e3c64172961';

/// 回收站数据 Provider
/// 提供已删除的本地和远程资产数据
///
/// Copied from [trashAssets].
@ProviderFor(trashAssets)
final trashAssetsProvider = AutoDisposeFutureProvider<List<BaseAsset>>.internal(
  trashAssets,
  name: r'trashAssetsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$trashAssetsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrashAssetsRef = AutoDisposeFutureProviderRef<List<BaseAsset>>;
String _$trashSectionsHash() => r'cde7caa9596ab4ff46763f1890bb07431ad45ea1';

/// 回收站分组数据 Provider
/// 将回收站数据转换为按时间分组的 TimelineSection 列表
///
/// Copied from [trashSections].
@ProviderFor(trashSections)
final trashSectionsProvider =
    AutoDisposeFutureProvider<List<TimelineSection>>.internal(
  trashSections,
  name: r'trashSectionsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trashSectionsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TrashSectionsRef = AutoDisposeFutureProviderRef<List<TimelineSection>>;
String _$trashFilterModeHash() => r'b7eb074669c3d5d8a3b98a0ebec92e69cc4ef431';

/// 回收站过滤模式 Provider
///
/// Copied from [TrashFilterMode].
@ProviderFor(TrashFilterMode)
final trashFilterModeProvider =
    AutoDisposeNotifierProvider<TrashFilterMode, TrashFilterModeEnum>.internal(
  TrashFilterMode.new,
  name: r'trashFilterModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$trashFilterModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$TrashFilterMode = AutoDisposeNotifier<TrashFilterModeEnum>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
