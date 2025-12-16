// lib/services/backup/background_sync_manager.dart

import 'dart:async';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';
import 'package:prismbox/features/local_sync/services/local_sync_service.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';
import 'package:prismbox/services/backup/asset_path_resolver.dart';
import 'package:prismbox/utils/cancellation_token.dart';

/// 后台同步结果
class BackgroundSyncResult {
  final int addedCount;
  final int updatedCount;
  final int deletedCount;
  final List<String> errors;
  final Duration duration;

  BackgroundSyncResult({
    required this.addedCount,
    required this.updatedCount,
    required this.deletedCount,
    required this.errors,
    required this.duration,
  });

  factory BackgroundSyncResult.combine(
      BackgroundSyncResult a, BackgroundSyncResult b) {
    return BackgroundSyncResult(
      addedCount: a.addedCount + b.addedCount,
      updatedCount: a.updatedCount + b.updatedCount,
      deletedCount: a.deletedCount + b.deletedCount,
      errors: [...a.errors, ...b.errors],
      duration: a.duration + b.duration,
    );
  }

  factory BackgroundSyncResult.success() {
    return BackgroundSyncResult(
      addedCount: 0,
      updatedCount: 0,
      deletedCount: 0,
      errors: [],
      duration: Duration.zero,
    );
  }
}

/// 后台同步管理器
/// 
/// **职责**：
/// - 同步本地媒体库到数据库
/// - 同步远程服务器资产列表
/// - 计算资产哈希值（用于去重）
/// 
/// **三阶段设计**：
/// 1. **阶段一：本地同步（syncLocal）**
///    - 扫描设备媒体库
///    - 识别新增、修改、删除的资产
///    - 更新本地数据库
/// 
/// 2. **阶段二：远程同步（syncRemote）**
///    - 调用服务器 API 获取已上传资产列表
///    - 更新本地数据库中的远程资产信息
///    - 用于后续去重判断
/// 
/// 3. **阶段三：哈希计算（hashAssets，可选）**
///    - 计算待上传资产的哈希值（checksum）
///    - 支持超时机制，避免阻塞备份流程
///    - 使用后台 Isolate 进行计算
class BackgroundSyncManager {
  final AppDatabase _database;
  final LocalSyncService _localSyncService;
  final ApiService _apiService;
  final AssetPathResolver _pathResolver;
  final Logger _logger = Logger('BackgroundSyncManager');

  // 远程同步配置
  static const String _remoteAssetsEndpoint = '/api/v1/media/list';
  static const int _pageSize = 100; // 每页最多 100 条

  BackgroundSyncManager({
    required AppDatabase database,
    required LocalSyncService localSyncService,
    ApiService? apiService,
    required AssetPathResolver pathResolver,
  })  : _database = database,
        _localSyncService = localSyncService,
        _apiService = apiService ?? ApiService(),
        _pathResolver = pathResolver;

  /// 执行完整同步流程（三阶段）
  /// 
  /// **参数**：
  /// - [cancellationToken] - 取消令牌
  /// - [hashTimeout] - 哈希计算超时时间（可选）
  /// 
  /// **返回**：BackgroundSyncResult（同步结果）
  /// 
  /// **执行流程**：
  /// 1. 阶段一：本地同步
  /// 2. 阶段二：远程同步
  /// 3. 阶段三：哈希计算（可选）
  Future<BackgroundSyncResult> syncAll({
    required CancellationToken cancellationToken,
    Duration? hashTimeout,
  }) async {
    _logger.info('Starting full sync (three phases)');

    final stopwatch = Stopwatch()..start();

    try {
      // 阶段一：本地同步
      final localResult = await syncLocal(
        cancellationToken: cancellationToken,
      );

      if (cancellationToken.isCancelled) {
        _logger.info('Sync cancelled after local sync');
        return localResult;
      }

      // 阶段二：远程同步
      final remoteResult = await syncRemote(
        cancellationToken: cancellationToken,
      );

      if (cancellationToken.isCancelled) {
        _logger.info('Sync cancelled after remote sync');
        return BackgroundSyncResult.combine(localResult, remoteResult);
      }

      // 阶段三：哈希计算（可选，根据配置决定）
      // 注意：这里暂时跳过哈希计算，后续可以根据配置决定是否执行
      // if (shouldCalculateHashes) {
      //   await hashAssets(
      //     assetIds: pendingAssetIds,
      //     cancellationToken: cancellationToken,
      //     timeout: hashTimeout ?? const Duration(seconds: 30),
      //   );
      // }

      stopwatch.stop();

      final result = BackgroundSyncResult.combine(localResult, remoteResult);
      _logger.info(
        'Full sync completed in ${stopwatch.elapsed.inSeconds}s: '
        'added=${result.addedCount}, updated=${result.updatedCount}, '
        'deleted=${result.deletedCount}',
      );

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.severe('Full sync failed', e, stackTrace);
      return BackgroundSyncResult(
        addedCount: 0,
        updatedCount: 0,
        deletedCount: 0,
        errors: [e.toString()],
        duration: stopwatch.elapsed,
      );
    }
  }

