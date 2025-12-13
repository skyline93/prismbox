// lib/services/backup/backup_candidate_selector.dart

import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/backup_selection.dart';
import 'package:prismbox/features/local_sync/services/local_sync_service.dart';

/// 候选资源筛选器
/// 
/// **职责**：
/// - 负责候选资源筛选（三种自动备份模式的筛选逻辑）
/// - 根据备份模式筛选待上传资产
/// - 不负责去重和上传编排
/// 
/// **职责边界**：
/// - ✅ **负责**：候选资源筛选（all_unbacked、selected_albums、time_range）
/// - ❌ **不负责**：去重检查（由 UploadOrchestrator 负责）
/// - ❌ **不负责**：上传编排（由 UploadOrchestrator 负责）
class BackupCandidateSelector {
  final AppDatabase _database;
  final LocalSyncService _localSyncService;
  final Logger _logger = Logger('BackupCandidateSelector');

  BackupCandidateSelector({
    required AppDatabase database,
    required LocalSyncService localSyncService,
  })  : _database = database,
        _localSyncService = localSyncService; // 保留用于后续扩展

  /// 筛选所有未备份资源（模式 A：all_unbacked）
  /// 
  /// **筛选逻辑**：
  /// - 基于 `lastBackupTime` 筛选（只获取上次备份后的新资产）
  /// - 排除 `backupSelection = excluded` 的相册中的资产
  /// - 如果 `lastBackupTime` 为 null，返回所有资产（首次备份）
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [lastBackupTime] - 最后备份时间（可选）
  /// 
  /// **返回**：List<LocalAssetEntityData>
  Future<List<LocalAssetEntityData>> selectAllUnbacked({
    required String userId,
    DateTime? lastBackupTime,
  }) async {
    _logger.info(
      'Selecting all unbacked assets for userId=$userId, '
      'lastBackupTime=$lastBackupTime',
    );

    // 1. 获取排除的相册 ID 列表
    final excludedAlbumIds = await _getExcludedAlbumIds();

    // 2. 获取所有资产（使用 DAO 方法）
    final dao = _database.localAssetDao;
    final allAssets = lastBackupTime != null
        ? await dao.getAssetsByDateRange(
            lastBackupTime,
            DateTime.now(),
          )
        : await dao.getAllAssets();

    // 5. 过滤排除的相册中的资产
    // 注意：这里假设可以通过其他方式判断资产是否属于排除的相册
    // 如果后续有本地相册资产关联表，可以使用 JOIN 查询
    final filteredAssets = await _filterAssetsByExcludedAlbums(
      allAssets,
      excludedAlbumIds,
    );

    _logger.info(
      'Selected ${filteredAssets.length} unbacked assets '
      '(from ${allAssets.length} total)',
    );

    return filteredAssets;
  }

  /// 筛选选中相册资源（模式 B：selected_albums）
  /// 
  /// **筛选逻辑**：
  /// - 查询 `backupSelection = selected` 的相册
  /// - 获取这些相册中的所有资产
  /// - 可结合时间范围筛选
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [timeRangeStart] - 时间范围起始（可选）
  /// - [timeRangeEnd] - 时间范围结束（可选）
  /// 
  /// **返回**：List<LocalAssetEntityData>
  Future<List<LocalAssetEntityData>> selectSelectedAlbums({
    required String userId,
    DateTime? timeRangeStart,
    DateTime? timeRangeEnd,
  }) async {
    _logger.info(
      'Selecting assets from selected albums for userId=$userId, '
      'timeRange=$timeRangeStart to $timeRangeEnd',
    );

    // 1. 获取选中的相册 ID 列表
    final selectedAlbumIds = await _getSelectedAlbumIds();

    if (selectedAlbumIds.isEmpty) {
      _logger.warning('No selected albums found for userId=$userId');
      return [];
    }

    // 2. 获取这些相册中的资产
    // 注意：这里假设可以通过其他方式获取相册中的资产
    // 如果后续有本地相册资产关联表，可以使用 JOIN 查询
    final assets = await _getAssetsByAlbumIds(
      selectedAlbumIds,
      timeRangeStart: timeRangeStart,
      timeRangeEnd: timeRangeEnd,
    );

    _logger.info(
      'Selected ${assets.length} assets from ${selectedAlbumIds.length} albums',
    );

    return assets;
  }

