// lib/services/encrypted_space/providers/encrypted_space_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/services/encrypted_space/encrypted_space_service.dart';
import 'package:prismbox/services/encrypted_space/album_access_control_service.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;
import 'package:prismbox/providers/infrastructure/api_service_provider.dart' as infra;

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
  return EncryptedSpaceService(
    database: database,
    apiService: apiService,
  );
}

/// AlbumAccessControlService Provider
/// 
/// 提供相册访问控制服务实例，用于管理相册的解锁状态
@riverpod
Future<AlbumAccessControlService> albumAccessControlService(
  AlbumAccessControlServiceRef ref,
) async {
  return AlbumAccessControlService();
}