  /// 同步本地媒体库
  /// 
  /// **参数**：
  /// - [cancellationToken] - 取消令牌
  /// 
  /// **返回**：BackgroundSyncResult（同步结果）
  /// 
  /// **执行流程**：
  /// 1. 使用 LocalSyncService 同步本地媒体库
  /// 2. 转换同步结果为 BackgroundSyncResult
  Future<BackgroundSyncResult> syncLocal({
    required CancellationToken cancellationToken,
  }) async {
    _logger.info('Starting local sync (phase 1)');

    final stopwatch = Stopwatch()..start();

    try {
      // 使用 LocalSyncService 同步本地媒体库
      final result = await _localSyncService.syncLocal(
        full: false, // 增量同步
        onProgress: (current, total) {
          if (cancellationToken.isCancelled) {
            _localSyncService.cancel();
          }
        },
      );

      stopwatch.stop();

      // 转换同步结果
      final syncResult = BackgroundSyncResult(
        addedCount: result.added,
        updatedCount: result.updated,
        deletedCount: result.deleted,
        errors: result.error != null ? [result.error!] : [],
        duration: stopwatch.elapsed,
      );

      _logger.info(
        'Local sync completed in ${stopwatch.elapsed.inSeconds}s: '
        'added=${syncResult.addedCount}, updated=${syncResult.updatedCount}, '
        'deleted=${syncResult.deletedCount}',
      );

      return syncResult;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.severe('Local sync failed', e, stackTrace);
      return BackgroundSyncResult(
        addedCount: 0,
        updatedCount: 0,
        deletedCount: 0,
        errors: [e.toString()],
        duration: stopwatch.elapsed,
      );
    }
  }

