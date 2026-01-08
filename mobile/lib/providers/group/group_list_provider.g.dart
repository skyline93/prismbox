// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupApiClientHash() => r'8ac2d19265249f49b2fce5f8b1d6033b60b0547c';

/// GroupApiClient Provider
///
/// Copied from [groupApiClient].
@ProviderFor(groupApiClient)
final groupApiClientProvider = AutoDisposeProvider<GroupApiClient>.internal(
  groupApiClient,
  name: r'groupApiClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupApiClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GroupApiClientRef = AutoDisposeProviderRef<GroupApiClient>;
String _$groupServiceHash() => r'4208867677afbd7110c5215ba768ffb7c472244f';

/// GroupService Provider
///
/// Copied from [groupService].
@ProviderFor(groupService)
final groupServiceProvider = AutoDisposeProvider<GroupService>.internal(
  groupService,
  name: r'groupServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$groupServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GroupServiceRef = AutoDisposeProviderRef<GroupService>;
String _$groupListProviderHash() => r'b651a867b3dc1a61f12cf133534b6ffd783877db';

/// 圈子列表 Provider
/// 管理圈子列表的状态（内存中）
///
/// Copied from [GroupListProvider].
@ProviderFor(GroupListProvider)
final groupListProviderProvider =
    AutoDisposeAsyncNotifierProvider<GroupListProvider, List<Group>>.internal(
  GroupListProvider.new,
  name: r'groupListProviderProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupListProviderHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$GroupListProvider = AutoDisposeAsyncNotifier<List<Group>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
