// lib/services/encrypted_space/providers/encrypted_space_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/services/pin/pin_service_factory.dart';
import 'package:prismbox/services/pin/pin_access_control_service.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart'
    as infra;
import 'package:prismbox/providers/infrastructure/api_service_provider.dart'
    as infra;

part 'encrypted_space_providers.g.dart';

/// EncryptedSpaceService Provider
///
/// 提供加密空间服务实例，用于管理加密相册和资产
@riverpod
Future<EncryptedSpaceService> encryptedSpaceService(
  EncryptedSpaceServiceRef ref,
) async {
  final database = await ref.watch(infra.databaseProvider.future);
  final apiService = ref.watch(infra.apiServiceProvider);
  return EncryptedSpaceService(database: database, apiService: apiService);
}

/// PinAccessControlService Provider (for encrypted space)
///
/// 提供PIN访问控制服务实例，用于管理加密相册的解锁状态
/// 这是AlbumAccessControlService的替代品，使用新的PIN服务架构
@riverpod
Future<PinAccessControlService> pinAccessControlService(
  PinAccessControlServiceRef ref,
) async {
  final suite = PinServiceFactory.createEncryptedSpaceSuite();
  return suite.accessControlService;
}

/// AlbumAccessControlService Provider (deprecated, use pinAccessControlService instead)
///
/// 提供相册访问控制服务实例，用于管理相册的解锁状态
/// 注意：此服务已弃用，请使用 pinAccessControlService
/// 为了向后兼容，返回PinAccessControlService
@Deprecated('Use pinAccessControlService instead')
@riverpod
Future<PinAccessControlService> albumAccessControlService(
  AlbumAccessControlServiceRef ref,
) async {
  final suite = PinServiceFactory.createEncryptedSpaceSuite();
  return suite.accessControlService;
}