  /// 筛选时间段资源（模式 C：time_range）
  /// 
  /// **筛选逻辑**：
  /// - 基于时间范围筛选
  /// - 排除 `backupSelection = excluded` 的相册中的资产
  /// 
  /// **参数**：
  /// - [userId] - 用户 ID（必须）
  /// - [timeRangeStart] - 时间范围起始（必须）
  /// - [timeRangeEnd] - 时间范围结束（必须）
  /// 
  /// **返回**：List<LocalAssetEntityData>
  Future<List<LocalAssetEntityData>> selectTimeRange({
    required String userId,
    required DateTime timeRangeStart,
    required DateTime timeRangeEnd,
  }) async {
    _logger.info(
      'Selecting assets in time range for userId=$userId, '
      'timeRange=$timeRangeStart to $timeRangeEnd',
    );

    // 1. 获取排除的相册 ID 列表
    final excludedAlbumIds = await _getExcludedAlbumIds();

    // 2. 构建查询（时间范围，使用 DAO 方法）
    final dao = _database.localAssetDao;
    final assets = await dao.getAssetsByDateRange(
      timeRangeStart,
      timeRangeEnd,
    );

    // 3. 过滤排除的相册中的资产
    final filteredAssets = await _filterAssetsByExcludedAlbums(
      assets,
      excludedAlbumIds,
    );

    _logger.info(
      'Selected ${filteredAssets.length} assets in time range '
      '(from ${assets.length} total)',
    );

    return filteredAssets;
  }

  /// 获取排除的相册 ID 列表
  Future<Set<String>> _getExcludedAlbumIds() async {
    final albums = await (_database.select(_database.localAlbumEntity)
          ..where((t) =>
              t.backupSelection.equalsValue(BackupSelection.excluded)))
        .get();

    return albums.map((a) => a.id).toSet();
  }

  /// 获取选中的相册 ID 列表
  Future<Set<String>> _getSelectedAlbumIds() async {
    final albums = await (_database.select(_database.localAlbumEntity)
          ..where((t) =>
              t.backupSelection.equalsValue(BackupSelection.selected)))
        .get();

    return albums.map((a) => a.id).toSet();
  }

  /// 根据相册 ID 列表获取资产
  /// 
  /// **注意**：这是一个占位实现，假设可以通过其他方式获取相册中的资产
  /// 如果后续有本地相册资产关联表，应该使用 JOIN 查询
  Future<List<LocalAssetEntityData>> _getAssetsByAlbumIds(
    Set<String> albumIds, {
    DateTime? timeRangeStart,
    DateTime? timeRangeEnd,
  }) async {
    // TODO: 实现通过相册 ID 获取资产的逻辑
    // 当前实现返回空列表，需要根据实际的数据结构实现
    _logger.warning(
      'getAssetsByAlbumIds is not fully implemented. '
      'albumIds=$albumIds',
    );

    // 临时实现：返回所有资产（需要后续完善）
    final dao = _database.localAssetDao;
    
    if (timeRangeStart != null && timeRangeEnd != null) {
      return await dao.getAssetsByDateRange(timeRangeStart, timeRangeEnd);
    }

    return await dao.getAllAssets();
  }

  /// 过滤排除的相册中的资产
  /// 
  /// **注意**：这是一个占位实现，假设可以通过其他方式判断资产是否属于排除的相册
  /// 如果后续有本地相册资产关联表，应该使用 JOIN 查询
  Future<List<LocalAssetEntityData>> _filterAssetsByExcludedAlbums(
    List<LocalAssetEntityData> assets,
    Set<String> excludedAlbumIds,
  ) async {
    if (excludedAlbumIds.isEmpty) {
      return assets;
    }

    // TODO: 实现过滤逻辑
    // 当前实现返回所有资产，需要根据实际的数据结构实现
    _logger.warning(
      'filterAssetsByExcludedAlbums is not fully implemented. '
      'excludedAlbumIds=$excludedAlbumIds',
    );

    // 临时实现：返回所有资产（需要后续完善）
    return assets;
  }
}

