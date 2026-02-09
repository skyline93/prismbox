// lib/features/local_sync/services/timeline_provider_service.dart

import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
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
import 'package:prismbox/features/local_sync/models/timeline_content_filter_config.dart';
import 'package:prismbox/features/local_sync/models/timeline_sort_config.dart';
import 'package:prismbox/features/local_sync/services/data_source_selector.dart';
import 'package:prismbox/platform/asset_native_api.g.dart';
import 'package:prismbox/providers/photo_filter/photo_filter_provider.dart';

/// 时间线数据提供者服务
/// 提供时间线数据，支持双数据源（数据库和 photo_manager）
class TimelineProviderService {
  final AppDatabase _database;
  final DataSourceSelector _dataSourceSelector;
  final AssetNativeApi _assetNativeApi;
  final Logger _logger = Logger('TimelineProviderService');

  TimelineProviderService({
    required AppDatabase database,
    DataSourceSelector? dataSourceSelector,
    AssetNativeApi? assetNativeApi,
  }) : _database = database,
       _dataSourceSelector =
           dataSourceSelector ?? DataSourceSelector(database: database),
       _assetNativeApi = assetNativeApi ?? AssetNativeApi();

  /// 获取时间线数据
  ///
  /// [forcePhotoManager] 强制使用 photo_manager 数据源
  /// [filterMode] 本地/远程隔离过滤模式（可选），如果提供则根据模式过滤资产
  /// [contentFilter] 内容过滤配置（可选），用于过滤收藏、视频等
  /// [sortConfig] 排序配置（可选），用于控制排序方式
  ///
  /// 返回 BaseAsset 列表（包含 LocalAsset 和 RemoteAsset）
  ///
  /// **过滤顺序**：
  /// 1. 先应用本地/远程隔离过滤（`filterMode`）
  /// 2. 再应用内容过滤（`contentFilter`）
  /// 3. 最后应用排序（`sortConfig`）
  Future<List<BaseAsset>> getTimelineAssets({
    bool forcePhotoManager = false,
    PhotoFilterModeEnum? filterMode,
    TimelineContentFilterConfig? contentFilter,
    TimelineSortConfig? sortConfig,
  }) async {
    try {
      // 选择数据源
      final dataSource = forcePhotoManager
          ? DataSourceType.photoManager
          : await _dataSourceSelector.selectDataSource();

      List<BaseAsset> assets;
      if (dataSource == DataSourceType.database) {
        assets = await _getFromDatabase();
      } else {
        // photo_manager 数据源仍然返回 List<LocalAsset>
        // 因为 photo_manager 只能访问本地资源
        final localAssets = await _getFromPhotoManager();
        assets = localAssets.cast<BaseAsset>();
      }

      // 第一步：应用本地/远程隔离过滤
      if (filterMode != null) {
        assets = _filterAssets(assets, filterMode);
      }

      // 第二步：应用内容过滤（收藏、视频等）
      if (contentFilter != null && contentFilter.hasContentFilter) {
        assets = _filterByContent(assets, contentFilter);
      }

      // 第三步：应用排序
      if (sortConfig != null) {
        _applySort(assets, sortConfig);
      }

      return assets;
    } catch (e, stackTrace) {
      _logger.severe('获取时间线数据失败', e, stackTrace);
      // 如果失败，尝试从 photo_manager 获取
      try {
        final localAssets = await _getFromPhotoManager();
        final assets = localAssets.cast<BaseAsset>();

        // 第一步：应用本地/远程隔离过滤
        if (filterMode != null) {
          final filtered = _filterAssets(assets, filterMode);
          // 第二步：应用内容过滤
          if (contentFilter != null && contentFilter.hasContentFilter) {
            final contentFiltered = _filterByContent(filtered, contentFilter);
            // 第三步：应用排序
            if (sortConfig != null) {
              _applySort(contentFiltered, sortConfig);
            }
            return contentFiltered;
          }
          // 第三步：应用排序
          if (sortConfig != null) {
            _applySort(filtered, sortConfig);
          }
          return filtered;
        }

        // 第二步：应用内容过滤
        if (contentFilter != null && contentFilter.hasContentFilter) {
          final contentFiltered = _filterByContent(assets, contentFilter);
          // 第三步：应用排序
          if (sortConfig != null) {
            _applySort(contentFiltered, sortConfig);
          }
          return contentFiltered;
        }

        // 第三步：应用排序
        if (sortConfig != null) {
          _applySort(assets, sortConfig);
        }

        return assets;
      } catch (e2) {
        _logger.severe('从 photo_manager 获取数据也失败', e2);
        return [];
      }
    }
  }