  /// 同步远程服务器资产
  /// 
  /// **参数**：
  /// - [cancellationToken] - 取消令牌
  /// 
  /// **返回**：BackgroundSyncResult（同步结果）
  /// 
  /// **执行流程**：
  /// 1. 调用服务器 API 获取已上传资产列表（分页）
  /// 2. 更新本地数据库中的远程资产信息
  /// 3. 用于后续去重判断
  /// 
  /// **API 格式**：
  /// - 请求：GET /api/v1/media/list?page=1&pageSize=100
  /// - 响应：{ "items": [...], "total": 1000, "page": 1, "pageSize": 100 }
  Future<BackgroundSyncResult> syncRemote({
    required CancellationToken cancellationToken,
  }) async {
    _logger.info('Starting remote sync (phase 2)');

    final stopwatch = Stopwatch()..start();
    int addedCount = 0;
    int updatedCount = 0;
    int deletedCount = 0;
    final errors = <String>[];

    try {
      final endpoint = _apiService.endpoint ?? '';
      final url = '$endpoint$_remoteAssetsEndpoint';
      final headers = ApiService.getRequestHeaders();

      // 分页获取远程资产
      int page = 1;
      bool hasMore = true;
      final Set<String> remoteAssetIds = {}; // 用于检测已删除的资产

      while (hasMore && !cancellationToken.isCancelled) {
        try {
          final response = await _apiService.dio.get(
            url,
            queryParameters: {
              'page': page,
              'pageSize': _pageSize,
            },
            options: Options(headers: headers),
          );

          if (response.statusCode != null &&
              response.statusCode! >= 200 &&
              response.statusCode! < 300) {
            final data = response.data as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>? ?? [];
            final total = data['total'] as int? ?? 0;
            final currentPage = data['page'] as int? ?? page;
            final pageSize = data['pageSize'] as int? ?? _pageSize;

            _logger.info(
              'Fetched remote assets: page=$currentPage, '
              'items=${items.length}, total=$total',
            );

            // 处理每个资产
            for (final item in items) {
              if (cancellationToken.isCancelled) {
                break;
              }

              try {
                final assetData = item as Map<String, dynamic>;
                final remoteAsset = _parseRemoteAsset(assetData);
                remoteAssetIds.add(remoteAsset.id);

                // 检查本地是否已存在
                final existing = await _database.remoteAssetDao
                    .getAssetById(remoteAsset.id);

                if (existing == null) {
                  // 新增
                  await _database.remoteAssetDao.insertAsset(remoteAsset);
                  addedCount++;
                } else {
                  // 更新
                  await _database.remoteAssetDao.updateAsset(remoteAsset);
                  updatedCount++;
                }
              } catch (e) {
                _logger.warning('Failed to process remote asset: $e');
                errors.add('Failed to process asset: $e');
              }
            }

            // 检查是否还有更多页
            final totalPages = (total / pageSize).ceil();
            hasMore = currentPage < totalPages;
            page++;

            if (hasMore) {
              _logger.info('Fetching next page: $page');
            }
          } else {
            throw Exception(
              'Failed to fetch remote assets: ${response.statusCode}',
            );
          }
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to fetch page $page: $e',
            e,
            stackTrace,
          );
          errors.add('Failed to fetch page $page: $e');
          // 继续下一页或结束
          hasMore = false;
        }
      }

      // 检测已删除的资产（软删除）
      // 注意：这里只标记本地存在但服务器不存在的资产为已删除
      // 实际删除逻辑可能需要更复杂的策略
      // TODO: 实现更完善的删除检测逻辑

      stopwatch.stop();

      final result = BackgroundSyncResult(
        addedCount: addedCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        errors: errors,
        duration: stopwatch.elapsed,
      );

      _logger.info(
        'Remote sync completed in ${stopwatch.elapsed.inSeconds}s: '
        'added=$addedCount, updated=$updatedCount, deleted=$deletedCount',
      );

      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.severe('Remote sync failed', e, stackTrace);
      return BackgroundSyncResult(
        addedCount: addedCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        errors: [...errors, e.toString()],
        duration: stopwatch.elapsed,
      );
    }
  }

  /// 解析远程资产数据
  /// 
  /// **参数**：
  /// - [data] - API 返回的资产数据
  /// 
  /// **返回**：RemoteAssetEntityData
  RemoteAssetEntityData _parseRemoteAsset(Map<String, dynamic> data) {
    // 根据实际 API 响应格式解析
    // 这里假设 API 返回的格式包含以下字段
    return RemoteAssetEntityData(
      id: data['id'] as String,
      name: data['name'] as String? ?? '',
      checksum: data['checksum'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? data['owner_id'] as String? ?? '',
      type: _parseAssetType(data['type'] as String?),
      createdAt: _parseDateTime(data['createdAt'] ?? data['created_at']),
      updatedAt: _parseDateTime(data['updatedAt'] ?? data['updated_at']),
      width: data['width'] as int?,
      height: data['height'] as int?,
      durationInSeconds: data['durationInSeconds'] as int? ??
          data['duration_in_seconds'] as int?,
      isFavorite: data['isFavorite'] as bool? ?? data['is_favorite'] as bool? ?? false,
      thumbHash: data['thumbHash'] as String? ?? data['thumb_hash'] as String?,
      visibility: _parseVisibility(data['visibility'] as String?),
      livePhotoVideoId: data['livePhotoVideoId'] as String? ??
          data['live_photo_video_id'] as String?,
      stackId: data['stackId'] as String? ?? data['stack_id'] as String?,
      libraryId: data['libraryId'] as String? ?? data['library_id'] as String?,
      deletedAt: null, // 已删除的资产不会出现在列表中
    );
  }

  /// 解析资产类型
  AssetType _parseAssetType(String? type) {
    if (type == null) return AssetType.image;
    switch (type.toLowerCase()) {
      case 'image':
      case 'photo':
        return AssetType.image;
      case 'video':
        return AssetType.video;
      default:
        return AssetType.image;
    }
  }

  /// 解析可见性
  AssetVisibility _parseVisibility(String? visibility) {
    if (visibility == null) return AssetVisibility.private;
    switch (visibility.toLowerCase()) {
      case 'public':
        return AssetVisibility.public;
      case 'private':
        return AssetVisibility.private;
      default:
        return AssetVisibility.private;
    }
  }

  /// 解析日期时间
  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    if (value is int) {
      // Unix 时间戳（秒）
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    return DateTime.now();
  }

  /// 计算资产哈希值
  /// 
  /// **参数**：
  /// - [assetIds] - 资产 ID 列表
  /// - [cancellationToken] - 取消令牌
  /// - [timeout] - 超时时间（可选，默认 30 秒）
  /// 
  /// **执行流程**：
  /// 1. 查询需要计算哈希的资产（checksum 为 null 或空）
  /// 2. 分批计算哈希值（每批最多 10 个，避免内存占用过大）
  /// 3. 支持超时机制，避免阻塞备份流程
  /// 4. 更新本地数据库中的 checksum 字段
  /// 
  /// **注意**：
  /// - 大文件哈希计算可能耗时较长，使用超时机制避免阻塞
  /// - 如果超时，已计算的哈希值会保存，未计算的留待下次处理
  Future<void> hashAssets({
    required List<String> assetIds,
    required CancellationToken cancellationToken,
    Duration? timeout,
  }) async {
    _logger.info(
      'Starting hash calculation (phase 3): assetIds=${assetIds.length}',
    );

    final stopwatch = Stopwatch()..start();
    final effectiveTimeout = timeout ?? const Duration(seconds: 30);
    final batchSize = 10; // 每批最多 10 个，避免内存占用过大
    int processedCount = 0;

    try {
      // 1. 查询需要计算哈希的资产
      final dao = _database.localAssetDao;
      final assetsToHash = <String>[];

      for (final assetId in assetIds) {
        if (cancellationToken.isCancelled) {
          break;
        }

        final asset = await dao.getAssetById(assetId);
        if (asset != null &&
            (asset.checksum == null || asset.checksum!.isEmpty)) {
          assetsToHash.add(assetId);
        }
      }

      if (assetsToHash.isEmpty) {
        _logger.info('No assets need hash calculation');
        return;
      }

      _logger.info('Found ${assetsToHash.length} assets need hash calculation');

      // 2. 分批计算哈希值
      for (int i = 0; i < assetsToHash.length; i += batchSize) {
        if (cancellationToken.isCancelled) {
          _logger.info('Hash calculation cancelled');
          break;
        }

        // 检查是否超时
        if (stopwatch.elapsed > effectiveTimeout) {
          _logger.warning(
            'Hash calculation timeout after ${stopwatch.elapsed.inSeconds}s, '
            'processed $processedCount/${assetsToHash.length} assets',
          );
          break;
        }

        final batch = assetsToHash.skip(i).take(batchSize).toList();
        _logger.fine('Processing hash batch: ${batch.length} assets');

        // 计算批次哈希值
        await Future.wait(
          batch.map((assetId) async {
            try {
              final asset = await dao.getAssetById(assetId);
              if (asset == null) {
                return;
              }

              // 检查文件是否存在
              if (!await _pathResolver.validateFileExists(asset.path)) {
                _logger.warning('File not found for hash calculation: ${asset.path}');
                return;
              }

              // 计算哈希值（使用 SHA256）
              final checksum = await _calculateFileChecksum(asset.path);

              // 更新数据库
              final updatedAsset = asset.copyWith(
                checksum: Value(checksum),
                updatedAt: DateTime.now(),
              );
              await dao.updateAsset(updatedAsset);

              processedCount++;
              _logger.fine(
                'Hash calculated for asset: assetId=$assetId, checksum=$checksum',
              );
            } catch (e, stackTrace) {
              _logger.warning(
                'Failed to calculate hash for assetId=$assetId: $e',
                e,
                stackTrace,
              );
            }
          }),
        );
      }

      stopwatch.stop();
      _logger.info(
        'Hash calculation completed in ${stopwatch.elapsed.inSeconds}s: '
        'processed $processedCount/${assetsToHash.length} assets',
      );
    } catch (e, stackTrace) {
      stopwatch.stop();
      _logger.severe('Hash calculation failed', e, stackTrace);
    }
  }

  /// 计算文件 checksum（SHA256）
  /// 
  /// **参数**：
  /// - [filePath] - 文件路径
  /// 
  /// **返回**：SHA256 哈希值（十六进制字符串）
  /// 
  /// **注意**：
  /// - 对于大文件，此操作可能耗时较长
  /// - 建议在后台 Isolate 中执行（当前实现为同步，后续可优化）
  Future<String> _calculateFileChecksum(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

