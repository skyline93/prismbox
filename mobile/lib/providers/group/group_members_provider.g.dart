// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_members_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupMembersProviderHash() =>
    r'549066619b033fba97a8805e7d3acc5d649144a6';

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

abstract class _$GroupMembersProvider
    extends BuildlessAutoDisposeAsyncNotifier<List<GroupMember>> {
  late final String groupUuid;

  FutureOr<List<GroupMember>> build(
    String groupUuid,
  );
}

/// 圈子成员列表 Provider
/// 使用 family 参数区分不同的圈子
///
/// Copied from [GroupMembersProvider].
@ProviderFor(GroupMembersProvider)
const groupMembersProviderProvider = GroupMembersProviderFamily();

/// 圈子成员列表 Provider
/// 使用 family 参数区分不同的圈子
///
/// Copied from [GroupMembersProvider].
class GroupMembersProviderFamily extends Family<AsyncValue<List<GroupMember>>> {
  /// 圈子成员列表 Provider
  /// 使用 family 参数区分不同的圈子
  ///
  /// Copied from [GroupMembersProvider].
  const GroupMembersProviderFamily();

  /// 圈子成员列表 Provider
  /// 使用 family 参数区分不同的圈子
  ///
  /// Copied from [GroupMembersProvider].
  GroupMembersProviderProvider call(
    String groupUuid,
  ) {
    return GroupMembersProviderProvider(
      groupUuid,
    );
  }

  @override
  GroupMembersProviderProvider getProviderOverride(
    covariant GroupMembersProviderProvider provider,
  ) {
    return call(
      provider.groupUuid,
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
  String? get name => r'groupMembersProviderProvider';
}

/// 圈子成员列表 Provider
/// 使用 family 参数区分不同的圈子
///
/// Copied from [GroupMembersProvider].
class GroupMembersProviderProvider extends AutoDisposeAsyncNotifierProviderImpl<
    GroupMembersProvider, List<GroupMember>> {
  /// 圈子成员列表 Provider
  /// 使用 family 参数区分不同的圈子
  ///
  /// Copied from [GroupMembersProvider].
  GroupMembersProviderProvider(
    String groupUuid,
  ) : this._internal(
          () => GroupMembersProvider()..groupUuid = groupUuid,
          from: groupMembersProviderProvider,
          name: r'groupMembersProviderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupMembersProviderHash,
          dependencies: GroupMembersProviderFamily._dependencies,
          allTransitiveDependencies:
              GroupMembersProviderFamily._allTransitiveDependencies,
          groupUuid: groupUuid,
        );

  GroupMembersProviderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupUuid,
  }) : super.internal();

  final String groupUuid;

  @override
  FutureOr<List<GroupMember>> runNotifierBuild(
    covariant GroupMembersProvider notifier,
  ) {
    return notifier.build(
      groupUuid,
    );
  }

  @override
  Override overrideWith(GroupMembersProvider Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupMembersProviderProvider._internal(
        () => create()..groupUuid = groupUuid,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupUuid: groupUuid,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<GroupMembersProvider,
      List<GroupMember>> createElement() {
    return _GroupMembersProviderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersProviderProvider &&
        other.groupUuid == groupUuid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupUuid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GroupMembersProviderRef
    on AutoDisposeAsyncNotifierProviderRef<List<GroupMember>> {
  /// The parameter `groupUuid` of this provider.
  String get groupUuid;
}

class _GroupMembersProviderProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupMembersProvider,
        List<GroupMember>> with GroupMembersProviderRef {
  _GroupMembersProviderProviderElement(super.provider);

  @override
  String get groupUuid => (origin as GroupMembersProviderProvider).groupUuid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
