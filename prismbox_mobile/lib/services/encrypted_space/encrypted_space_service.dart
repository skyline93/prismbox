// lib/services/encrypted_space/encrypted_space_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/album_order.dart';
import 'package:prismbox/data/database/enums/album_type.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/encrypted_space/session_storage_service.dart';
import 'package:prismbox/services/encrypted_space/file_migration_service.dart';
import 'package:prismbox/services/encrypted_space/retry_queue_service.dart';

/// 加密空间服务
/// 负责加密相册的创建、资产管理和访问控制
class EncryptedSpaceService {
  final AppDatabase _database;
  final ApiService _apiService;
  final SessionStorageService _sessionStorage;
  final FileMigrationService _fileMigrationService;
  final RetryQueueService _retryQueue;
  final Logger _log = Logger('EncryptedSpaceService');

  EncryptedSpaceService({
    required AppDatabase database,
    required ApiService apiService,
    SessionStorageService? sessionStorage,
    FileMigrationService? fileMigrationService,
    RetryQueueService? retryQueue,
  }) : _database = database,
       _apiService = apiService,
       _sessionStorage = sessionStorage ?? SessionStorageService(),
       _fileMigrationService =
           fileMigrationService ?? FileMigrationService(database: database),
       _retryQueue = retryQueue ?? RetryQueueService() {
    // 初始化重试队列（启用持久化）
    _retryQueue.initialize(database);
    // 设置重试回调
    _retryQueue.setRetryCallback(_handleRetryTask);
  }

