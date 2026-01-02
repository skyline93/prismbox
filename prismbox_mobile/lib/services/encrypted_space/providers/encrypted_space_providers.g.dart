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
String _$pinAccessControlServiceHash() =>
    r'39c6957493e9767b76c131b420fefa683fa91558';

/// PinAccessControlService Provider (for encrypted space)
///
/// 提供PIN访问控制服务实例，用于管理加密相册的解锁状态
/// 这是AlbumAccessControlService的替代品，使用新的PIN服务架构
///
/// Copied from [pinAccessControlService].
@ProviderFor(pinAccessControlService)
final pinAccessControlServiceProvider =
    AutoDisposeFutureProvider<PinAccessControlService>.internal(
  pinAccessControlService,
  name: r'pinAccessControlServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pinAccessControlServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef PinAccessControlServiceRef
    = AutoDisposeFutureProviderRef<PinAccessControlService>;
String _$albumAccessControlServiceHash() =>
    r'3cf258ddf532ecb07933c477473f5400015ba752';

/// AlbumAccessControlService Provider (deprecated, use pinAccessControlService instead)
///
/// 提供相册访问控制服务实例，用于管理相册的解锁状态
/// 注意：此服务已弃用，请使用 pinAccessControlService
/// 为了向后兼容，返回PinAccessControlService
///
/// Copied from [albumAccessControlService].
@ProviderFor(albumAccessControlService)
final albumAccessControlServiceProvider =
    AutoDisposeFutureProvider<PinAccessControlService>.internal(
  albumAccessControlService,
  name: r'albumAccessControlServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$albumAccessControlServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AlbumAccessControlServiceRef
    = AutoDisposeFutureProviderRef<PinAccessControlService>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
