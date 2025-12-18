// lib/services/backup/asset_sync_service.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 资产同步服务
///
/// **职责**：
/// - 更新本地资产 checksum
/// - 查询远程资产信息
/// - 更新 remote_asset_entity 表
/// - 同步资产状态
///
/// **职责边界**：
/// - ✅ **负责**：资产同步相关的数据库操作和API调用
/// - ❌ **不负责**：上传流程编排（由 UploadOrchestrator 负责）
class AssetSyncService {
  final AppDatabase _database;
  final ApiService _apiService;
  final Logger _logger = Logger('AssetSyncService');

  AssetSyncService({
    required AppDatabase database,
    ApiService? apiService,
  })  : _database = database,
        _apiService = apiService ?? ApiService();

  /// 计算文件 checksum
  Future<String> calculateFileChecksum(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// 更新本地资产的 checksum
  ///
  /// **参数**：
  /// - [assetId] - 本地资产 ID
  /// - [checksum] - checksum 值
  ///
  /// **返回**：是否更新成功
  Future<bool> updateLocalAssetChecksum({
    required String assetId,
    required String checksum,
  }) async {
    try {
      final localAsset = await _database.localAssetDao.getAssetById(assetId);
      if (localAsset == null) {
        _logger.warning('Local asset not found: assetId=$assetId');
        return false;
      }

      if (localAsset.checksum == checksum) {
        // checksum 已是最新，无需更新
        return true;
      }

      final updatedAsset = localAsset.copyWith(
        checksum: Value(checksum),
        updatedAt: DateTime.now(),
      );
      await _database.localAssetDao.updateAsset(updatedAsset);

      _logger.info('Updated local asset checksum: assetId=$assetId');
      return true;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to update local asset checksum: assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
      return false;
    }
  }

  /// 获取或计算本地资产的 checksum
  ///
  /// **参数**：
  /// - [assetId] - 本地资产 ID
  /// - [filePath] - 文件路径（如果本地资产没有 checksum，则计算）
  ///
  /// **返回**：checksum 值，如果失败返回 null
  Future<String?> getOrCalculateChecksum({
    required String assetId,
    required String filePath,
  }) async {
    try {
      // 1. 尝试从本地资产获取 checksum
      final localAsset = await _database.localAssetDao.getAssetById(assetId);
      if (localAsset == null) {
        _logger.warning('Local asset not found: assetId=$assetId');
        return null;
      }

      if (localAsset.checksum != null && localAsset.checksum!.isNotEmpty) {
        return localAsset.checksum;
      }

      // 2. 计算 checksum
      final file = File(filePath);
      if (!await file.exists()) {
        _logger.warning('File not found for checksum calculation: $filePath');
        return null;
      }

      final checksum = await calculateFileChecksum(filePath);

      // 3. 更新本地资产的 checksum
      await updateLocalAssetChecksum(assetId: assetId, checksum: checksum);

      return checksum;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to get or calculate checksum: assetId=$assetId, error=$e',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// 通过 checksum 查询远程资产信息
  ///
  /// **参数**：
  /// - [checksum] - checksum 值
  /// - [userId] - 用户 ID
  ///
  /// **返回**：远程资产信息，如果不存在返回 null
  ///
  /// **实现说明**：
  /// - 优先通过 /api/v1/media 分页查询（更可靠，直接返回完整信息）
  /// - 如果失败，再通过 /api/v1/media/changes 获取最近的变化
  Future<Map<String, dynamic>?> queryRemoteAssetByChecksum({
    required String checksum,
    required String userId,
  }) async {
    try {
      final endpoint = _apiService.endpoint ?? '';
      final headers = await ApiService.getRequestHeaders();

      // 方法1：通过 /api/v1/media 分页查询（更可靠，直接返回完整信息）
      final mediaUrl = '$endpoint/api/v1/media';
      try {
        final mediaResponse = await _apiService.dio.get(
          mediaUrl,
          queryParameters: {
            'page': 1,
            'page_size': 50, // 查询最近50个资产
          },
          options: Options(headers: headers),
        );

        if (mediaResponse.statusCode != null &&
            mediaResponse.statusCode! >= 200 &&
            mediaResponse.statusCode! < 300) {
          final mediaData = mediaResponse.data as Map<String, dynamic>?;
          if (mediaData != null) {
            final medias = mediaData['medias'] as List<dynamic>?;
            if (medias != null) {
              _logger.fine(
                'Found ${medias.length} medias in response, searching for checksum: $checksum',
              );
              // 查找匹配 checksum 的资产
              for (final media in medias) {
                final mediaInfo = media as Map<String, dynamic>;
                final mediaHash = mediaInfo['hash'] as String?;
                if (mediaHash == checksum) {
                  _logger.info(
                    'Found remote asset by checksum: uuid=${mediaInfo['uuid']}, hash=$checksum',
                  );
                  return mediaInfo;
                }
              }
            }
          }
        }
      } catch (e) {
        _logger.warning('Failed to query media list: $e');
      }

      // 方法2：如果方法1失败，通过 /api/v1/media/changes 获取最近的变化
      final changesUrl = '$endpoint/api/v1/media/changes';
      try {
        final changesResponse = await _apiService.dio.get(
          changesUrl,
          options: Options(headers: headers),
        );

        if (changesResponse.statusCode != null &&
            changesResponse.statusCode! >= 200 &&
            changesResponse.statusCode! < 300) {
          final changesData = changesResponse.data as Map<String, dynamic>?;
          if (changesData != null) {
            final changes = changesData['changes'] as List<dynamic>?;
            if (changes != null && changes.isNotEmpty) {
              _logger.fine(
                'Found ${changes.length} changes in response, searching for checksum: $checksum',
              );
              // 查找匹配 checksum 的资产
              for (final change in changes) {
                final changeData = change as Map<String, dynamic>;
                final changeHash = changeData['hash'] as String?;
                if (changeHash == checksum &&
                    changeData['action'] == 'created') {
                  final uuid = changeData['uuid'] as String?;
                  if (uuid != null) {
                    _logger.info(
                      'Found remote asset UUID from changes: uuid=$uuid, hash=$checksum',
                    );
                    // 通过 UUID 获取完整的资产信息
                    return await _getRemoteAssetInfo(uuid);
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        _logger.warning('Failed to query media changes: $e');
      }

      return null;
    } catch (e) {
      _logger.warning(
        'Failed to query remote asset by checksum: checksum=$checksum, error=$e',
      );
      return null;
    }
  }

  /// 获取远程资产详细信息
  Future<Map<String, dynamic>?> _getRemoteAssetInfo(String remoteAssetId) async {
    try {
      final endpoint = _apiService.endpoint ?? '';
      final url = '$endpoint/api/v1/media/$remoteAssetId';
      final headers = await ApiService.getRequestHeaders();

      final response = await _apiService.dio.get(
        url,
        options: Options(headers: headers),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final data = response.data as Map<String, dynamic>?;
        if (data != null) {
          return data['data'] as Map<String, dynamic>? ?? data;
        }
      }

      return null;
    } catch (e) {
      _logger.warning(
        'Failed to get remote asset info: remoteAssetId=$remoteAssetId, error=$e',
      );
      return null;
    }
  }

  /// 转换 item_type 字符串为 AssetType 枚举
  AssetType _convertItemTypeToAssetType(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'image':
        return AssetType.image;
      case 'video':
        return AssetType.video;
      case 'audio':
        return AssetType.audio;
      default:
        return AssetType.other;
    }
  }

  /// 上传成功后更新数据库关联
  ///
  /// **参数**：
  /// - [task] - 上传任务实体
  ///
  /// **实现说明**：
  /// - 通过 API 查询资产信息（使用 checksum）
  /// - 更新 remote_asset_entity 表
  /// - 确保 local_asset_entity 的 checksum 已设置
  Future<void> syncAssetAfterUpload(UploadTaskEntityData task) async {
    try {
      // 1. 获取本地资产信息
      final localAsset = await _database.localAssetDao.getAssetById(task.assetId);
      if (localAsset == null) {
        _logger.warning(
          'Local asset not found: assetId=${task.assetId}',
        );
        return;
      }

      // 2. 获取或计算 checksum
      final checksum = await getOrCalculateChecksum(
        assetId: task.assetId,
        filePath: task.localPath,
      );

      if (checksum == null || checksum.isEmpty) {
        _logger.warning(
          'Failed to get checksum for asset: assetId=${task.assetId}',
        );
        return;
      }

      // 3. 获取用户 ID（从任务中获取）
      final userId = task.userId;

      // 4. 通过 API 查询资产信息（使用 checksum）
      final remoteAssetInfo = await queryRemoteAssetByChecksum(
        checksum: checksum,
        userId: userId,
      );

      if (remoteAssetInfo == null) {
        _logger.warning(
          'Remote asset not found for checksum: $checksum',
        );
        // 如果查询不到，可能是服务器延迟，不阻塞流程
        return;
      }

      // 5. 更新 remote_asset_entity 表
      final remoteDao = RemoteAssetDao(_database);
      
      // 处理 updated_at 可能为空字符串的情况
      final updatedAtStr = remoteAssetInfo['updated_at'] as String?;
      final updatedAt = updatedAtStr != null && updatedAtStr.isNotEmpty
          ? DateTime.parse(updatedAtStr)
          : DateTime.parse(remoteAssetInfo['created_at'] as String);
      
      final remoteAssetData = RemoteAssetEntityData(
        id: remoteAssetInfo['uuid'] as String,
        checksum: remoteAssetInfo['hash'] as String,
        ownerId: userId,
        name: remoteAssetInfo['original_filename'] as String? ?? 
              remoteAssetInfo['filename'] as String? ?? '',
        type: _convertItemTypeToAssetType(remoteAssetInfo['item_type'] as String),
        createdAt: DateTime.parse(remoteAssetInfo['created_at'] as String),
        updatedAt: updatedAt,
        width: remoteAssetInfo['width'] as int?,
        height: remoteAssetInfo['height'] as int?,
        durationInSeconds: null, // API 响应中没有 duration 字段
        isFavorite: false, // 默认值
        localDateTime: remoteAssetInfo['media_taken_at'] != null
            ? DateTime.parse(remoteAssetInfo['media_taken_at'] as String)
            : null,
        thumbHash: null,
        deletedAt: null,
        livePhotoVideoId: null,
        visibility: AssetVisibility.private,
        stackId: null,
        libraryId: null,
      );

      await remoteDao.insertOrUpdateAsset(remoteAssetData);

      _logger.info(
        'Database updated after upload: assetId=${task.assetId}, '
        'remoteAssetId=${remoteAssetInfo['uuid']}',
      );
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to sync asset after upload: taskId=${task.id}, error=$e',
        e,
        stackTrace,
      );
      // 不抛出异常，避免阻塞上传流程
    }
  }
}

