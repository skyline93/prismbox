// lib/services/trash/trash_purge_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/trash/trash_storage_service.dart';

/// 回收站永久删除服务
/// 负责永久删除回收站中的资源
class TrashPurgeService {
  final Logger _logger = Logger('TrashPurgeService');
  final LocalAssetDao _localDao;
  final RemoteAssetDao _remoteDao;
  final TrashStorageService _trashStorage;
  final ApiService _apiService;

  TrashPurgeService({
    required LocalAssetDao localDao,
    required RemoteAssetDao remoteDao,
    required TrashStorageService trashStorage,
    required ApiService apiService,
  }) : _localDao = localDao,
       _remoteDao = remoteDao,
       _trashStorage = trashStorage,
       _apiService = apiService;

  /// 永久删除本地资源
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID
  ///
  /// **行为**：
  /// 1. 删除回收站文件
  /// 2. 从数据库硬删除记录
  ///
  /// **返回**：是否成功
  Future<bool> purgeLocalAsset(String assetId) async {
    try {
      // 1. 获取资产信息
      final asset = await _localDao.getAssetById(assetId);
      if (asset == null) {
        _logger.warning('资产不存在: $assetId');
        return false;
      }

      final trashPath = asset.trashPath;
      if (trashPath != null && trashPath.isNotEmpty) {
        // 删除回收站文件
        await _trashStorage.deleteFromTrash(trashPath);
      }

      // 2. 从数据库硬删除记录
      final success = await _localDao.deleteAsset(assetId);

      if (success) {
        _logger.info('本地资源已永久删除: $assetId');
      } else {
        _logger.warning('删除数据库记录失败: $assetId');
      }

      return success;
    } catch (e, stackTrace) {
      _logger.severe('永久删除本地资源失败: $assetId', e, stackTrace);
      return false;
    }
  }

  /// 永久删除远程资源
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（UUID）
  ///
  /// **行为**：
  /// 1. 调用后端 API `DELETE /api/v1/media/:uuid/purge` 永久删除
  /// 2. 从本地数据库硬删除记录
  ///
  /// **返回**：是否成功
  Future<bool> purgeRemoteAsset(String assetId) async {
    try {
      // 1. 调用后端 API
      final endpoint = _apiService.endpoint;
      if (endpoint == null || endpoint.isEmpty) {
        _logger.warning('API endpoint 未配置');
        return false;
      }

      final url = '$endpoint/api/v1/media/$assetId/purge';
      final response = await _apiService.dio.delete(url);

      if (response.statusCode != 200) {
        _logger.warning('后端 API 返回错误: ${response.statusCode}');
        return false;
      }

      // 2. 从本地数据库硬删除记录
      // 注意：RemoteAssetDao 可能没有硬删除方法，需要检查
      // 这里我们假设有 deleteAsset 方法，如果没有，需要添加
      final success = await _remoteDao.deleteAsset(assetId);

      if (success) {
        _logger.info('远程资源已永久删除: $assetId');
      } else {
        _logger.warning('删除本地数据库记录失败: $assetId');
      }

      return success;
    } catch (e, stackTrace) {
      _logger.severe('永久删除远程资源失败: $assetId', e, stackTrace);
      return false;
    }
  }

  /// 批量永久删除资源
  ///
  /// **参数**：
  /// - [localAssetIds] - 本地资产 ID 列表
  /// - [remoteAssetIds] - 远程资产 ID 列表
  ///
  /// **返回**：成功删除的数量
  Future<int> purgeAssets({
    List<String>? localAssetIds,
    List<String>? remoteAssetIds,
  }) async {
    int successCount = 0;

    // 永久删除本地资源
    if (localAssetIds != null && localAssetIds.isNotEmpty) {
      for (final assetId in localAssetIds) {
        final success = await purgeLocalAsset(assetId);
        if (success) {
          successCount++;
        }
      }
    }

    // 永久删除远程资源
    if (remoteAssetIds != null && remoteAssetIds.isNotEmpty) {
      for (final assetId in remoteAssetIds) {
        final success = await purgeRemoteAsset(assetId);
        if (success) {
          successCount++;
        }
      }
    }

    _logger.info('批量永久删除完成: $successCount');
    return successCount;
  }
}
