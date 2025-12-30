// lib/features/local_sync/services/timeline_provider_service.dart

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart' as pm;
import 'package:prismbox/core/storage/store_key.dart';
import 'package:prismbox/core/storage/store_service.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/daos/album_dao.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/album_type.dart';
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
      final albumDao = AlbumDao(_database);

      // 1. 获取当前用户ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _logger.warning('无法获取用户ID，仅返回本地资产');
        return await _getLocalAssetsOnly(localDao, remoteDao);
      }

      // 2. 获取加密空间相册ID（用于过滤）
      final encryptedSpaceAlbumIds = await _getEncryptedSpaceAlbumIds(albumDao, userId);

      // 3. 并行查询本地和远程资产
      final localAssetsFuture = localDao.getAllAssets();
      final remoteAssetsFuture = remoteDao.getUserAssets(userId);

      final localAssetsData = await localAssetsFuture;
      final remoteAssetsData = await remoteAssetsFuture;

      // 4. 过滤掉在加密空间中的资产
      final filteredLocalAssets = await _filterEncryptedSpaceAssets(
        localAssetsData,
        encryptedSpaceAlbumIds,
        albumDao,
      );
      final filteredRemoteAssets = await _filterEncryptedSpaceRemoteAssets(
        remoteAssetsData,
        encryptedSpaceAlbumIds,
        albumDao,
      );

      // 5. 构建 checksum 到本地资产的映射（用于关联）
      final localAssetMap = <String, LocalAssetEntityData>{};

      for (final data in filteredLocalAssets) {
        if (data.checksum != null && data.checksum!.isNotEmpty) {
          // 取第一个作为主要关联（通常 checksum 应该是唯一的）
          if (!localAssetMap.containsKey(data.checksum!)) {
            localAssetMap[data.checksum!] = data;
          }
        }
      }

      // 6. 构建已处理的远程资产 checksum 集合（用于去重）
      final processedRemoteChecksums = <String>{};
      final mergedAssets = <BaseAsset>[];

      // 7. 处理远程资产（包括有本地关联和没有本地关联的）
      for (final remoteData in filteredRemoteAssets) {
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

      // 8. 处理仅本地的资产（排除已有远程版本的）
      for (final localData in filteredLocalAssets) {
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

      // 9. 按创建时间降序排序
      mergedAssets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _logger.info(
        '合并查询完成：本地资产 ${localAssetsData.length} 个（过滤后 ${filteredLocalAssets.length} 个），'
        '远程资产 ${remoteAssetsData.length} 个（过滤后 ${filteredRemoteAssets.length} 个），'
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
    final albumDao = AlbumDao(_database);
    final allLocalAssetsData = await localDao.getAllAssets();
    
    // 获取加密空间相册ID（用于过滤）
    final encryptedSpaceAlbumIds = await _getEncryptedSpaceAlbumIds(albumDao, null);
    
    // 过滤掉在加密空间中的资产
    final localAssetsData = await _filterEncryptedSpaceAssets(
      allLocalAssetsData,
      encryptedSpaceAlbumIds,
      albumDao,
    );
    
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

      // 获取资产列表
      final assets = await allPhotosAlbum.getAssetListRange(
        start: 0,
        end: totalCount,
      );

      // ========== 优化：批量查询远程资产 ID ==========
      // 1. 批量获取所有本地资产数据（一次查询）
      final assetIds = assets.map((a) => a.id).toList();
      final localDao = LocalAssetDao(_database);
      final albumDao = AlbumDao(_database);
      final allLocalAssetsMap = await localDao.getAssetsByIds(assetIds);
      
      // 2. 过滤掉在加密空间中的资产
      final userId = await _getCurrentUserId();
      final encryptedSpaceAlbumIds = await _getEncryptedSpaceAlbumIds(albumDao, userId);
      final localAssetsData = allLocalAssetsMap.values.toList();
      final filteredLocalAssets = await _filterEncryptedSpaceAssets(
        localAssetsData,
        encryptedSpaceAlbumIds,
        albumDao,
      );
      final localAssetsMap = <String, LocalAssetEntityData>{};
      for (final asset in filteredLocalAssets) {
        localAssetsMap[asset.id] = asset;
      }

      // 3. 收集所有需要查询的 checksum（批量查询远程资产）
      final checksumsToQuery = <String>[];
      final assetIdToChecksumMap = <String, String>{};

      for (final entry in localAssetsMap.entries) {
        final checksum = entry.value.checksum;
        if (checksum != null && checksum.isNotEmpty) {
          checksumsToQuery.add(checksum);
          assetIdToChecksumMap[entry.key] = checksum;
        }
      }

      // 4. 批量查询远程资产 ID（一次查询）
      final remoteDao = RemoteAssetDao(_database);
      final remoteAssetsMap = checksumsToQuery.isEmpty
          ? <String, RemoteAssetEntityData>{}
          : await remoteDao.getAssetsByChecksums(checksumsToQuery);

      // 5. 过滤远程资产（排除在加密空间中的）
      final filteredRemoteAssetsMap = <String, RemoteAssetEntityData>{};
      if (encryptedSpaceAlbumIds['remote'] != null) {
        final remoteEncryptedAlbumId = encryptedSpaceAlbumIds['remote']!;
        try {
          final encryptedAssets = await albumDao.getAlbumAssets(remoteEncryptedAlbumId);
          final encryptedAssetIds = encryptedAssets.map((a) => a.id).toSet();
          
          for (final entry in remoteAssetsMap.entries) {
            if (!encryptedAssetIds.contains(entry.value.id)) {
              filteredRemoteAssetsMap[entry.key] = entry.value;
            }
          }
        } catch (e) {
          _logger.warning('过滤远程加密资产失败: $e');
          // 如果过滤失败，使用原始数据
          filteredRemoteAssetsMap.addAll(remoteAssetsMap);
        }
      } else {
        filteredRemoteAssetsMap.addAll(remoteAssetsMap);
      }

      // 6. 构建 assetId -> remoteAssetId 映射（只使用过滤后的远程资产）
      final assetIdToRemoteAssetIdMap = <String, String>{};
      for (final entry in assetIdToChecksumMap.entries) {
        final checksum = entry.value;
        final remoteAsset = filteredRemoteAssetsMap[checksum];
        if (remoteAsset != null) {
          assetIdToRemoteAssetIdMap[entry.key] = remoteAsset.id;
        }
      }
      // ========== 批量查询优化结束 ==========

      // 7. 并行转换资产（不包含数据库查询，只处理过滤后的资产）
      final filteredAssetIds = localAssetsMap.keys.toSet();
      final localAssetsResults = await Future.wait(
        assets.where((asset) => filteredAssetIds.contains(asset.id)).map((asset) async {
          try {
            return await _convertAssetEntityToLocalAsset(
              asset,
              remoteAssetId: assetIdToRemoteAssetIdMap[asset.id],
            );
          } catch (e) {
            _logger.warning('转换资产失败: ${asset.id}', e);
            return null;
          }
        }),
      );

      // 过滤掉转换失败的结果
      final localAssets = localAssetsResults
          .whereType<LocalAsset>()
          .toList();

      // 按创建时间降序排序
      localAssets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _logger.info(
        '从 photo_manager 加载 ${localAssets.length} 个资产，'
        '批量查询了 ${remoteAssetsMap.length} 个远程资产关联',
      );

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

  /// 转换 AssetEntity 为 LocalAsset（优化版本）
  /// [remoteAssetId] 预先查询好的远程资产 ID，避免在转换时再次查询数据库
  Future<LocalAsset> _convertAssetEntityToLocalAsset(
    pm.AssetEntity asset, {
    String? remoteAssetId,
  }) async {
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

    // 注意：remoteAssetId 已经从批量查询中获取，不再需要单独查询数据库

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
      remoteAssetId: remoteAssetId, // 使用预先查询的结果
      assetEntity: asset, // photo_manager 数据源包含 AssetEntity
    );
  }

  /// 获取加密空间相册ID（本地和远程）
  /// 返回 Map<String, String>，key 为 'local' 和 'remote'，value 为相册ID
  Future<Map<String, String?>> _getEncryptedSpaceAlbumIds(
    AlbumDao albumDao,
    String? userId,
  ) async {
    final result = <String, String?>{'local': null, 'remote': null};

    try {
      // 获取本地加密空间相册
      final localAlbums = await albumDao.getAllLocalAlbums();
      final localEncryptedAlbum = localAlbums.firstWhere(
        (album) => album.albumType == AlbumType.encryptedSpace && album.isEncrypted,
        orElse: () => throw StateError('No local encrypted space album found'),
      );
      result['local'] = localEncryptedAlbum.id;
    } catch (e) {
      // 本地加密空间相册不存在，忽略
      _logger.fine('本地加密空间相册不存在: $e');
    }

    try {
      // 获取远程加密空间相册
      final remoteAlbums = await albumDao.getAllRemoteAlbums();
      final remoteEncryptedAlbum = remoteAlbums.firstWhere(
        (album) => album.albumType == AlbumType.encryptedSpace && album.isEncrypted,
        orElse: () => throw StateError('No remote encrypted space album found'),
      );
      result['remote'] = remoteEncryptedAlbum.id;
    } catch (e) {
      // 远程加密空间相册不存在，忽略
      _logger.fine('远程加密空间相册不存在: $e');
    }

    return result;
  }

  /// 过滤掉在加密空间中的本地资产
  /// 排除条件：
  /// 1. isInPrivateSpace = true
  /// 2. 关联到本地加密相册
  Future<List<LocalAssetEntityData>> _filterEncryptedSpaceAssets(
    List<LocalAssetEntityData> assets,
    Map<String, String?> encryptedSpaceAlbumIds,
    AlbumDao albumDao,
  ) async {
    if (encryptedSpaceAlbumIds['local'] == null) {
      // 没有本地加密相册，只过滤 isInPrivateSpace
      return assets.where((asset) => !asset.isInPrivateSpace).toList();
    }

    final localEncryptedAlbumId = encryptedSpaceAlbumIds['local']!;
    
    // 获取本地加密相册中的所有资产ID
    final encryptedAssetIds = <String>{};
    try {
      final encryptedAssets = await albumDao.getLocalAlbumAssets(localEncryptedAlbumId);
      encryptedAssetIds.addAll(encryptedAssets.map((a) => a.id));
    } catch (e) {
      _logger.warning('获取本地加密相册资产失败: $e');
    }

    // 过滤：排除 isInPrivateSpace = true 或关联到加密相册的资产
    return assets.where((asset) {
      if (asset.isInPrivateSpace) {
        return false;
      }
      if (encryptedAssetIds.contains(asset.id)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 过滤掉在加密空间中的远程资产
  /// 排除条件：关联到远程加密相册
  Future<List<RemoteAssetEntityData>> _filterEncryptedSpaceRemoteAssets(
    List<RemoteAssetEntityData> assets,
    Map<String, String?> encryptedSpaceAlbumIds,
    AlbumDao albumDao,
  ) async {
    if (encryptedSpaceAlbumIds['remote'] == null) {
      // 没有远程加密相册，不过滤
      return assets;
    }

    final remoteEncryptedAlbumId = encryptedSpaceAlbumIds['remote']!;
    
    // 获取远程加密相册中的所有资产ID
    final encryptedAssetIds = <String>{};
    try {
      final encryptedAssets = await albumDao.getAlbumAssets(remoteEncryptedAlbumId);
      encryptedAssetIds.addAll(encryptedAssets.map((a) => a.id));
    } catch (e) {
      _logger.warning('获取远程加密相册资产失败: $e');
    }

    // 过滤：排除关联到加密相册的资产
    return assets.where((asset) => !encryptedAssetIds.contains(asset.id)).toList();
  }
}