  /// 处理重试任务
  Future<bool> _handleRetryTask(RetryTask task) async {
    try {
      switch (task.type) {
        case RetryTaskType.addAssets:
          await addAssetsToEncryptedSpace(
            albumId: task.albumId,
            assetIds: task.assetIds,
          );
          return true;
        case RetryTaskType.removeAssets:
          await removeAssetsFromEncryptedSpace(
            albumId: task.albumId,
            assetIds: task.assetIds,
          );
          return true;
        case RetryTaskType.migrateToPrivateSpace:
          for (final assetId in task.assetIds) {
            await _fileMigrationService.moveAssetToPrivateSpace(
              assetId: assetId,
            );
          }
          return true;
        case RetryTaskType.migrateFromPrivateSpace:
          for (final assetId in task.assetIds) {
            await _fileMigrationService.moveAssetFromPrivateSpace(
              assetId: assetId,
            );
          }
          return true;
      }
    } catch (e, stackTrace) {
      _log.warning(
        'Retry task failed: ${task.type}, albumId: ${task.albumId}',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// 获取待处理的重试任务列表
  List<RetryTask> getPendingRetryTasks() {
    return _retryQueue.getPendingTasks();
  }

  /// 获取或创建加密空间相册
  /// 返回远程相册ID
  /// 确保加密空间相册总是存在（这是必须存在的相册）
  ///
  /// 实现策略：总是从服务器获取或创建，确保本地与服务器ID一致
  Future<String> getOrCreateEncryptedSpaceAlbum() async {
    try {
      final albumDao = _database.albumDao;

      // 查询本地是否已有加密空间相册（用于后续比较）
      RemoteAlbumEntityData? localAlbum;
      try {
        final allAlbums = await albumDao.getAllRemoteAlbums();
        localAlbum = allAlbums.firstWhere(
          (album) => album.albumType == AlbumType.encryptedSpace,
        );
        _log.fine(
          'Found encrypted space album in local database: ${localAlbum.id}',
        );
      } catch (e) {
        _log.fine('Encrypted space album not found in local database');
      }

      // ✅ 总是从服务器获取或创建，确保ID一致性
      final response = await _apiService.dio.get(
        '/api/v1/albums/encrypted-space',
      );

      // 响应拦截器已自动提取 data 字段，response.data 已经是业务数据
      final data = response.data as Map<String, dynamic>;
      final serverAlbumId = data['id'] as String;

      // 如果本地相册ID与服务器不一致，删除旧的本地记录
      if (localAlbum != null && localAlbum.id != serverAlbumId) {
        _log.warning(
          'Local album ID (${localAlbum.id}) differs from server ID ($serverAlbumId), '
          'updating local database',
        );
        // 删除旧的本地记录
        await albumDao.deleteAlbum(localAlbum.id);
        localAlbum = null;
      }

      // 如果本地没有或已删除，创建/更新本地记录
      if (localAlbum == null) {
        // 从当前用户信息获取 ownerId（后端没有返回此字段）
        final store = StoreService();
        if (!store.isInitialized) {
          throw Exception('Store not initialized');
        }

        final userJson = store.tryGet<String>(StoreKey.currentUser);
        if (userJson == null || userJson.isEmpty) {
          throw Exception('User not found in store');
        }

        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final ownerId = userMap['id']?.toString();
        if (ownerId == null || ownerId.isEmpty) {
          throw Exception('User ID not found');
        }

        // 同步到本地数据库
        final album = RemoteAlbumEntityData(
          id: serverAlbumId,
          name: data['name'] as String? ?? '加密空间',
          description: data['description'] as String?,
          createdAt: DateTime.parse(data['created_at'] as String),
          updatedAt: DateTime.parse(data['updated_at'] as String),
          ownerId: ownerId, // 从当前用户获取
          thumbnailAssetId: data['thumbnail_asset_id'] as String?,
          isActivityEnabled: data['is_activity_enabled'] as bool? ?? false,
          order: AlbumOrder.createdAtDesc, // 使用枚举值
          isEncrypted: true, // 加密空间相册
          albumType: AlbumType.encryptedSpace, // 加密空间类型
        );

        await albumDao.createAlbum(album);
        _log.info(
          'Encrypted space album synced to local database: $serverAlbumId',
        );
      } else {
        _log.fine('Encrypted space album already synced: $serverAlbumId');
      }

      return serverAlbumId;
    } on DioException catch (e) {
      _log.severe(
        'Failed to get or create encrypted space album from server',
        e,
      );
      rethrow;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to get or create encrypted space album',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 设置加密空间密码
  Future<void> setEncryptionPassword({
    required String albumId,
    required String password,
  }) async {
    try {
      await _apiService.dio.post(
        '/api/v1/albums/$albumId/password',
        data: {'password': password},
      );

      // 清除旧会话令牌
      await _sessionStorage.deleteSessionToken(albumId);

      _log.info('Encryption password set for album: $albumId');
    } on DioException catch (e) {
      _log.severe('Failed to set encryption password', e);
      rethrow;
    }
  }

  /// 更改加密空间密码
  /// 需要提供旧密码进行验证
  Future<void> changeEncryptionPassword({
    required String albumId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.dio.post(
        '/api/v1/albums/$albumId/password/change',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );

      // 清除所有会话令牌（密码更改后所有会话都会失效）
      await _sessionStorage.deleteSessionToken(albumId);

      _log.info('Encryption password changed for album: $albumId');
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        throw Exception('旧密码错误');
      }
      _log.severe('Failed to change encryption password', e);
      rethrow;
    }
  }

  /// 验证密码并获取会话令牌
  Future<void> verifyPassword({
    required String albumId,
    required String password,
  }) async {
    try {
      final response = await _apiService.dio.post(
        '/api/v1/albums/$albumId/verify-password',
        data: {'password': password},
      );

      // 响应拦截器已自动提取 data 字段，response.data 已经是业务数据
      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final expiresAt = DateTime.parse(data['expires_at'] as String);

      // 保存会话令牌（使用密码派生密钥加密）
      await _sessionStorage.saveSessionToken(
        albumId: albumId,
        token: token,
        expiresAt: expiresAt,
        password: password, // 传递密码用于KDF加密
      );

      _log.info(
        'Password verified and session token saved for album: $albumId',
      );
    } on DioException catch (e) {
      _log.severe('Failed to verify password', e);
      rethrow;
    }
  }

  /// 检查PIN是否已设置
  /// 通过尝试调用验证API，如果返回"PIN not set"错误，说明未设置
  /// 如果返回其他错误（如"Invalid PIN"），说明PIN已设置，只是输入错误
  Future<bool> checkIfPinIsSet({required String albumId}) async {
    try {
      // 尝试验证一个无效的PIN
      // 如果返回"PIN not set"错误，说明PIN未设置
      // 如果返回"Invalid PIN"错误，说明PIN已设置，只是输入错误
      await _apiService.dio.post(
        '/api/v1/albums/$albumId/verify-password',
        data: {'password': '000000'}, // 使用一个无效的PIN
      );
      // 如果验证成功（不应该发生），说明PIN已设置
      return true;
    } on DioException catch (e) {
      // 检查错误消息或状态码
      if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data?.toString().toLowerCase() ?? '';
        // 如果错误消息包含"PIN not set"或"not set for this album"，说明PIN未设置
        if (errorMessage.contains('pin not set') ||
            errorMessage.contains('not set for this album') ||
            errorMessage.contains('password not set')) {
          return false; // PIN未设置
        }
      }
      // 其他错误（如"Invalid PIN"、400等）说明PIN已设置，只是输入错误或格式错误
      return true;
    } catch (e) {
      // 未知错误，默认假设PIN已设置（保守策略）
      _log.warning('Failed to check if PIN is set, assuming it is set', e);
      return true;
    }
  }

  /// 添加资产到加密空间
  /// 支持三种类型的资产：
  /// 1. 仅本地资产：迁移文件到私有空间
  /// 2. 仅云端资产：关联到远程加密相册
  /// 3. 已备份资产：同时处理远程关联和本地迁移
  Future<void> addAssetsToEncryptedSpace({
    required String albumId,
    required List<String> assetIds,
  }) async {
    try {
      // 检查会话令牌
      final sessionToken = await _sessionStorage.getSessionToken(albumId);
      if (sessionToken == null) {
        throw Exception(
          'Session token not found. Please unlock the album first.',
        );
      }

      // 添加请求头
      final headers = {'X-Session-Token': sessionToken};

      final albumDao = _database.albumDao;
      final localAssetDao = _database.localAssetDao;
      final remoteAssetDao = _database.remoteAssetDao;

      // 分类资产：仅本地、仅云端、已备份
      final localOnlyAssets = <String>[];
      final remoteOnlyAssets = <String>[];
      final mergedAssets = <String>[];

      for (final assetId in assetIds) {
        // 检查是否为本地资产
        final localAsset = await localAssetDao.getAssetById(assetId);
        if (localAsset != null) {
          // 是本地资产，检查是否有远程版本
          if (localAsset.checksum != null && localAsset.checksum!.isNotEmpty) {
            final remoteAsset = await remoteAssetDao.getAssetByChecksum(
              localAsset.checksum!,
            );
            if (remoteAsset != null) {
              // 已备份资产
              mergedAssets.add(remoteAsset.id);
            } else {
              // 仅本地资产
              localOnlyAssets.add(assetId);
            }
          } else {
            // 仅本地资产（没有checksum）
            localOnlyAssets.add(assetId);
          }
        } else {
          // 可能是远程资产ID，检查是否存在
          final remoteAsset = await remoteAssetDao.getAssetById(assetId);
          if (remoteAsset != null) {
            // 仅云端资产
            remoteOnlyAssets.add(assetId);
          } else {
            _log.warning(
              'Asset not found (neither local nor remote): $assetId',
            );
          }
        }
      }

      // 收集所有需要从系统相册删除的资产ID（用于批量删除）
      final assetIdsToDeleteFromSystem = <String>[];

      // 处理仅本地资产：迁移文件到私有空间并关联到本地加密相册
      if (localOnlyAssets.isNotEmpty) {
        // 获取或创建本地加密空间相册
        final localAlbumId = await albumDao
            .getOrCreateLocalEncryptedSpaceAlbum();

        for (final assetId in localOnlyAssets) {
          try {
            // 迁移文件到私有空间，但不立即删除系统相册中的文件
            await _fileMigrationService.moveAssetToPrivateSpace(
              assetId: assetId,
              deleteFromSystemAlbum: false, // 不立即删除，稍后批量删除
            );

            // 收集需要删除的资产ID
            assetIdsToDeleteFromSystem.add(assetId);

            // 迁移成功后，关联到本地加密相册
            // 注意：只有在迁移成功后才关联，如果迁移失败则不关联
            try {
              await albumDao.addLocalAssetToAlbum(assetId, localAlbumId);
              _log.info(
                'Local asset migrated to private space and added to local album: $assetId',
              );
            } catch (e) {
              // 忽略重复关联错误
              _log.fine('Local asset already in local album: $assetId');
            }
          } catch (e, stackTrace) {
            _log.severe(
              'Failed to migrate local asset to private space: $assetId',
              e,
              stackTrace,
            );
            // 迁移失败，不添加到删除列表，不关联到加密相册，继续处理其他资产
            // 这样资产不会出现在加密空间，也不会从照片页面消失
          }
        }
      }

      // 处理仅云端资产和已备份资产：添加到远程相册
      final remoteAssetIds = <String>[...remoteOnlyAssets, ...mergedAssets];
      if (remoteAssetIds.isNotEmpty) {
        try {
          await _apiService.dio.post(
            '/api/v1/albums/$albumId/assets',
            data: {'asset_ids': remoteAssetIds},
            options: Options(headers: headers),
          );

          // 同步本地关联关系
          for (final assetId in remoteAssetIds) {
            try {
              await albumDao.addAssetToAlbum(assetId, albumId);
            } catch (e) {
              // 忽略重复关联错误
              _log.fine('Asset already in album: $assetId');
            }
          }
        } on DioException catch (e) {
          _log.severe('Failed to add remote assets to encrypted space', e);

          // 如果是网络错误，添加到重试队列
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError) {
            _retryQueue.addTask(
              RetryTask(
                type: RetryTaskType.addAssets,
                albumId: albumId,
                assetIds: remoteAssetIds,
              ),
            );
            _log.info('Added task to retry queue due to network error');
            // 不抛出异常，允许部分成功的情况
            return;
          }

          // 其他错误（如认证失败、服务器错误等）直接抛出
          rethrow;
        }
      }

      // 处理已备份资产的本地文件迁移
      for (final remoteAssetId in mergedAssets) {
        try {
          // 通过远程资产ID找到对应的本地资产
          final remoteAsset = await remoteAssetDao.getAssetById(remoteAssetId);
          if (remoteAsset != null && remoteAsset.checksum.isNotEmpty) {
            final localAsset = await localAssetDao.getAssetByChecksum(
              remoteAsset.checksum,
            );
            if (localAsset != null && !localAsset.isInPrivateSpace) {
              // 迁移文件到私有空间，但不立即删除系统相册中的文件
              await _fileMigrationService.moveAssetToPrivateSpace(
                assetId: localAsset.id,
                deleteFromSystemAlbum: false, // 不立即删除，稍后批量删除
              );

              // 收集需要删除的资产ID
              assetIdsToDeleteFromSystem.add(localAsset.id);

              _log.info(
                'Merged asset migrated to private space: ${localAsset.id}',
              );
            }
          }
        } catch (e, stackTrace) {
          _log.severe(
            'Failed to migrate merged asset to private space: $remoteAssetId',
            e,
            stackTrace,
          );
          // 继续处理其他资产
        }
      }

      // 批量删除系统相册中的原始文件
      if (assetIdsToDeleteFromSystem.isNotEmpty) {
        _log.info(
          'Batch deleting ${assetIdsToDeleteFromSystem.length} assets from system album',
        );
        await _fileMigrationService.batchDeleteFromSystemAlbum(
          assetIds: assetIdsToDeleteFromSystem,
        );
      }

      // 仅本地资产的相册关联已在上面处理完成

      _log.info(
        'Assets added to encrypted space: ${assetIds.length} assets (local: ${localOnlyAssets.length}, remote: ${remoteOnlyAssets.length}, merged: ${mergedAssets.length})',
      );
    } on DioException catch (e) {
      _log.severe('Failed to add assets to encrypted space', e);

      // 如果是网络错误，添加到重试队列
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        _retryQueue.addTask(
          RetryTask(
            type: RetryTaskType.addAssets,
            albumId: albumId,
            assetIds: assetIds,
          ),
        );
        _log.info('Added task to retry queue due to network error');
        // 不抛出异常，允许部分成功的情况
        return;
      }

      rethrow;
    } catch (e, stackTrace) {
      _log.severe('Failed to add assets to encrypted space', e, stackTrace);
      rethrow;
    }
  }

  /// 从加密空间移除资产
  /// 支持三种类型的资产：
  /// 1. 仅本地资产：移回系统相册（如果文件在私有空间）
  /// 2. 仅云端资产：移除远程关联
  /// 3. 已备份资产：同时处理远程关联和本地文件移回
  Future<void> removeAssetsFromEncryptedSpace({
    required String albumId,
    required List<String> assetIds,
  }) async {
    try {
      // 检查会话令牌
      final sessionToken = await _sessionStorage.getSessionToken(albumId);
      if (sessionToken == null) {
        throw Exception(
          'Session token not found. Please unlock the album first.',
        );
      }

      // 添加请求头
      final headers = {'X-Session-Token': sessionToken};

      final albumDao = _database.albumDao;
      final localAssetDao = _database.localAssetDao;
      final remoteAssetDao = _database.remoteAssetDao;

      // 分类资产：仅本地、仅云端、已备份
      final localOnlyAssets = <String>[];
      final remoteOnlyAssets = <String>[];
      final mergedAssets = <String>[];

      for (final assetId in assetIds) {
        // 检查是否为本地资产
        final localAsset = await localAssetDao.getAssetById(assetId);
        if (localAsset != null) {
          // 是本地资产，检查是否有远程版本
          if (localAsset.checksum != null && localAsset.checksum!.isNotEmpty) {
            final remoteAsset = await remoteAssetDao.getAssetByChecksum(
              localAsset.checksum!,
            );
            if (remoteAsset != null) {
              // 已备份资产
              mergedAssets.add(remoteAsset.id);
            } else {
              // 仅本地资产
              localOnlyAssets.add(assetId);
            }
          } else {
            // 仅本地资产（没有checksum）
            localOnlyAssets.add(assetId);
          }
        } else {
          // 可能是远程资产ID，检查是否存在
          final remoteAsset = await remoteAssetDao.getAssetById(assetId);
          if (remoteAsset != null) {
            // 仅云端资产
            remoteOnlyAssets.add(assetId);
          } else {
            _log.warning(
              'Asset not found (neither local nor remote): $assetId',
            );
          }
        }
      }

      // 处理仅云端资产和已备份资产：从远程相册移除
      final remoteAssetIds = <String>[...remoteOnlyAssets, ...mergedAssets];
      if (remoteAssetIds.isNotEmpty) {
        try {
          await _apiService.dio.delete(
            '/api/v1/albums/$albumId/assets',
            data: {'asset_ids': remoteAssetIds},
            options: Options(headers: headers),
          );

          // 同步本地关联关系
          for (final assetId in remoteAssetIds) {
            await albumDao.removeAssetFromAlbum(assetId, albumId);
          }
        } on DioException catch (e) {
          _log.severe('Failed to remove remote assets from encrypted space', e);

          // 如果是网络错误，添加到重试队列
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.connectionError) {
            _retryQueue.addTask(
              RetryTask(
                type: RetryTaskType.removeAssets,
                albumId: albumId,
                assetIds: remoteAssetIds,
              ),
            );
            _log.info('Added task to retry queue due to network error');
            // 不抛出异常，允许部分成功的情况
            return;
          }

          // 其他错误（如认证失败、服务器错误等）直接抛出
          rethrow;
        }
      }

      // 处理已备份资产的本地文件移回系统相册
      for (final remoteAssetId in mergedAssets) {
        try {
          // 通过远程资产ID找到对应的本地资产
          final remoteAsset = await remoteAssetDao.getAssetById(remoteAssetId);
          if (remoteAsset != null && remoteAsset.checksum.isNotEmpty) {
            final localAsset = await localAssetDao.getAssetByChecksum(
              remoteAsset.checksum,
            );
            if (localAsset != null && localAsset.isInPrivateSpace) {
              // 移回系统相册（事务保护）
              await _fileMigrationService.moveAssetFromPrivateSpace(
                assetId: localAsset.id,
              );
              _log.info(
                'Merged asset moved back to system album: ${localAsset.id}',
              );
            }
          }
        } catch (e, stackTrace) {
          _log.severe(
            'Failed to move merged asset back to system album: $remoteAssetId',
            e,
            stackTrace,
          );
          // 继续处理其他资产
        }
      }

      // 处理仅本地资产的本地文件移回系统相册和移除本地相册关联
      if (localOnlyAssets.isNotEmpty) {
        // 获取本地加密空间相册ID
        final localAlbumId = await albumDao
            .getOrCreateLocalEncryptedSpaceAlbum();

        for (final assetId in localOnlyAssets) {
          try {
            final localAsset = await localAssetDao.getAssetById(assetId);
            if (localAsset != null && localAsset.isInPrivateSpace) {
              // 移回系统相册（事务保护）
              await _fileMigrationService.moveAssetFromPrivateSpace(
                assetId: assetId,
              );
              _log.info('Local asset moved back to system album: $assetId');
            }

            // 移除本地相册关联
            await albumDao.removeLocalAssetFromAlbum(assetId, localAlbumId);
            _log.info('Local asset removed from local album: $assetId');
          } catch (e, stackTrace) {
            _log.severe(
              'Failed to move local asset back to system album: $assetId',
              e,
              stackTrace,
            );
            // 继续处理其他资产
          }
        }
      }

      _log.info(
        'Assets removed from encrypted space: ${assetIds.length} assets (local: ${localOnlyAssets.length}, remote: ${remoteOnlyAssets.length}, merged: ${mergedAssets.length})',
      );
    } on DioException catch (e) {
      _log.severe('Failed to remove assets from encrypted space', e);
      rethrow;
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to remove assets from encrypted space',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 获取加密空间的资产列表
  Future<List<String>> getEncryptedSpaceAssets(String albumId) async {
    try {
      // 检查会话令牌
      final sessionToken = await _sessionStorage.getSessionToken(albumId);
      if (sessionToken == null) {
        throw Exception(
          'Session token not found. Please unlock the album first.',
        );
      }

      // 添加请求头
      final headers = {'X-Session-Token': sessionToken};

      final response = await _apiService.dio.get(
        '/api/v1/albums/$albumId/assets',
        options: Options(headers: headers),
      );

      final data = response.data;
      final assets = data['assets'] as List<dynamic>;
      return assets.map((a) => a['id'] as String).toList();
    } on DioException catch (e) {
      _log.severe('Failed to get encrypted space assets', e);
      rethrow;
    }
  }

  /// 检查相册是否已解锁
  Future<bool> isAlbumUnlocked(String albumId) async {
    return await _sessionStorage.isSessionTokenValid(albumId);
  }

  /// 撤销所有会话令牌
  Future<void> revokeAllSessions(String albumId) async {
    try {
      await _apiService.dio.delete('/api/v1/albums/$albumId/sessions');

      // 清除本地会话令牌
      await _sessionStorage.deleteSessionToken(albumId);

      _log.info('All sessions revoked for album: $albumId');
    } on DioException catch (e) {
      _log.severe('Failed to revoke sessions', e);
      rethrow;
    }
  }
}
