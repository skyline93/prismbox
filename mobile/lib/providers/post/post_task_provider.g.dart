// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_task_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postTaskHash() => r'52ac0f5e084999a9ab0e34b2cee51293bcecb5b6';

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

/// 帖子任务状态 Provider（按任务 ID）
///
/// Copied from [postTask].
@ProviderFor(postTask)
const postTaskProvider = PostTaskFamily();

/// 帖子任务状态 Provider（按任务 ID）
///
/// Copied from [postTask].
class PostTaskFamily extends Family<AsyncValue<PostTaskEntityData?>> {
  /// 帖子任务状态 Provider（按任务 ID）
  ///
  /// Copied from [postTask].
  const PostTaskFamily();

  /// 帖子任务状态 Provider（按任务 ID）
  ///
  /// Copied from [postTask].
  PostTaskProvider call(
    String taskId,
  ) {
    return PostTaskProvider(
      taskId,
    );
  }

  @override
  PostTaskProvider getProviderOverride(
    covariant PostTaskProvider provider,
  ) {
    return call(
      provider.taskId,
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
  String? get name => r'postTaskProvider';
}

/// 帖子任务状态 Provider（按任务 ID）
///
/// Copied from [postTask].
class PostTaskProvider extends AutoDisposeFutureProvider<PostTaskEntityData?> {
  /// 帖子任务状态 Provider（按任务 ID）
  ///
  /// Copied from [postTask].
  PostTaskProvider(
    String taskId,
  ) : this._internal(
          (ref) => postTask(
            ref as PostTaskRef,
            taskId,
          ),
          from: postTaskProvider,
          name: r'postTaskProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postTaskHash,
          dependencies: PostTaskFamily._dependencies,
          allTransitiveDependencies: PostTaskFamily._allTransitiveDependencies,
          taskId: taskId,
        );

  PostTaskProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.taskId,
  }) : super.internal();

  final String taskId;

