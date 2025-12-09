// lib/features/local_sync/services/data_source_selector.dart

import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/features/local_sync/models/data_source_type.dart';

/// 数据源选择器
/// 根据数据可用性自动选择最优数据源
class DataSourceSelector {
  final AppDatabase _database;
  
  /// 数据可用性阈值（数据库资产数量）
  static const int _threshold = 100;

  DataSourceSelector({
    required AppDatabase database,
  }) : _database = database;

  /// 选择数据源
  /// 
  /// 返回选择的数据源类型
  Future<DataSourceType> selectDataSource() async {
    try {
      final dao = LocalAssetDao(_database);
      final assets = await dao.getAllAssets();
      
      // 如果数据库资产数量大于阈值，使用数据库
      if (assets.length > _threshold) {
        return DataSourceType.database;
      }
      
      // 否则使用 photo_manager
      return DataSourceType.photoManager;
    } catch (e) {
      // 如果数据库查询失败，回退到 photo_manager
      return DataSourceType.photoManager;
    }
  }

  /// 检查数据库数据是否可用
  Future<bool> isDatabaseAvailable() async {
    try {
      final dao = LocalAssetDao(_database);
      final assets = await dao.getAllAssets();
      return assets.length > _threshold;
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

