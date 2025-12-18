// lib/features/local_sync/services/data_source_selector.dart

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/features/local_sync/models/data_source_type.dart';

/// 数据源选择器
/// 根据数据可用性自动选择最优数据源
class DataSourceSelector {
  final AppDatabase _database;
  final Logger _logger = Logger('DataSourceSelector');
  
  /// 数据可用性阈值（数据库资产数量）
  /// 可以从配置中读取，默认值为 100
  final int threshold;

  DataSourceSelector({
    required AppDatabase database,
    int? threshold,
  }) : _database = database,
       threshold = threshold ?? AppSetting.get(Setting.dataSourceThreshold) {
    _logger.info('DataSourceSelector 初始化，阈值=$threshold（从配置读取）');
  }

  /// 选择数据源
  ///
  /// 返回选择的数据源类型
  ///
  /// **数据源选择优先级**：
  /// 1. 如果有远程资产 → 必须使用数据库（数据完整性优先）
  /// 2. 如果数据库资产数量 > 阈值 → 使用数据库（性能优化）
  /// 3. 否则 → 使用 photo_manager（快速路径）
  Future<DataSourceType> selectDataSource() async {
    try {
      // 优先级1：检查是否有远程资产
      final hasRemoteAssets = await _hasRemoteAssets();
      if (hasRemoteAssets) {
        _logger.fine(
          '选择数据源：数据库（存在远程资产，需要合并显示）',
        );
        return DataSourceType.database;
      }

      // 优先级2：检查数据库资产数量
      final dao = LocalAssetDao(_database);
      final assets = await dao.getAllAssets();
      final assetCount = assets.length;

      if (assetCount > threshold) {
        _logger.fine(
          '选择数据源：数据库（资产数量=$assetCount > 阈值=$threshold）',
        );
        return DataSourceType.database;
      }

      // 优先级3：使用快速路径
      _logger.fine(
        '选择数据源：photo_manager（资产数量=$assetCount ≤ 阈值=$threshold，且无远程资产）',
      );
      return DataSourceType.photoManager;
    } catch (e) {
      // 如果数据库查询失败，回退到 photo_manager
      _logger.warning('数据库查询失败，回退到 photo_manager', e);
      return DataSourceType.photoManager;
    }
  }

  /// 检查是否有远程资产
  ///
  /// 如果有远程资产，必须使用数据库数据源才能完整显示所有资产
  Future<bool> _hasRemoteAssets() async {
    try {
      // 获取当前用户ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        return false;
      }

      // 查询远程资产
      final remoteDao = RemoteAssetDao(_database);
      final remoteAssets = await remoteDao.getUserAssets(userId);
      return remoteAssets.isNotEmpty;
    } catch (e) {
      _logger.fine('检查远程资产失败', e);
      return false;
    }
  }

  /// 获取当前用户ID
  Future<String?> _getCurrentUserId() async {
    try {
      final store = StoreService();
      if (!store.isInitialized) {
        return null;
      }

      final userJson = store.tryGet<String>(StoreKey.currentUser);
      if (userJson == null || userJson.isEmpty) {
        return null;
      }

      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      return userMap['id']?.toString();
    } catch (e) {
      _logger.fine('获取用户ID失败', e);
      return null;
    }
  }

  /// 检查数据库数据是否可用
  ///
  /// 数据库数据源可用的条件：
  /// 1. 存在远程资产（必须使用数据库才能完整显示）
  /// 2. 本地资产数量 > 阈值
  Future<bool> isDatabaseAvailable() async {
    try {
      // 如果有远程资产，数据库数据源必须可用
      final hasRemote = await _hasRemoteAssets();
      if (hasRemote) {
        return true;
      }

      // 否则检查本地资产数量
      final dao = LocalAssetDao(_database);
      final assets = await dao.getAllAssets();
      return assets.length > threshold;
    } catch (e) {
      return false;
    }
  }

  /// 获取数据库资产数量
  Future<int> getDatabaseAssetCount() async {
    try {
      final dao = LocalAssetDao(_database);
      final assets = await dao.getAllAssets();
      return assets.length;
    } catch (e) {
      return 0;
    }
  }
}

