// lib/services/trash/remote_asset_delete_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 远程资源删除服务
/// 负责远程资源的软删除操作（调用后端 API）
class RemoteAssetDeleteService {
  final Logger _logger = Logger('RemoteAssetDeleteService');
  final RemoteAssetDao _dao;
  final ApiService _apiService;

  RemoteAssetDeleteService({
    required RemoteAssetDao dao,
    required ApiService apiService,
  }) : _dao = dao,
       _apiService = apiService;

  /// 软删除远程资源
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（UUID）
  ///
  /// **行为**：
  /// 1. 调用后端 API `DELETE /api/v1/media/:uuid` 执行软删除
  /// 2. 更新本地数据库的 `deletedAt` 字段
  ///
  /// **返回**：是否成功
  Future<bool> softDeleteAsset(String assetId) async {
    try {
      // 1. 调用后端 API
      final endpoint = _apiService.endpoint;
      if (endpoint == null || endpoint.isEmpty) {
        _logger.warning('API endpoint 未配置');
        return false;
      }

      final url = '$endpoint/api/v1/media/$assetId';
      final response = await _apiService.dio.delete(url);

      if (response.statusCode != 200) {
        _logger.warning('后端 API 返回错误: ${response.statusCode}');
        return false;
      }

      // 2. 更新本地数据库
      final success = await _dao.softDeleteAsset(assetId);

      if (success) {
        _logger.info('远程资源已软删除: $assetId');
      } else {
        _logger.warning('更新本地数据库失败: $assetId');
      }

      return success;
    } catch (e, stackTrace) {
      _logger.severe('软删除远程资源失败: $assetId', e, stackTrace);
      return false;
    }
  }

  /// 批量软删除远程资源
  ///
  /// **参数**：
  /// - [assetIds] - 资产 ID 列表
  ///
  /// **返回**：成功删除的数量
  Future<int> softDeleteAssets(List<String> assetIds) async {
    int successCount = 0;
    for (final assetId in assetIds) {
      final success = await softDeleteAsset(assetId);
      if (success) {
        successCount++;
      }
    }
    _logger.info('批量软删除完成: $successCount/${assetIds.length}');
    return successCount;
  }
}
