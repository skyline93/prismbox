// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_thread_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$newThreadHash() => r'72a8ea7a80cde80632aaf978cd49e6186f15f39f';

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

abstract class _$NewThread
    extends BuildlessAutoDisposeNotifier<NewThreadState> {
  late final String groupId;

  NewThreadState build(
    String groupId,
  );
}

/// See also [NewThread].
@ProviderFor(NewThread)
const newThreadProvider = NewThreadFamily();

/// See also [NewThread].
class NewThreadFamily extends Family<NewThreadState> {
  /// See also [NewThread].
  const NewThreadFamily();

  /// See also [NewThread].
  NewThreadProvider call(
    String groupId,
  ) {
    return NewThreadProvider(
      groupId,
    );
  }

  @override
  NewThreadProvider getProviderOverride(
    covariant NewThreadProvider provider,
  ) {
    return call(
      provider.groupId,
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
  String? get name => r'newThreadProvider';
}

/// See also [NewThread].
class NewThreadProvider
    extends AutoDisposeNotifierProviderImpl<NewThread, NewThreadState> {
  /// See also [NewThread].
  NewThreadProvider(
    String groupId,
  ) : this._internal(
          () => NewThread()..groupId = groupId,
          from: newThreadProvider,
          name: r'newThreadProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$newThreadHash,
          dependencies: NewThreadFamily._dependencies,
          allTransitiveDependencies: NewThreadFamily._allTransitiveDependencies,
          groupId: groupId,
        );

  NewThreadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.groupId,
  }) : super.internal();

  final String groupId;

  @override
  NewThreadState runNotifierBuild(
    covariant NewThread notifier,
  ) {
    return notifier.build(
      groupId,
    );
  }

  @override
  Override overrideWith(NewThread Function() create) {
    return ProviderOverride(
      origin: this,
      override: NewThreadProvider._internal(
        () => create()..groupId = groupId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        groupId: groupId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<NewThread, NewThreadState>
      createElement() {
    return _NewThreadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is NewThreadProvider && other.groupId == groupId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, groupId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin NewThreadRef on AutoDisposeNotifierProviderRef<NewThreadState> {
  /// The parameter `groupId` of this provider.
  String get groupId;
}

class _NewThreadProviderElement
    extends AutoDisposeNotifierProviderElement<NewThread, NewThreadState>
    with NewThreadRef {
  _NewThreadProviderElement(super.provider);

  @override
  String get groupId => (origin as NewThreadProvider).groupId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
