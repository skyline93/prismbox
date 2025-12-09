// lib/features/local_sync/services/timeline_provider_service.dart

import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/features/local_sync/models/data_source_type.dart';
import 'package:prismbox/features/local_sync/services/data_source_selector.dart';

/// 时间线数据提供者服务
/// 提供时间线数据，支持双数据源（数据库和 photo_manager）
class TimelineProviderService {
  final AppDatabase _database;
  final DataSourceSelector _dataSourceSelector;
  final Logger _logger = Logger('TimelineProviderService');

  TimelineProviderService({
    required AppDatabase database,
    DataSourceSelector? dataSourceSelector,
  })  : _database = database,
        _dataSourceSelector = dataSourceSelector ??
            DataSourceSelector(database: database);

  /// 获取时间线数据
  /// 
  /// [forcePhotoManager] 强制使用 photo_manager 数据源
  /// 
  /// 返回 BaseAsset 列表（LocalAsset）
  Future<List<LocalAsset>> getTimelineAssets({
    bool forcePhotoManager = false,
  }) async {
    try {
      // 选择数据源
      final dataSource = forcePhotoManager
          ? DataSourceType.photoManager
          : await _dataSourceSelector.selectDataSource();

      if (dataSource == DataSourceType.database) {
        return await _getFromDatabase();
      } else {
        return await _getFromPhotoManager();
      }
    } catch (e, stackTrace) {
      _logger.severe('获取时间线数据失败', e, stackTrace);
      // 如果失败，尝试从 photo_manager 获取
      try {
        return await _getFromPhotoManager();
      } catch (e2) {
        _logger.severe('从 photo_manager 获取数据也失败', e2);
        return [];
      }
    }
  }

  /// 从数据库获取数据
  Future<List<LocalAsset>> _getFromDatabase() async {
    try {
      final dao = LocalAssetDao(_database);
      final assets = await dao.getAllAssets();
      
      // 按创建时间降序排序
      assets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // 转换为 LocalAsset，并批量获取 remoteAssetId
      final remoteDao = RemoteAssetDao(_database);
      final localAssets = <LocalAsset>[];
      
      for (final data in assets) {
        // 如果 checksum 存在，尝试获取 remoteAssetId
        String? remoteAssetId;
        if (data.checksum != null && data.checksum!.isNotEmpty) {
          try {
            final remoteAsset = await remoteDao.getAssetByChecksum(data.checksum!);
            remoteAssetId = remoteAsset?.id;
          } catch (e) {
            _logger.fine('获取远程资产 ID 失败: ${data.id}', e);
          }
        }
        
        localAssets.add(LocalAsset.fromData(
          id: data.id,
          name: data.name,
          checksum: data.checksum,
          type: data.type,
          createdAt: data.createdAt,
          updatedAt: data.updatedAt,
          width: data.width,
          height: data.height,
          durationInSeconds: data.durationInSeconds,
          isFavorite: data.isFavorite,
          orientation: data.orientation,
          remoteAssetId: remoteAssetId,
          assetEntity: null, // 延迟获取：在需要时通过 getAssetEntityById 获取
        ));
      }
      
      return localAssets;
    } catch (e) {
      _logger.warning('从数据库获取数据失败', e);
      rethrow;
    }
  }

  /// 从 photo_manager 获取数据
  Future<List<LocalAsset>> _getFromPhotoManager() async {
    try {
      // 检查权限
      final permission = await pm.PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        _logger.warning('相册权限未授予');
        return [];
      }

      // 获取所有相册
      final albums = await pm.PhotoManager.getAssetPathList(
        hasAll: true,
      );
      
      if (albums.isEmpty) {
        return [];
      }

      // 获取"所有照片"相册
      final allPhotosAlbum = albums.firstWhere(
        (album) => album.isAll,
        orElse: () => albums.first,
      );

      // 获取所有资产
      final totalCount = await allPhotosAlbum.assetCountAsync;
      if (totalCount == 0) {
        return [];
      }

      // 获取资产列表（限制数量，避免一次性加载太多）
      final assets = await allPhotosAlbum.getAssetListRange(
        start: 0,
        end: totalCount,
      );

      // 转换为 LocalAsset
      final localAssets = <LocalAsset>[];
      for (final asset in assets) {
        try {
          final localAsset = await _convertAssetEntityToLocalAsset(asset);
          localAssets.add(localAsset);
        } catch (e) {
          _logger.warning('转换资产失败: ${asset.id}', e);
          // 继续处理其他资产
        }
      }

      // 按创建时间降序排序
      localAssets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return localAssets;
    } catch (e) {
      _logger.warning('从 photo_manager 获取数据失败', e);
      rethrow;
    }
  }

  /// 延迟获取 AssetEntity（按需获取）
  /// 当需要加载图片时调用此方法
  Future<pm.AssetEntity?> getAssetEntityById(String id) async {
    try {
      return await pm.AssetEntity.fromId(id);
    } catch (e) {
      _logger.warning('获取 AssetEntity 失败: $id', e);
      return null;
    }
  }

  /// 获取关联的远程资产 ID（通过 checksum 查询）
  Future<String?> _getRemoteAssetId(String? checksum) async {
    if (checksum == null || checksum.isEmpty) {
      return null;
    }

    try {
      final remoteDao = RemoteAssetDao(_database);
      // 通过 checksum 查询远程资产（不限制用户）
      final remoteAsset = await remoteDao.getAssetByChecksum(checksum);
      return remoteAsset?.id;
    } catch (e) {
      _logger.warning('查询远程资产 ID 失败: $checksum', e);
      return null;
    }
  }

  /// 转换 AssetEntity 为 LocalAsset
  Future<LocalAsset> _convertAssetEntityToLocalAsset(pm.AssetEntity asset) async {
    // 转换资产类型
    // photo_manager 的 AssetType 是枚举，需要转换为我们的 AssetType
    // AssetEntity.type 返回的是 AssetType 枚举值，使用索引值判断
    AssetType assetType;
    // photo_manager AssetType 枚举值：image=1, video=2, audio=3
    final typeIndex = asset.type.index;
    if (typeIndex == 1) {
      assetType = AssetType.image;
    } else if (typeIndex == 2) {
      assetType = AssetType.video;
    } else if (typeIndex == 3) {
      assetType = AssetType.audio;
    } else {
      assetType = AssetType.other;
    }

    // 尝试从数据库获取关联的远程资产 ID
    String? remoteAssetId;
    try {
      final dao = LocalAssetDao(_database);
      final localAsset = await dao.getAssetById(asset.id);
      if (localAsset != null && localAsset.checksum != null) {
        remoteAssetId = await _getRemoteAssetId(localAsset.checksum);
      }
    } catch (e) {
      // 忽略错误
      _logger.fine('获取远程资产 ID 失败: ${asset.id}', e);
    }

    return LocalAsset.fromData(
      id: asset.id,
      name: asset.title ?? asset.id, // 如果标题为空，使用 ID
      checksum: null, // photo_manager 不提供 checksum
      type: assetType,
      createdAt: asset.createDateTime,
      updatedAt: asset.modifiedDateTime,
      width: asset.width,
      height: asset.height,
      durationInSeconds: asset.duration,
      isFavorite: false,
      orientation: asset.orientation,
      remoteAssetId: remoteAssetId,
      assetEntity: asset, // photo_manager 数据源包含 AssetEntity
    );
  }
}

