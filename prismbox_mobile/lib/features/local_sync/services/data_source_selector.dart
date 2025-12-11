// lib/features/local_sync/services/data_source_selector.dart

import 'package:logging/logging.dart';
import 'package:prismbox/core/settings/app_setting.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
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
  Future<DataSourceType> selectDataSource() async {
    try {
      final dao = LocalAssetDao(_database);
      final assets = await dao.getAllAssets();
      final assetCount = assets.length;
      
      // 如果数据库资产数量大于阈值，使用数据库
      if (assetCount > threshold) {
        _logger.fine('选择数据源：数据库（资产数量=$assetCount > 阈值=$threshold）');
        return DataSourceType.database;
      }
      
      // 否则使用 photo_manager
      _logger.fine('选择数据源：photo_manager（资产数量=$assetCount ≤ 阈值=$threshold）');
      return DataSourceType.photoManager;
    } catch (e) {
      // 如果数据库查询失败，回退到 photo_manager
      _logger.warning('数据库查询失败，回退到 photo_manager', e);
      return DataSourceType.photoManager;
    }
  }

  /// 检查数据库数据是否可用
  Future<bool> isDatabaseAvailable() async {
    try {
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