  /// 根据筛选模式过滤资产列表（本地/远程隔离）
  ///
  /// [assets] - 原始资产列表
  /// [filterMode] - 筛选模式
  /// 返回过滤后的资产列表
  ///
  /// **过滤逻辑（基于上传状态）**：
  /// - 全部：仅展示本地媒体资源（LocalAsset），包括已上传和未上传的
  /// - 已备份：仅展示已上传的本地媒体资源（isUploaded == true）
  /// - 未备份：仅展示未上传的本地媒体资源（isUploaded == false，包括从未上传和上传失败的）
  /// - 仅云端：仅展示远程服务端的媒体资源（RemoteAsset）
  List<BaseAsset> _filterAssets(
    List<BaseAsset> assets,
    PhotoFilterModeEnum filterMode,
  ) {
    switch (filterMode) {
      case PhotoFilterModeEnum.all:
        // 仅展示本地媒体资源，包括已上传和未上传的
        return assets.whereType<LocalAsset>().toList();
      case PhotoFilterModeEnum.backedUp:
        // 仅展示已上传的本地媒体资源（isUploaded == true）
        return assets
            .whereType<LocalAsset>()
            .where((asset) => asset.isUploaded)
            .toList();
      case PhotoFilterModeEnum.notBackedUp:
        // 仅展示未上传的本地媒体资源（isUploaded == false）
        return assets
            .whereType<LocalAsset>()
            .where((asset) => !asset.isUploaded)
            .toList();
      case PhotoFilterModeEnum.remoteOnly:
        // 仅展示远程服务端的媒体资源
        return assets.whereType<RemoteAsset>().toList();
    }
  }

  /// 根据内容过滤配置过滤资产列表（收藏、视频等）
  ///
  /// [assets] - 原始资产列表
  /// [contentFilter] - 内容过滤配置
  /// 返回过滤后的资产列表
  ///
  /// **过滤逻辑**：
  /// - `favoriteOnly: true` - 仅显示收藏资产
  /// - `videoOnly: true` - 仅显示视频资产
  /// - `rawOnly: true` - 仅显示 RAW 照片（且为图片类型）
  /// - `liveOnly: true` - 仅显示 Live Photo（底层通过 isMotionPhoto 判断）
  /// - 可以同时应用多个过滤条件（组合过滤，预留接口）
  List<BaseAsset> _filterByContent(
    List<BaseAsset> assets,
    TimelineContentFilterConfig contentFilter,
  ) {
    var result = assets;

    // 收藏过滤
    if (contentFilter.favoriteOnly == true) {
      result = result.where((a) => a.isFavorite).toList();
    } else if (contentFilter.favoriteOnly == false) {
      // 预留：仅非收藏（当前未使用）
      result = result.where((a) => !a.isFavorite).toList();
    }

    // 视频过滤
    if (contentFilter.videoOnly == true) {
      result = result.where((a) => a.isVideo).toList();
    } else if (contentFilter.videoOnly == false) {
      // 预留：仅非视频（当前未使用）
      result = result.where((a) => !a.isVideo).toList();
    }

    // RAW 照片过滤
    if (contentFilter.rawOnly == true) {
      result = result.where((a) => a.isImage && a.isRaw).toList();
    } else if (contentFilter.rawOnly == false) {
      // 预留：仅非 RAW 照片（当前未使用）
      result = result.where((a) => !(a.isImage && a.isRaw)).toList();
    }

    // Live Photo 过滤
    if (contentFilter.liveOnly == true) {
      result = result.where((a) => a.isMotionPhoto).toList();
    } else if (contentFilter.liveOnly == false) {
      // 预留：仅非 Live（当前未使用）
      result = result.where((a) => !a.isMotionPhoto).toList();
    }

    // 预留扩展接口：未来可以添加更多过滤条件
    // 如：地点过滤、标签过滤、日期范围过滤等

    return result;
  }

