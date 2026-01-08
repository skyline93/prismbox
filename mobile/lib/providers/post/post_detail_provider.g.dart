// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postDetailProviderHash() =>
    r'07661f9a0a4bc11d7ba65bbe383e4989faf3b4ec';

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

abstract class _$PostDetailProvider
    extends BuildlessAutoDisposeAsyncNotifier<Post?> {
  late final String key;

  FutureOr<Post?> build(
    String key,
  );
}

/// 帖子详情 Provider
/// 管理帖子详情状态（内存中）
/// 使用 family 参数，参数为 "{groupUuid}:{postId}"
///
/// Copied from [PostDetailProvider].
@ProviderFor(PostDetailProvider)
const postDetailProviderProvider = PostDetailProviderFamily();

/// 帖子详情 Provider
/// 管理帖子详情状态（内存中）
/// 使用 family 参数，参数为 "{groupUuid}:{postId}"
///
/// Copied from [PostDetailProvider].
class PostDetailProviderFamily extends Family<AsyncValue<Post?>> {
  /// 帖子详情 Provider
  /// 管理帖子详情状态（内存中）
  /// 使用 family 参数，参数为 "{groupUuid}:{postId}"
  ///
  /// Copied from [PostDetailProvider].
  const PostDetailProviderFamily();

  /// 帖子详情 Provider
  /// 管理帖子详情状态（内存中）
  /// 使用 family 参数，参数为 "{groupUuid}:{postId}"
  ///
  /// Copied from [PostDetailProvider].
  PostDetailProviderProvider call(
    String key,
  ) {
    return PostDetailProviderProvider(
      key,
    );
  }

  @override
  PostDetailProviderProvider getProviderOverride(
    covariant PostDetailProviderProvider provider,
  ) {
    return call(
      provider.key,
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
  String? get name => r'postDetailProviderProvider';
}

/// 帖子详情 Provider
/// 管理帖子详情状态（内存中）
/// 使用 family 参数，参数为 "{groupUuid}:{postId}"
///
/// Copied from [PostDetailProvider].
class PostDetailProviderProvider
    extends AutoDisposeAsyncNotifierProviderImpl<PostDetailProvider, Post?> {
  /// 帖子详情 Provider
  /// 管理帖子详情状态（内存中）
  /// 使用 family 参数，参数为 "{groupUuid}:{postId}"
  ///
  /// Copied from [PostDetailProvider].
  PostDetailProviderProvider(
    String key,
  ) : this._internal(
          () => PostDetailProvider()..key = key,
          from: postDetailProviderProvider,
          name: r'postDetailProviderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postDetailProviderHash,
          dependencies: PostDetailProviderFamily._dependencies,
          allTransitiveDependencies:
              PostDetailProviderFamily._allTransitiveDependencies,
          key: key,
        );

  PostDetailProviderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.key,
  }) : super.internal();

  final String key;

  @override
  FutureOr<Post?> runNotifierBuild(
    covariant PostDetailProvider notifier,
  ) {
    return notifier.build(
      key,
    );
  }

  @override
  Override overrideWith(PostDetailProvider Function() create) {
    return ProviderOverride(
      origin: this,
      override: PostDetailProviderProvider._internal(
        () => create()..key = key,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        key: key,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PostDetailProvider, Post?>
      createElement() {
    return _PostDetailProviderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostDetailProviderProvider && other.key == key;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, key.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostDetailProviderRef on AutoDisposeAsyncNotifierProviderRef<Post?> {
  /// The parameter `key` of this provider.
  String get key;
}

class _PostDetailProviderProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<PostDetailProvider, Post?>
    with PostDetailProviderRef {
  _PostDetailProviderProviderElement(super.provider);

  @override
  String get key => (origin as PostDetailProviderProvider).key;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
