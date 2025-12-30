// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'encrypted_space_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$encryptedSpaceServiceHash() =>
    r'c0029f03d6e07f84906da1a4608e2a1d93279c75';

/// EncryptedSpaceService Provider
///
/// 提供加密空间服务实例，用于管理加密相册和资产
///
/// Copied from [encryptedSpaceService].
@ProviderFor(encryptedSpaceService)
final encryptedSpaceServiceProvider =
    AutoDisposeFutureProvider<EncryptedSpaceService>.internal(
  encryptedSpaceService,
  name: r'encryptedSpaceServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$encryptedSpaceServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef EncryptedSpaceServiceRef
    = AutoDisposeFutureProviderRef<EncryptedSpaceService>;
String _$albumAccessControlServiceHash() =>
    r'21f239066d8c39fd8fae9137618e9b729bab2b3a';

/// AlbumAccessControlService Provider
///
/// 提供相册访问控制服务实例，用于管理相册的解锁状态
///
/// Copied from [albumAccessControlService].
@ProviderFor(albumAccessControlService)
final albumAccessControlServiceProvider =
    AutoDisposeFutureProvider<AlbumAccessControlService>.internal(
  albumAccessControlService,
  name: r'albumAccessControlServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$albumAccessControlServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AlbumAccessControlServiceRef
    = AutoDisposeFutureProviderRef<AlbumAccessControlService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