  /// 应用排序配置
  ///
  /// [assets] - 资产列表（原地排序）
  /// [sortConfig] - 排序配置
  ///
  /// **排序逻辑**：
  /// - `sortBy: createdAt` - 按创建时间排序
  /// - `sortBy: updatedAt` - 按更新时间排序（用于"最近添加"）
  /// - `order: asc` - 升序
  /// - `order: desc` - 降序（默认）
  void _applySort(List<BaseAsset> assets, TimelineSortConfig sortConfig) {
    assets.sort((a, b) {
      DateTime aTime, bTime;
      if (sortConfig.sortBy == TimelineSortField.updatedAt) {
        aTime = a.updatedAt;
        bTime = b.updatedAt;
      } else {
        // 默认按创建时间排序
        aTime = a.createdAt;
        bTime = b.createdAt;
      }

      final comparison = aTime.compareTo(bTime);
      return sortConfig.order == SortOrder.desc ? -comparison : comparison;
    });
  }

  /// 从数据库获取数据（合并本地和远程资产）
  ///
  /// **合并策略**：
  /// - 完全解耦本地和远程资产，不进行关联
  /// - 先添加所有远程资产，再添加所有本地资产
  /// - 允许重复显示（同一张照片可能同时显示本地版本和远程版本）
  Future<List<BaseAsset>> _getFromDatabase() async {
    try {
      final localDao = LocalAssetDao(_database);
      final remoteDao = RemoteAssetDao(_database);

      // 1. 获取当前用户ID
      final userId = await _getCurrentUserId();
      if (userId == null) {
        _logger.warning('无法获取用户ID，仅返回本地资产');
        return await _getLocalAssetsOnly(localDao);
      }

      // 2. 并行查询本地和远程资产
      final localAssetsFuture = localDao.getAllAssets();
      final remoteAssetsFuture = remoteDao.getUserAssets(userId);

      final localAssetsData = await localAssetsFuture;
      final remoteAssetsData = await remoteAssetsFuture;

      final mergedAssets = <BaseAsset>[];

      // 3. 先添加所有远程资产
      for (final remoteData in remoteAssetsData) {
        mergedAssets.add(
          RemoteAsset.fromData(
            id: remoteData.id,
            name: remoteData.name,
            checksum: remoteData.checksum,
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
            localAssetId: null, // 完全解耦，不关联本地资产
            fileSize: remoteData.fileSize,
            latitude: remoteData.latitude,
            longitude: remoteData.longitude,
            deviceMake: remoteData.deviceMake,
            deviceModel: remoteData.deviceModel,
            exifExposureTime: remoteData.exifExposureTime,
            exifFNumber: remoteData.exifFNumber,
            exifIso: remoteData.exifIso,
            exifFocalLength: remoteData.exifFocalLength,
          ),
        );
      }

      // 4. 再添加所有本地资产
      for (final localData in localAssetsData) {
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
            isUploaded: localData.isUploaded,
            orientation: localData.orientation,
            remoteAssetId: null,
            assetEntity: null,
            livePhotoVideoId: localData.livePhotoVideoId,
            fileSize: localData.fileSize,
            latitude: localData.latitude,
            longitude: localData.longitude,
            deviceMake: localData.deviceMake,
            deviceModel: localData.deviceModel,
            exifExposureTime: localData.exifExposureTime,
            exifFNumber: localData.exifFNumber,
            exifIso: localData.exifIso,
            exifFocalLength: localData.exifFocalLength,
            isHdr: localData.isHdr,
          ),
        );
      }

