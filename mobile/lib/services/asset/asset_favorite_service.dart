// lib/services/asset/asset_favorite_service.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/platform/asset_native_api.g.dart';

/// 资产收藏服务
/// 提供管理媒体资源收藏状态的功能：先更新 Prismbox 数据库，再写回系统相册。
/// 写回系统后，下次同步时系统与 DB 一致，收藏状态不会被覆盖。
///
/// **权限**：写回系统需要相册写入权限（iOS 需「完全访问」相册，Android 11+ 需存储写入权限）。
/// 若无权限，仅保留 DB 更新，不抛异常。
class AssetFavoriteService {
  final LocalAssetDao _localAssetDao;
  final Logger _logger = Logger('AssetFavoriteService');
  final AssetNativeApi _assetNativeApi;

  AssetFavoriteService({
    required LocalAssetDao localAssetDao,
    AssetNativeApi? assetNativeApi,
  })  : _localAssetDao = localAssetDao,
        _assetNativeApi = assetNativeApi ?? AssetNativeApi();

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
  /// 先更新数据库，再尝试写回系统相册（需相册写入权限）。写回失败仅打日志，不抛异常。
  ///
  /// **参数**：
  /// - [assetId] - 资产 ID（本地资源标识符，iOS 为 localIdentifier，Android 为 MediaStore _ID）
  /// - [isFavorite] - 是否收藏（true 表示收藏，false 表示取消收藏）
  ///
  /// **异常**：
  /// - 如果资产不存在或数据库更新失败，抛出异常
  Future<void> setFavorite(String assetId, bool isFavorite) async {
    try {
      _logger.fine('setFavorite: 开始设置收藏状态, assetId=$assetId, isFavorite=$isFavorite');

      // 从数据库获取资产
      final asset = await _localAssetDao.getAssetById(assetId);
      if (asset == null) {
        throw Exception('Asset not found in database: $assetId');
      }

      // 1. 先更新数据库（保证 App 内状态立即生效）
      final updatedAsset = asset.copyWith(isFavorite: isFavorite);
      await _localAssetDao.updateAsset(updatedAsset);
      _logger.fine('setFavorite: 数据库收藏状态更新成功, assetId=$assetId');

      // 2. 写回系统相册（需权限；失败仅降级，不抛异常）
      await _setFavoriteOnSystem(assetId, isFavorite);

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

  /// 将收藏状态写回系统相册。无权限或失败时仅打日志，不抛异常。
  Future<void> _setFavoriteOnSystem(String assetId, bool isFavorite) async {
    if (!kIsWeb && (Platform.isIOS || Platform.isAndroid)) {
      try {
        await _assetNativeApi.setIsFavorite(assetId, isFavorite);
        _logger.fine('setFavorite: 系统相册收藏状态已写回, assetId=$assetId');
      } catch (e, stackTrace) {
        _logger.warning(
          'setFavorite: 写回系统相册失败（已保留数据库更新）, assetId=$assetId, error=$e',
          e,
          stackTrace,
        );
      }
    }
  }
}

