// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupFeedProviderHash() => r'8571dce0f0ef6ffcf5ead65a0f4b6257ca3ef1c3';

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

abstract class _$GroupFeedProvider
    extends BuildlessAutoDisposeAsyncNotifier<List<Post>> {
  late final String groupUuid;

  FutureOr<List<Post>> build(
    String groupUuid,
  );
}

/// 圈子 Feed 流 Provider
/// 使用 family 参数区分不同的圈子，管理 Feed 流状态（内存中）
///
/// 设计原则：
/// - build() 方法直接加载数据，不返回占位值
/// - 错误时抛出异常，让 Riverpod 处理错误状态
///
/// Copied from [GroupFeedProvider].
@ProviderFor(GroupFeedProvider)
const groupFeedProviderProvider = GroupFeedProviderFamily();

/// 圈子 Feed 流 Provider
/// 使用 family 参数区分不同的圈子，管理 Feed 流状态（内存中）
///
/// 设计原则：
/// - build() 方法直接加载数据，不返回占位值
/// - 错误时抛出异常，让 Riverpod 处理错误状态
///
/// Copied from [GroupFeedProvider].
class GroupFeedProviderFamily extends Family<AsyncValue<List<Post>>> {
  /// 圈子 Feed 流 Provider
  /// 使用 family 参数区分不同的圈子，管理 Feed 流状态（内存中）
  ///
  /// 设计原则：
  /// - build() 方法直接加载数据，不返回占位值
  /// - 错误时抛出异常，让 Riverpod 处理错误状态
  ///
  /// Copied from [GroupFeedProvider].
  const GroupFeedProviderFamily();

  /// 圈子 Feed 流 Provider
  /// 使用 family 参数区分不同的圈子，管理 Feed 流状态（内存中）
  ///
  /// 设计原则：
  /// - build() 方法直接加载数据，不返回占位值
  /// - 错误时抛出异常，让 Riverpod 处理错误状态
  ///
  /// Copied from [GroupFeedProvider].
  GroupFeedProviderProvider call(
    String groupUuid,
  ) {
    return GroupFeedProviderProvider(
      groupUuid,
    );
  }

  @override
  GroupFeedProviderProvider getProviderOverride(
    covariant GroupFeedProviderProvider provider,
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
  String? get name => r'groupFeedProviderProvider';
}

/// 圈子 Feed 流 Provider
/// 使用 family 参数区分不同的圈子，管理 Feed 流状态（内存中）
///
/// 设计原则：
/// - build() 方法直接加载数据，不返回占位值
/// - 错误时抛出异常，让 Riverpod 处理错误状态
///
/// Copied from [GroupFeedProvider].
class GroupFeedProviderProvider extends AutoDisposeAsyncNotifierProviderImpl<
    GroupFeedProvider, List<Post>> {
  /// 圈子 Feed 流 Provider
  /// 使用 family 参数区分不同的圈子，管理 Feed 流状态（内存中）
  ///
  /// 设计原则：
  /// - build() 方法直接加载数据，不返回占位值
  /// - 错误时抛出异常，让 Riverpod 处理错误状态
  ///
  /// Copied from [GroupFeedProvider].
  GroupFeedProviderProvider(
    String groupUuid,
  ) : this._internal(
          () => GroupFeedProvider()..groupUuid = groupUuid,
          from: groupFeedProviderProvider,
          name: r'groupFeedProviderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupFeedProviderHash,
          dependencies: GroupFeedProviderFamily._dependencies,
          allTransitiveDependencies:
              GroupFeedProviderFamily._allTransitiveDependencies,
          groupUuid: groupUuid,
        );

  GroupFeedProviderProvider._internal(
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
  FutureOr<List<Post>> runNotifierBuild(
    covariant GroupFeedProvider notifier,
  ) {
    return notifier.build(
      groupUuid,
    );
  }

  @override
  Override overrideWith(GroupFeedProvider Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupFeedProviderProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<GroupFeedProvider, List<Post>>
      createElement() {
    return _GroupFeedProviderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupFeedProviderProvider && other.groupUuid == groupUuid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupUuid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GroupFeedProviderRef on AutoDisposeAsyncNotifierProviderRef<List<Post>> {
  /// The parameter `groupUuid` of this provider.
  String get groupUuid;
}

class _GroupFeedProviderProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupFeedProvider,
        List<Post>> with GroupFeedProviderRef {
  _GroupFeedProviderProviderElement(super.provider);

  @override
  String get groupUuid => (origin as GroupFeedProviderProvider).groupUuid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
