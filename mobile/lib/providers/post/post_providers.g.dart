// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$postApiClientHash() => r'c21a567ae395d8c54308ef0c9ffc6bfe13a6f7a5';

/// PostApiClient Provider
///
/// Copied from [postApiClient].
@ProviderFor(postApiClient)
final postApiClientProvider = AutoDisposeProvider<PostApiClient>.internal(
  postApiClient,
  name: r'postApiClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postApiClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PostApiClientRef = AutoDisposeProviderRef<PostApiClient>;
String _$postServiceBaseHash() => r'ce7131950fc4e5b761cac93bdbd8b0fe659511dc';

/// PostService Provider（基础版本，不包含 PostTaskManager）
///
/// Copied from [postServiceBase].
@ProviderFor(postServiceBase)
final postServiceBaseProvider = AutoDisposeProvider<PostService>.internal(
  postServiceBase,
  name: r'postServiceBaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postServiceBaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PostServiceBaseRef = AutoDisposeProviderRef<PostService>;
String _$postTaskManagerHash() => r'1b69922471a7c070fc68866404e8e225c9656df3';

/// PostTaskManager Provider
///
/// Copied from [postTaskManager].
@ProviderFor(postTaskManager)
final postTaskManagerProvider =
    AutoDisposeFutureProvider<PostTaskManager>.internal(
  postTaskManager,
  name: r'postTaskManagerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$postTaskManagerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PostTaskManagerRef = AutoDisposeFutureProviderRef<PostTaskManager>;
String _$postServiceHash() => r'9518f976339000f39d6ca18fb91a00437808a039';

/// PostService Provider（完整版本，包含 PostTaskManager）
///
/// Copied from [postService].
@ProviderFor(postService)
final postServiceProvider = AutoDisposeFutureProvider<PostService>.internal(
  postService,
  name: r'postServiceProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$postServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PostServiceRef = AutoDisposeFutureProviderRef<PostService>;
String _$commentServiceHash() => r'6ef34b9ac5547d55e6c73b917ec4e9cec4487417';

/// CommentService Provider
///
/// Copied from [commentService].
@ProviderFor(commentService)
final commentServiceProvider = AutoDisposeProvider<CommentService>.internal(
  commentService,
  name: r'commentServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$commentServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CommentServiceRef = AutoDisposeProviderRef<CommentService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
