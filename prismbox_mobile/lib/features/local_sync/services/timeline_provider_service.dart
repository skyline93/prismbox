// lib/features/local_sync/services/timeline_provider_service.dart

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/domain/entities/base_asset.dart';
import 'package:prismbox/domain/entities/local_asset.dart';
import 'package:prismbox/domain/entities/remote_asset.dart';
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
  }) : _database = database,
       _dataSourceSelector =
           dataSourceSelector ?? DataSourceSelector(database: database);

  /// 获取时间线数据
  ///
  /// [forcePhotoManager] 强制使用 photo_manager 数据源
  ///
  /// 返回 BaseAsset 列表（包含 LocalAsset 和 RemoteAsset）
  Future<List<BaseAsset>> getTimelineAssets({
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
        // photo_manager 数据源仍然返回 List<LocalAsset>
        // 因为 photo_manager 只能访问本地资源
        final localAssets = await _getFromPhotoManager();
        return localAssets.cast<BaseAsset>();
      }
    } catch (e, stackTrace) {
      _logger.severe('获取时间线数据失败', e, stackTrace);
      // 如果失败，尝试从 photo_manager 获取
      try {
        final localAssets = await _getFromPhotoManager();
        return localAssets.cast<BaseAsset>();
      } catch (e2) {
        _logger.severe('从 photo_manager 获取数据也失败', e2);
        return [];
      }
    }
  }

  /// 从数据库获取数据（合并本地和远程资产）
  Future<List<BaseAsset>> _getFromDatabase() async {
    try {
      final localDao = LocalAssetDao(_database);
      final remoteDao = RemoteAssetDao(_database);

      // 1. 获取当前用户ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _logger.warning('无法获取用户ID，仅返回本地资产');
        return await _getLocalAssetsOnly(localDao, remoteDao);
      }

      // 2. 并行查询本地和远程资产
      final localAssetsFuture = localDao.getAllAssets();
      final remoteAssetsFuture = remoteDao.getUserAssets(userId);

      final localAssetsData = await localAssetsFuture;
      final remoteAssetsData = await remoteAssetsFuture;

      // 3. 构建 checksum 到本地资产的映射（用于关联）
      final localAssetMap = <String, LocalAssetEntityData>{};

      for (final data in localAssetsData) {
        if (data.checksum != null && data.checksum!.isNotEmpty) {
          // 取第一个作为主要关联（通常 checksum 应该是唯一的）
          if (!localAssetMap.containsKey(data.checksum!)) {
            localAssetMap[data.checksum!] = data;
          }
        }
      }

      // 4. 构建已处理的远程资产 checksum 集合（用于去重）
      final processedRemoteChecksums = <String>{};
      final mergedAssets = <BaseAsset>[];

      // 5. 处理远程资产（包括有本地关联和没有本地关联的）
      for (final remoteData in remoteAssetsData) {
        final checksum = remoteData.checksum;
        if (checksum.isEmpty) {
          // 没有 checksum 的远程资产，直接添加
          mergedAssets.add(
            RemoteAsset.fromData(
              id: remoteData.id,
              name: remoteData.name,
              checksum: '',
              ownerId: remoteData.ownerId,
              type: remoteData.type,
              createdAt: remoteData.createdAt,
              updatedAt: remoteData.updatedAt,
              width: remoteData.width,
              height: remoteData.height,
              durationInSeconds: remoteData.durationInSeconds,
              isFavorite: remoteData.isFavorite,
              thumbHash: remoteData.thumbHash,
              visibility: remoteData.visibility,
              livePhotoVideoId: remoteData.livePhotoVideoId,
              stackId: remoteData.stackId,
              localAssetId: null, // 没有本地关联
            ),
          );
          continue;
        }

        // checksum 不为空，继续处理
        final localData = localAssetMap[checksum];

        if (localData != null) {
          // 有本地关联：创建 LocalAsset（merged 状态）
          mergedAssets.add(
            LocalAsset.fromData(
              id: localData.id,
              name: localData.name,
              checksum: localData.checksum,
              type: localData.type,
              createdAt: localData.createdAt,
              updatedAt: localData.updatedAt,
              width: localData.width,
              height: localData.height,
              durationInSeconds: localData.durationInSeconds,
              isFavorite: localData.isFavorite,
              orientation: localData.orientation,
              remoteAssetId: remoteData.id, // 关联远程资产ID
              assetEntity: null,
            ),
          );
          processedRemoteChecksums.add(checksum);
        } else {
          // 没有本地关联：创建 RemoteAsset（remote 状态）
          mergedAssets.add(
            RemoteAsset.fromData(
              id: remoteData.id,
              name: remoteData.name,
              checksum: checksum,
              ownerId: remoteData.ownerId,
              type: remoteData.type,
              createdAt: remoteData.createdAt,
              updatedAt: remoteData.updatedAt,
              width: remoteData.width,
              height: remoteData.height,
              durationInSeconds: remoteData.durationInSeconds,
              isFavorite: remoteData.isFavorite,
              thumbHash: remoteData.thumbHash,
              visibility: remoteData.visibility,
              livePhotoVideoId: remoteData.livePhotoVideoId,
              stackId: remoteData.stackId,
              localAssetId: null, // 设备B的情况：没有本地文件
            ),
          );
          processedRemoteChecksums.add(checksum);
        }
      }

      // 6. 处理仅本地的资产（排除已有远程版本的）
      for (final localData in localAssetsData) {
        if (localData.checksum == null || localData.checksum!.isEmpty) {
          // 没有 checksum，无法关联，作为仅本地资产
          mergedAssets.add(
            LocalAsset.fromData(
              id: localData.id,
              name: localData.name,
              checksum: null,
              type: localData.type,
              createdAt: localData.createdAt,
              updatedAt: localData.updatedAt,
              width: localData.width,
              height: localData.height,
              durationInSeconds: localData.durationInSeconds,
              isFavorite: localData.isFavorite,
              orientation: localData.orientation,
              remoteAssetId: null, // 未上传
              assetEntity: null,
            ),
          );
        } else {
          // 检查是否已有远程版本
          if (!processedRemoteChecksums.contains(localData.checksum!)) {
            // 仅本地资产（未上传）
            mergedAssets.add(
              LocalAsset.fromData(
                id: localData.id,
                name: localData.name,
                checksum: localData.checksum,
                type: localData.type,
                createdAt: localData.createdAt,
                updatedAt: localData.updatedAt,
                width: localData.width,
                height: localData.height,
                durationInSeconds: localData.durationInSeconds,
                isFavorite: localData.isFavorite,
                orientation: localData.orientation,
                remoteAssetId: null, // 未上传
                assetEntity: null,
              ),
            );
          }
          // 如果已有远程版本，已经在上面处理过了
        }
      }

      // 7. 按创建时间降序排序
      mergedAssets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _logger.info(
        '合并查询完成：本地资产 ${localAssetsData.length} 个，'
        '远程资产 ${remoteAssetsData.length} 个，'
        '合并后 ${mergedAssets.length} 个',
      );

      return mergedAssets;
    } catch (e) {
      _logger.warning('从数据库获取数据失败', e);
      rethrow;
    }
  }

  /// 仅获取本地资产（当无法获取用户ID时）
  Future<List<BaseAsset>> _getLocalAssetsOnly(
    LocalAssetDao localDao,
    RemoteAssetDao remoteDao,
  ) async {
    final localAssetsData = await localDao.getAllAssets();
    final localAssets = <BaseAsset>[];

    for (final data in localAssetsData) {
      // 尝试通过 checksum 关联远程资产
      String? remoteAssetId;
      if (data.checksum != null && data.checksum!.isNotEmpty) {
        try {
          final remoteAsset = await remoteDao.getAssetByChecksum(
            data.checksum!,
          );
          remoteAssetId = remoteAsset?.id;
        } catch (e) {
          _logger.fine('获取远程资产 ID 失败: ${data.id}', e);
        }
      }

      localAssets.add(
        LocalAsset.fromData(
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
          assetEntity: null,
        ),
      );
    }

    localAssets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return localAssets;
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
      _logger.warning('获取用户ID失败', e);
      return null;
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
      final albums = await pm.PhotoManager.getAssetPathList(hasAll: true);

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
  Future<LocalAsset> _convertAssetEntityToLocalAsset(
    pm.AssetEntity asset,
  ) async {
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

    // 验证文件对象可访问（但不使用其路径来获取文件名）
    final file = await asset.originFile;
    if (file == null) {
      throw Exception('无法获取文件对象: assetId=${asset.id}');
    }

    // 获取原始文件名 - 使用 asset.title（推荐方式）
    // Android: asset.title 通常就是原始文件名
    // iOS 14+: asset.title 基本可靠
    // 注意：不要使用 originFile.path 来解析文件名，因为它在 iOS 上是临时文件，文件名是随机的
    final originalFileName = asset.title ?? '';

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
      name: originalFileName, // 使用 asset.title 获取的原始文件名
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
