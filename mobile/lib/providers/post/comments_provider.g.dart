// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentsProviderHash() => r'e45a55f0363f2b8963d35c256bbc807d604f8dcb';

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

abstract class _$CommentsProvider
    extends BuildlessAutoDisposeAsyncNotifier<List<Comment>> {
  late final int postId;

  FutureOr<List<Comment>> build(
    int postId,
  );
}

/// 评论列表 Provider
/// 管理评论列表状态（内存中）
/// 使用 family 参数，参数为 postId (int)
///
/// Copied from [CommentsProvider].
@ProviderFor(CommentsProvider)
const commentsProviderProvider = CommentsProviderFamily();

/// 评论列表 Provider
/// 管理评论列表状态（内存中）
/// 使用 family 参数，参数为 postId (int)
///
/// Copied from [CommentsProvider].
class CommentsProviderFamily extends Family<AsyncValue<List<Comment>>> {
  /// 评论列表 Provider
  /// 管理评论列表状态（内存中）
  /// 使用 family 参数，参数为 postId (int)
  ///
  /// Copied from [CommentsProvider].
  const CommentsProviderFamily();

  /// 评论列表 Provider
  /// 管理评论列表状态（内存中）
  /// 使用 family 参数，参数为 postId (int)
  ///
  /// Copied from [CommentsProvider].
  CommentsProviderProvider call(
    int postId,
  ) {
    return CommentsProviderProvider(
      postId,
    );
  }

  @override
  CommentsProviderProvider getProviderOverride(
    covariant CommentsProviderProvider provider,
  ) {
    return call(
      provider.postId,
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
  String? get name => r'commentsProviderProvider';
}

/// 评论列表 Provider
/// 管理评论列表状态（内存中）
/// 使用 family 参数，参数为 postId (int)
///
/// Copied from [CommentsProvider].
class CommentsProviderProvider extends AutoDisposeAsyncNotifierProviderImpl<
    CommentsProvider, List<Comment>> {
  /// 评论列表 Provider
  /// 管理评论列表状态（内存中）
  /// 使用 family 参数，参数为 postId (int)
  ///
  /// Copied from [CommentsProvider].
  CommentsProviderProvider(
    int postId,
  ) : this._internal(
          () => CommentsProvider()..postId = postId,
          from: commentsProviderProvider,
          name: r'commentsProviderProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentsProviderHash,
          dependencies: CommentsProviderFamily._dependencies,
          allTransitiveDependencies:
              CommentsProviderFamily._allTransitiveDependencies,
          postId: postId,
        );

  CommentsProviderProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.postId,
  }) : super.internal();

  final int postId;

  @override
  FutureOr<List<Comment>> runNotifierBuild(
    covariant CommentsProvider notifier,
  ) {
    return notifier.build(
      postId,
    );
  }

  @override
  Override overrideWith(CommentsProvider Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentsProviderProvider._internal(
        () => create()..postId = postId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        postId: postId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<CommentsProvider, List<Comment>>
      createElement() {
    return _CommentsProviderProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsProviderProvider && other.postId == postId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, postId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CommentsProviderRef
    on AutoDisposeAsyncNotifierProviderRef<List<Comment>> {
  /// The parameter `postId` of this provider.
  int get postId;
}

class _CommentsProviderProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<CommentsProvider,
        List<Comment>> with CommentsProviderRef {
  _CommentsProviderProviderElement(super.provider);

  @override
  int get postId => (origin as CommentsProviderProvider).postId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
