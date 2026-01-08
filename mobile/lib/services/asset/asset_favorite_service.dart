// lib/services/asset/asset_favorite_service.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';

/// 资产收藏服务
/// 提供管理媒体资源收藏状态的功能，包括设置和切换收藏状态
/// 
/// **设计原则**：收藏操作仅更新 Prismbox 数据库，不修改系统相册。
/// 系统相册的收藏状态通过同步流程读取，保持单向同步。
class AssetFavoriteService {
  final LocalAssetDao _localAssetDao;
  final Logger _logger = Logger('AssetFavoriteService');

  AssetFavoriteService({
    required LocalAssetDao localAssetDao,
  }) : _localAssetDao = localAssetDao;

  /// 切换资产的收藏状态
  ///
  /// 从数据库获取当前收藏状态，取反后更新数据库中的收藏状态
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（本地资源标识符）
  ///
  /// **异常**：
  /// - 如果资产不存在，抛出异常
  /// - 如果数据库更新失败，抛出异常
  Future<void> toggleFavorite(String assetId) async {
    try {
      _logger.fine('toggleFavorite: 开始切换收藏状态, assetId=$assetId');

      // 从数据库获取当前收藏状态
      final asset = await _localAssetDao.getAssetById(assetId);
      if (asset == null) {
        throw Exception('Asset not found: $assetId');
      }

      // 计算新的收藏状态（取反）
      final newFavoriteStatus = !asset.isFavorite;
      _logger.fine(
        'toggleFavorite: 当前状态=${asset.isFavorite}, 新状态=$newFavoriteStatus, assetId=$assetId',
      );

      // 调用 setFavorite 设置新状态
      await setFavorite(assetId, newFavoriteStatus);

      _logger.info('toggleFavorite: 切换收藏状态成功, assetId=$assetId, isFavorite=$newFavoriteStatus');
    } catch (e, stackTrace) {
      _logger.severe(
        'toggleFavorite: 切换收藏状态失败, assetId=$assetId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// 设置资产的收藏状态
  ///
  /// 直接更新数据库中的收藏状态，不修改系统相册
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（本地资源标识符）
  /// - [isFavorite] - 是否收藏（true 表示收藏，false 表示取消收藏）
  ///
  /// **异常**：
  /// - 如果资产不存在，抛出异常
  /// - 如果数据库更新失败，抛出异常
  Future<void> setFavorite(String assetId, bool isFavorite) async {
    try {
      _logger.fine('setFavorite: 开始设置收藏状态, assetId=$assetId, isFavorite=$isFavorite');

      // 从数据库获取资产
      final asset = await _localAssetDao.getAssetById(assetId);
      if (asset == null) {
        throw Exception('Asset not found in database: $assetId');
      }

      // 使用 updateAsset 更新收藏状态
      final updatedAsset = asset.copyWith(isFavorite: isFavorite);
      await _localAssetDao.updateAsset(updatedAsset);
      _logger.fine('setFavorite: 数据库收藏状态更新成功, assetId=$assetId');

      _logger.info('setFavorite: 设置收藏状态成功, assetId=$assetId, isFavorite=$isFavorite');
    } catch (e, stackTrace) {
      _logger.severe(
        'setFavorite: 设置收藏状态失败, assetId=$assetId, isFavorite=$isFavorite',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}