  @override
  Override overrideWith(
    FutureOr<PostTaskEntityData?> Function(PostTaskRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostTaskProvider._internal(
        (ref) => create(ref as PostTaskRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        taskId: taskId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<PostTaskEntityData?> createElement() {
    return _PostTaskProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostTaskProvider && other.taskId == taskId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, taskId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostTaskRef on AutoDisposeFutureProviderRef<PostTaskEntityData?> {
  /// The parameter `taskId` of this provider.
  String get taskId;
}

class _PostTaskProviderElement
    extends AutoDisposeFutureProviderElement<PostTaskEntityData?>
    with PostTaskRef {
  _PostTaskProviderElement(super.provider);

  @override
  String get taskId => (origin as PostTaskProvider).taskId;
}

String _$postTaskStatusStreamHash() =>
    r'd1692d82c4edacd5bfb0abb612654b42e0778e7d';

/// 帖子任务状态流 Provider（按任务 ID）
/// 监听任务状态变化
///
/// Copied from [postTaskStatusStream].
@ProviderFor(postTaskStatusStream)
const postTaskStatusStreamProvider = PostTaskStatusStreamFamily();

/// 帖子任务状态流 Provider（按任务 ID）
/// 监听任务状态变化
///
/// Copied from [postTaskStatusStream].
class PostTaskStatusStreamFamily
    extends Family<AsyncValue<PostTaskStatusUpdate>> {
  /// 帖子任务状态流 Provider（按任务 ID）
  /// 监听任务状态变化
  ///
  /// Copied from [postTaskStatusStream].
  const PostTaskStatusStreamFamily();

  /// 帖子任务状态流 Provider（按任务 ID）
  /// 监听任务状态变化
  ///
  /// Copied from [postTaskStatusStream].
  PostTaskStatusStreamProvider call(
    String taskId,
  ) {
    return PostTaskStatusStreamProvider(
      taskId,
    );
  }

  @override
  PostTaskStatusStreamProvider getProviderOverride(
    covariant PostTaskStatusStreamProvider provider,
  ) {
    return call(
      provider.taskId,
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
  String? get name => r'postTaskStatusStreamProvider';
}

/// 帖子任务状态流 Provider（按任务 ID）
/// 监听任务状态变化
///
/// Copied from [postTaskStatusStream].
class PostTaskStatusStreamProvider
    extends AutoDisposeStreamProvider<PostTaskStatusUpdate> {
  /// 帖子任务状态流 Provider（按任务 ID）
  /// 监听任务状态变化
  ///
  /// Copied from [postTaskStatusStream].
  PostTaskStatusStreamProvider(
    String taskId,
  ) : this._internal(
          (ref) => postTaskStatusStream(
            ref as PostTaskStatusStreamRef,
            taskId,
          ),
          from: postTaskStatusStreamProvider,
          name: r'postTaskStatusStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postTaskStatusStreamHash,
          dependencies: PostTaskStatusStreamFamily._dependencies,
          allTransitiveDependencies:
              PostTaskStatusStreamFamily._allTransitiveDependencies,
          taskId: taskId,
        );

  PostTaskStatusStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.taskId,
  }) : super.internal();

  final String taskId;

  @override
  Override overrideWith(
    Stream<PostTaskStatusUpdate> Function(PostTaskStatusStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostTaskStatusStreamProvider._internal(
        (ref) => create(ref as PostTaskStatusStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        taskId: taskId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<PostTaskStatusUpdate> createElement() {
    return _PostTaskStatusStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostTaskStatusStreamProvider && other.taskId == taskId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, taskId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostTaskStatusStreamRef
    on AutoDisposeStreamProviderRef<PostTaskStatusUpdate> {
  /// The parameter `taskId` of this provider.
  String get taskId;
}

class _PostTaskStatusStreamProviderElement
    extends AutoDisposeStreamProviderElement<PostTaskStatusUpdate>
    with PostTaskStatusStreamRef {
  _PostTaskStatusStreamProviderElement(super.provider);

  @override
  String get taskId => (origin as PostTaskStatusStreamProvider).taskId;
}

String _$postTasksHash() => r'b37c13f4b58424506495328c6fcfeaee0de263dd';

/// 用户的所有帖子任务列表 Provider
///
/// Copied from [postTasks].
@ProviderFor(postTasks)
const postTasksProvider = PostTasksFamily();

/// 用户的所有帖子任务列表 Provider
///
/// Copied from [postTasks].
class PostTasksFamily extends Family<AsyncValue<List<PostTaskEntityData>>> {
  /// 用户的所有帖子任务列表 Provider
  ///
  /// Copied from [postTasks].
  const PostTasksFamily();

  /// 用户的所有帖子任务列表 Provider
  ///
  /// Copied from [postTasks].
  PostTasksProvider call(
    String userId,
  ) {
    return PostTasksProvider(
      userId,
    );
  }

  @override
  PostTasksProvider getProviderOverride(
    covariant PostTasksProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'postTasksProvider';
}

/// 用户的所有帖子任务列表 Provider
///
/// Copied from [postTasks].
class PostTasksProvider
    extends AutoDisposeFutureProvider<List<PostTaskEntityData>> {
  /// 用户的所有帖子任务列表 Provider
  ///
  /// Copied from [postTasks].
  PostTasksProvider(
    String userId,
  ) : this._internal(
          (ref) => postTasks(
            ref as PostTasksRef,
            userId,
          ),
          from: postTasksProvider,
          name: r'postTasksProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$postTasksHash,
          dependencies: PostTasksFamily._dependencies,
          allTransitiveDependencies: PostTasksFamily._allTransitiveDependencies,
          userId: userId,
        );

  PostTasksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<List<PostTaskEntityData>> Function(PostTasksRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PostTasksProvider._internal(
        (ref) => create(ref as PostTasksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostTaskEntityData>> createElement() {
    return _PostTasksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PostTasksProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin PostTasksRef on AutoDisposeFutureProviderRef<List<PostTaskEntityData>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _PostTasksProviderElement
    extends AutoDisposeFutureProviderElement<List<PostTaskEntityData>>
    with PostTasksRef {
  _PostTasksProviderElement(super.provider);

  @override
  String get userId => (origin as PostTasksProvider).userId;
}

String _$failedPostTasksHash() => r'756a56a05df9ee27d80294b63138397a6894e44e';

/// 失败的帖子任务列表 Provider
///
/// Copied from [failedPostTasks].
@ProviderFor(failedPostTasks)
const failedPostTasksProvider = FailedPostTasksFamily();

/// 失败的帖子任务列表 Provider
///
/// Copied from [failedPostTasks].
class FailedPostTasksFamily
    extends Family<AsyncValue<List<PostTaskEntityData>>> {
  /// 失败的帖子任务列表 Provider
  ///
  /// Copied from [failedPostTasks].
  const FailedPostTasksFamily();

  /// 失败的帖子任务列表 Provider
  ///
  /// Copied from [failedPostTasks].
  FailedPostTasksProvider call(
    String userId,
  ) {
    return FailedPostTasksProvider(
      userId,
    );
  }

  @override
  FailedPostTasksProvider getProviderOverride(
    covariant FailedPostTasksProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'failedPostTasksProvider';
}

/// 失败的帖子任务列表 Provider
///
/// Copied from [failedPostTasks].
class FailedPostTasksProvider
    extends AutoDisposeFutureProvider<List<PostTaskEntityData>> {
  /// 失败的帖子任务列表 Provider
  ///
  /// Copied from [failedPostTasks].
  FailedPostTasksProvider(
    String userId,
  ) : this._internal(
          (ref) => failedPostTasks(
            ref as FailedPostTasksRef,
            userId,
          ),
          from: failedPostTasksProvider,
          name: r'failedPostTasksProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$failedPostTasksHash,
          dependencies: FailedPostTasksFamily._dependencies,
          allTransitiveDependencies:
              FailedPostTasksFamily._allTransitiveDependencies,
          userId: userId,
        );

  FailedPostTasksProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<List<PostTaskEntityData>> Function(FailedPostTasksRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FailedPostTasksProvider._internal(
        (ref) => create(ref as FailedPostTasksRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<PostTaskEntityData>> createElement() {
    return _FailedPostTasksProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FailedPostTasksProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FailedPostTasksRef
    on AutoDisposeFutureProviderRef<List<PostTaskEntityData>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _FailedPostTasksProviderElement
    extends AutoDisposeFutureProviderElement<List<PostTaskEntityData>>
    with FailedPostTasksRef {
  _FailedPostTasksProviderElement(super.provider);

  @override
  String get userId => (origin as FailedPostTasksProvider).userId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