      // 5. 注意：排序将在 getTimelineAssets() 方法中根据 sortConfig 统一处理
      // 这里不再硬编码排序，保持数据原始顺序

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
  Future<List<BaseAsset>> _getLocalAssetsOnly(LocalAssetDao localDao) async {
    final localAssetsData = await localDao.getAllAssets();

    final localAssets = <BaseAsset>[];

    for (final data in localAssetsData) {
      localAssets.add(
        LocalAsset.fromData(
          id: data.id,
          name: data.name,
          checksum: null,
          type: data.type,
          createdAt: data.createdAt,
          updatedAt: data.updatedAt,
          width: data.width,
          height: data.height,
          durationInSeconds: data.durationInSeconds,
          isFavorite: data.isFavorite,
          isUploaded: data.isUploaded,
          orientation: data.orientation,
          remoteAssetId: null,
          assetEntity: null,
          livePhotoVideoId: data.livePhotoVideoId,
          fileSize: data.fileSize,
          latitude: data.latitude,
          longitude: data.longitude,
          deviceMake: data.deviceMake,
          deviceModel: data.deviceModel,
          exifExposureTime: data.exifExposureTime,
          exifFNumber: data.exifFNumber,
          exifIso: data.exifIso,
          exifFocalLength: data.exifFocalLength,
          isHdr: data.isHdr,
        ),
      );
    }

    // 注意：排序将在 getTimelineAssets() 方法中根据 sortConfig 统一处理
    // 这里不再硬编码排序，保持数据原始顺序
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

      // 并行转换资产（不再关联远程资产）
      final localAssetsResults = await Future.wait(
        assets.map((asset) async {
          try {
            return await _convertAssetEntityToLocalAsset(asset);
          } catch (e) {
            _logger.warning('转换资产失败: ${asset.id}', e);
            return null;
          }
        }),
      );

      // 过滤掉转换失败的结果
      final localAssets = localAssetsResults.whereType<LocalAsset>().toList();

      // 注意：排序将在 getTimelineAssets() 方法中根据 sortConfig 统一处理
      // 这里不再硬编码排序，保持数据原始顺序

      _logger.info('从 photo_manager 加载 ${localAssets.length} 个资产');

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

    // 验证文件对象可访问
    final file = await asset.originFile;
    if (file == null) {
      throw Exception('无法获取文件对象: assetId=${asset.id}');
    }

    // 获取原始文件名（参考 Immich：使用 titleAsync，iOS 上 entity.title 可能为随机 GUID）
    String originalFileName = '';
    try {
      final fromTitle = await asset.titleAsync;
      if (fromTitle.isNotEmpty) {
        originalFileName = fromTitle;
      }
    } catch (e) {
      _logger.fine('获取原文件名 titleAsync 失败: ${asset.id}');
    }
    if (originalFileName.isEmpty) {
      final path = file.path;
      if (path.isNotEmpty) {
        originalFileName = p.basename(path);
      }
    }

    // 获取收藏状态
    // 通过原生 API 从系统相册获取收藏状态
    bool isFavorite = false;
    try {
      isFavorite = await _assetNativeApi.getIsFavorite(asset.id);
    } catch (e) {
      // 获取失败时默认为 false，不影响时间线显示
      _logger.fine('获取收藏状态失败: ${asset.id}, 默认为 false');
    }

    // Live Photo：仅图片且 isLivePhoto 为 true 时传入 livePhotoVideoId（主图 id，motion 由同一 AssetEntity 提供）
    String? livePhotoVideoId;
    if (assetType == AssetType.image) {
      try {
        final isLive = asset.isLivePhoto;
        if (isLive) livePhotoVideoId = asset.id;
      } catch (e) {
        _logger.fine('获取 Live Photo 状态失败: ${asset.id}, 默认为非 Live Photo');
      }
    }

    return LocalAsset.fromData(
      id: asset.id,
      name: originalFileName,
      checksum: null,
      type: assetType,
      createdAt: asset.createDateTime,
      updatedAt: asset.modifiedDateTime,
      width: asset.width,
      height: asset.height,
      durationInSeconds: asset.duration,
      isFavorite: isFavorite,
      isUploaded: false,
      orientation: asset.orientation,
      remoteAssetId: null,
      assetEntity: asset,
      livePhotoVideoId: livePhotoVideoId,
      isHdr: null,
      // photo_manager 数据源不读 DB，媒体详细信息为 null，详情页可后续按需从 AssetEntity 取
    );
  }
}
