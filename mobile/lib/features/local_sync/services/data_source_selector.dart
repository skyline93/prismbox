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
  ///
  /// **数据源选择优先级**：
  /// 1. 如果数据库资产数量 > 阈值 → 使用数据库（性能优化）
  /// 2. 否则 → 使用 photo_manager（快速路径）
  /// 
  /// **注意**：已移除基于远程资产存在性的强制数据库切换逻辑。
  /// 根据新的设计，时间线会同时显示本地和远程资产，但数据源选择仅基于本地资产数量。
  Future<DataSourceType> selectDataSource() async {
    try {
      // 检查数据库资产数量
      final dao = LocalAssetDao(_database);
      final assets = await dao.getAllAssets();
      final assetCount = assets.length;

      if (assetCount > threshold) {
        _logger.fine(
          '选择数据源：数据库（资产数量=$assetCount > 阈值=$threshold）',
        );
        return DataSourceType.database;
      }

      // 使用快速路径
      _logger.fine(
        '选择数据源：photo_manager（资产数量=$assetCount ≤ 阈值=$threshold）',
      );
      return DataSourceType.photoManager;
    } catch (e) {
      // 如果数据库查询失败，回退到 photo_manager
      _logger.warning('数据库查询失败，回退到 photo_manager', e);
      return DataSourceType.photoManager;
    }
  }


  /// 检查数据库数据是否可用
  ///
  /// 数据库数据源可用的条件：
  /// - 本地资产数量 > 阈值
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

