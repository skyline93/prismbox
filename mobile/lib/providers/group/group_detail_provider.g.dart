// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupDetailProviderHash() =>
    r'f92068155491344687a2f9f84ed820ea4a6d7da1';

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

abstract class _$GroupDetailProvider
    extends BuildlessAutoDisposeAsyncNotifier<models.GroupDetail?> {
  late final String groupUuid;

  FutureOr<models.GroupDetail?> build(
    String groupUuid,
  );
}

/// 圈子详情 Provider
/// 使用 family 参数区分不同的圈子
///
/// 设计原则：
/// - build() 方法直接加载数据，不返回占位值
/// - 错误时抛出异常，让 Riverpod 处理错误状态
///
/// Copied from [GroupDetailProvider].
@ProviderFor(GroupDetailProvider)
const groupDetailProviderProvider = GroupDetailProviderFamily();

/// 圈子详情 Provider
/// 使用 family 参数区分不同的圈子
///
/// 设计原则：
/// - build() 方法直接加载数据，不返回占位值
/// - 错误时抛出异常，让 Riverpod 处理错误状态
///
/// Copied from [GroupDetailProvider].
class GroupDetailProviderFamily
    extends Family<AsyncValue<models.GroupDetail?>> {
  /// 圈子详情 Provider
  /// 使用 family 参数区分不同的圈子
  ///
  /// 设计原则：
  /// - build() 方法直接加载数据，不返回占位值
  /// - 错误时抛出异常，让 Riverpod 处理错误状态
  ///
  /// Copied from [GroupDetailProvider].
  const GroupDetailProviderFamily();

  /// 圈子详情 Provider
  /// 使用 family 参数区分不同的圈子
  ///
  /// 设计原则：
  /// - build() 方法直接加载数据，不返回占位值
  /// - 错误时抛出异常，让 Riverpod 处理错误状态
  ///
  /// Copied from [GroupDetailProvider].
  GroupDetailProviderProvider call(
    String groupUuid,
  ) {
    return GroupDetailProviderProvider(
      groupUuid,
    );
  }

  @override
  GroupDetailProviderProvider getProviderOverride(
    covariant GroupDetailProviderProvider provider,
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
  String? get name => r'groupDetailProviderProvider';
}

/// 圈子详情 Provider
/// 使用 family 参数区分不同的圈子
///
/// 设计原则：
/// - build() 方法直接加载数据，不返回占位值
/// - 错误时抛出异常，让 Riverpod 处理错误状态
///
/// Copied from [GroupDetailProvider].
class GroupDetailProviderProvider extends AutoDisposeAsyncNotifierProviderImpl<
    GroupDetailProvider, models.GroupDetail?> {
  /// 圈子详情 Provider
  /// 使用 family 参数区分不同的圈子
  ///
  /// 设计原则：
  /// - build() 方法直接加载数据，不返回占位值
  /// - 错误时抛出异常，让 Riverpod 处理错误状态
  ///
  /// Copied from [GroupDetailProvider].
  GroupDetailProviderProvider(
    String groupUuid,
  ) : this._internal(
          () => GroupDetailProvider()..groupUuid = groupUuid,
          from: groupDetailProviderProvider,
          name: r'groupDetailProviderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$groupDetailProviderHash,
          dependencies: GroupDetailProviderFamily._dependencies,
          allTransitiveDependencies:
              GroupDetailProviderFamily._allTransitiveDependencies,
          groupUuid: groupUuid,
        );

  GroupDetailProviderProvider._internal(
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
  FutureOr<models.GroupDetail?> runNotifierBuild(
    covariant GroupDetailProvider notifier,
  ) {
    return notifier.build(
      groupUuid,
    );
  }

  @override
  Override overrideWith(GroupDetailProvider Function() create) {
    return ProviderOverride(
      origin: this,
      override: GroupDetailProviderProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<GroupDetailProvider,
      models.GroupDetail?> createElement() {
    return _GroupDetailProviderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupDetailProviderProvider && other.groupUuid == groupUuid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupUuid.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin GroupDetailProviderRef
    on AutoDisposeAsyncNotifierProviderRef<models.GroupDetail?> {
  /// The parameter `groupUuid` of this provider.
  String get groupUuid;
}

class _GroupDetailProviderProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<GroupDetailProvider,
        models.GroupDetail?> with GroupDetailProviderRef {
  _GroupDetailProviderProviderElement(super.provider);

  @override
  String get groupUuid => (origin as GroupDetailProviderProvider).groupUuid;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
