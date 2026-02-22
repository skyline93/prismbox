// lib/features/remote_sync/services/remote_sync_service.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:prismbox/core/config/network_config.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/asset_visibility.dart';
import 'package:prismbox/features/remote_sync/models/remote_sync_result.dart';
import 'package:prismbox/features/remote_sync/services/checkpoint_store.dart';
import 'package:prismbox/features/remote_sync/services/sync_stream_handler.dart';
import 'package:prismbox/infrastructure/api/api_service.dart';

/// 远程同步服务
/// 负责从服务器同步远程媒体资源到本地数据库；流式同步与 checkpoint 通过 Dio 发起，与其它 API 共用认证与 401 自动刷新重试。
class RemoteSyncService {
  final ApiService _apiService;
  final AppDatabase _database;
  final CheckpointStore _checkpointStore;
  final Logger _logger = Logger('RemoteSyncService');

  /// 批量处理大小
  static const int _batchSize = 100;

  /// 当前流式同步的取消令牌（Dio CancelToken），用于 cancel() 中止请求
  CancelToken? _cancelToken;

  RemoteSyncService({
    required ApiService apiService,
    required AppDatabase database,
    required CheckpointStore checkpointStore,
  })  : _apiService = apiService,
        _database = database,
        _checkpointStore = checkpointStore;

  /// 流式同步远程资产（通过 Dio 请求，与其它 API 共用认证与 401 自动刷新重试；取消使用 [cancel] 触发的 CancelToken）
  ///
  /// [userId] 用户 ID
  /// [reset] 是否重置同步
  /// [updatedAfter] 增量同步时间戳（可选）
  /// [onProgress] 进度回调
  /// [resyncDepth] 重新同步的递归深度（防止无限循环）
  ///
  /// 返回同步结果。用户取消时返回已处理统计，不将取消记入 errors。
  Future<RemoteSyncResult> syncRemoteStream({
    required String userId,
    bool reset = false,
    DateTime? updatedAfter,
    void Function(int current, int total)? onProgress,
    int resyncDepth = 0,
  }) async {
    if (resyncDepth > 1) {
      _logger.warning('重新同步深度超过限制，停止递归');
      return RemoteSyncResult(
        errors: ['重新同步深度超过限制'],
        duration: Duration.zero,
      );
    }

    _cancelToken = CancelToken();
    final stopwatch = Stopwatch()..start();
    var addedCount = 0;
    var updatedCount = 0;
    var deletedCount = 0;
    final errors = <String>[];
    final handler = SyncStreamHandler();
    final remoteDao = RemoteAssetDao(_database);
    final batch = <RemoteAssetEntityData>[];

    try {
      if (_apiService.endpoint == null || _apiService.endpoint!.isEmpty) {
        throw Exception('API endpoint not configured');
      }

      final requestBody = <String, dynamic>{
        'types': ['assets_v1'],
        'reset': reset,
      };
      if (updatedAfter != null) {
        requestBody['updated_after'] =
            updatedAfter.toUtc().toIso8601String();
      }

      _logger.info(
          '开始流式同步: reset=$reset, updatedAfter=$updatedAfter, resyncDepth=$resyncDepth');

      final response = await _apiService.dio.post<ResponseBody>(
        '/api/v1/sync/assets/stream',
        data: requestBody,
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: NetworkConfig.syncStreamReceiveTimeout,
          headers: <String, dynamic>{
            'Content-Type': 'application/json',
            'Accept': 'application/jsonlines+json',
          },
        ),
        cancelToken: _cancelToken,
      );

      if (response.statusCode != 200) {
        throw Exception('同步失败: ${response.statusCode}');
      }

      final responseBody = response.data;
      if (responseBody == null) {
        throw Exception('流式响应体为空');
      }

      bool shouldResync = false;

      await for (final chunk in responseBody.stream
          .cast<List<int>>()
          .transform(utf8.decoder)) {
        if (_cancelToken?.isCancelled ?? false) {
          _logger.info('同步已取消');
          break;
        }

        final events = handler.processChunk(chunk);

        for (final event in events) {
          if (_cancelToken?.isCancelled ?? false) break;

          if (event.type == SyncEntityType.syncResetV1) {
            shouldResync = true;
          }

          final result = await _handleSyncEvent(
            event,
            userId,
            remoteDao,
            batch,
            errors,
            onProgress,
          );
          addedCount += result['added'] as int;
          updatedCount += result['updated'] as int;
          deletedCount += result['deleted'] as int;

          if (batch.length >= _batchSize) {
            final batchResult = await _flushBatch(remoteDao, batch);
            addedCount += batchResult['added'] as int;
            updatedCount += batchResult['updated'] as int;
            onProgress?.call(addedCount + updatedCount, -1);
          }
        }
      }

      if (batch.isNotEmpty) {
        final batchResult = await _flushBatch(remoteDao, batch);
        addedCount += batchResult['added'] as int;
        updatedCount += batchResult['updated'] as int;
      }

      handler.clear();
      _cancelToken = null;

      if (shouldResync) {
        _logger.info('收到重置事件，重新发起全量同步以获取所有数据');
        final resyncResult = await syncRemoteStream(
          userId: userId,
          reset: true,
          updatedAfter: null,
          onProgress: onProgress,
          resyncDepth: resyncDepth + 1,
        );
        addedCount += resyncResult.addedCount;
        updatedCount += resyncResult.updatedCount;
        deletedCount += resyncResult.deletedCount;
        errors.addAll(resyncResult.errors);
      }

      _logger.info(
          '流式同步完成: $addedCount 新增, $updatedCount 更新, $deletedCount 删除, ${errors.length} 错误');

      return RemoteSyncResult(
        addedCount: addedCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        errors: errors,
        duration: stopwatch.elapsed,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        _logger.info('同步已取消');
        _cancelToken = null;
        return RemoteSyncResult(
          addedCount: addedCount,
          updatedCount: updatedCount,
          deletedCount: deletedCount,
          errors: errors,
          duration: stopwatch.elapsed,
        );
      }
      _logger.severe('远程同步失败', e, e.stackTrace);
      _cancelToken = null;
      return RemoteSyncResult(
        addedCount: addedCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        errors: [...errors, e.toString()],
        duration: stopwatch.elapsed,
      );
    } catch (e, stackTrace) {
      _logger.severe('远程同步失败', e, stackTrace);
      _cancelToken = null;
      return RemoteSyncResult(
        addedCount: addedCount,
        updatedCount: updatedCount,
        deletedCount: deletedCount,
        errors: [...errors, e.toString()],
        duration: stopwatch.elapsed,
      );
    }
  }

  /// 处理同步事件
  /// 返回处理结果：{added: int, updated: int, deleted: int}
  Future<Map<String, int>> _handleSyncEvent(
    SyncEvent event,
    String userId,
    RemoteAssetDao remoteDao,
    List<RemoteAssetEntityData> batch,
    List<String> errors,
    void Function(int current, int total)? onProgress,
  ) async {
    var added = 0;
    var updated = 0;
    var deleted = 0;

    try {
      switch (event.type) {
        case SyncEntityType.assetV1:
          // 处理资产数据
          // 根据后端实现，data 字段直接是数组（批量发送）
          // SyncStreamHandler 已经将数组包装在 'data' 键下
          final dataValue = event.data['data'];
          if (dataValue is List) {
            // 批量数据
            for (final assetData in dataValue) {
              if (assetData is Map<String, dynamic>) {
                final remoteAsset = _parseRemoteAsset(assetData, userId);
                if (remoteAsset != null) {
                  batch.add(remoteAsset);
                }
              }
            }
          } else if (dataValue is Map<String, dynamic>) {
            // 单个资产对象（兼容处理）
            final remoteAsset = _parseRemoteAsset(dataValue, userId);
            if (remoteAsset != null) {
              batch.add(remoteAsset);
            }
          }

          // 更新 checkpoint
          if (event.ack != null) {
            await _checkpointStore.setCheckpoint(userId, 'assets_v1', event.ack!);
          }
          break;

        case SyncEntityType.syncCompleteV1:
          // 同步完成，保存服务端 checkpoint
          _logger.info('收到同步完成事件');
          if (event.ids.isNotEmpty) {
            final ack = event.ids.first;
            await _saveServerCheckpoint(userId, 'assets_v1', ack);
          }
          break;

        case SyncEntityType.syncResetV1:
          // 需要全量同步
          _logger.info('收到同步重置事件');
          await _checkpointStore.clearCheckpoint(userId, 'assets_v1');
          break;

        case SyncEntityType.assetDeleteV1:
          // 处理删除事件
          for (final assetId in event.ids) {
            final deletedResult = await remoteDao.softDeleteAsset(assetId);
            if (deletedResult) {
              deleted++;
            }
          }
          break;

        case SyncEntityType.unknown:
          _logger.warning('未知的同步事件类型: ${event.data}');
          break;
      }
    } catch (e, stackTrace) {
      _logger.warning('处理同步事件失败', e, stackTrace);
      errors.add('处理事件失败: ${e.toString()}');
    }

    return {'added': added, 'updated': updated, 'deleted': deleted};
  }

  /// 刷新批量数据到数据库
  /// 返回处理结果：{added: int, updated: int}
  Future<Map<String, int>> _flushBatch(
    RemoteAssetDao remoteDao,
    List<RemoteAssetEntityData> batch,
  ) async {
    var added = 0;
    var updated = 0;

    if (batch.isEmpty) {
      return {'added': added, 'updated': updated};
    }

    try {
      // 批量插入或更新
      for (final asset in batch) {
        final existing = await remoteDao.getAssetById(asset.id);
        if (existing == null) {
          await remoteDao.insertAsset(asset);
          added++;
        } else {
          await remoteDao.updateAsset(asset);
          updated++;
        }
      }
      batch.clear();
    } catch (e, stackTrace) {
      _logger.severe('批量写入数据库失败', e, stackTrace);
      batch.clear();
      rethrow;
    }

    return {'added': added, 'updated': updated};
  }

  /// 解析远程资产数据
  RemoteAssetEntityData? _parseRemoteAsset(
    Map<String, dynamic> data,
    String userId,
  ) {
    try {
      // 转换 item_type 为 AssetType
      final itemType = data['item_type'] as String? ?? 'other';
      final assetType = _convertItemTypeToAssetType(itemType);

      // 解析时间
      final createdAt = _parseDateTime(data['created_at'] as String?);
      final updatedAt = _parseDateTime(data['updated_at'] as String?);
      final mediaTakenAt = _parseDateTime(data['media_taken_at'] as String?);

      // 解析 deletedAt 字段
      // 注意：后端同步 API 只返回未删除的资产（deleted = false），
      // 所以同步数据中不会包含已删除的资产。
      // 如果后端将来添加了 deleted_at 字段，优先使用它；
      // 否则，由于只返回未删除的资产，deletedAt 应该为 null。
      DateTime? deletedAt;
      if (data.containsKey('deleted_at')) {
        // 如果后端提供了 deleted_at 字段，解析它
        deletedAt = _parseDateTime(data['deleted_at'] as String?);
      } else if (data.containsKey('deleted')) {
        // 如果后端提供了 deleted 布尔字段，根据它设置 deletedAt
        final deleted = data['deleted'] as bool? ?? false;
        if (deleted) {
          // 如果 deleted 为 true，但没有提供 deleted_at 时间，使用 updatedAt 作为删除时间
          deletedAt = updatedAt ?? DateTime.now();
        } else {
          deletedAt = null;
        }
      } else {
        // 后端没有提供删除相关字段，说明该资产未删除
        // 因为同步 API 只返回未删除的资产（deleted = false）
        deletedAt = null;
      }
      // 解析 Live Photo 关联视频 ID（与后端约定字段名）
      // 优先使用 snake_case：live_photo_video_id；兼容可能的 camelCase：livePhotoVideoId
      final livePhotoVideoId = (data['live_photo_video_id'] ??
              data['livePhotoVideoId']) as String?;
      // 媒体详情（同步时写入，便于仅远程媒体在预览中展示）
      final fileSize = (data['file_size'] as num?)?.toInt();
      final latitude = (data['latitude'] as num?)?.toDouble();
      final longitude = (data['longitude'] as num?)?.toDouble();
      final deviceMake = data['device_make'] as String?;
      final deviceModel = data['device_model'] as String?;
      final exifExposureTime = data['exif_exposure_time'] as String?;
      final exifFNumber = (data['exif_f_number'] as num?)?.toDouble();
      final exifIso = (data['exif_iso'] as num?)?.toInt();
      final exifFocalLength = (data['exif_focal_length'] as num?)?.toDouble();

      return RemoteAssetEntityData(
        id: data['uuid'] as String,
        checksum: data['hash'] as String? ?? '',
        ownerId: userId,
        name: data['original_filename'] as String? ??
            data['filename'] as String? ??
            data['uuid'] as String,
        type: assetType,
        createdAt: createdAt ?? DateTime.now(),
        updatedAt: updatedAt ?? DateTime.now(),
        width: data['width'] as int?,
        height: data['height'] as int?,
        durationInSeconds: (data['duration_in_seconds'] as num?)?.toInt(),
        isFavorite: false, // 服务器数据中可能没有这个字段
        localDateTime: mediaTakenAt,
        thumbHash: null, // 服务器数据中可能没有这个字段
        deletedAt: deletedAt,
        livePhotoVideoId: livePhotoVideoId,
        visibility: AssetVisibility.private,
        stackId: null,
        libraryId: null,
        fileSize: fileSize,
        latitude: latitude,
        longitude: longitude,
        deviceMake: deviceMake,
        deviceModel: deviceModel,
        exifExposureTime: exifExposureTime,
        exifFNumber: exifFNumber,
        exifIso: exifIso,
        exifFocalLength: exifFocalLength,
      );
    } catch (e, stackTrace) {
      _logger.warning('解析远程资产数据失败', e, stackTrace);
      return null;
    }
  }

  /// 转换 item_type 字符串为 AssetType 枚举
  AssetType _convertItemTypeToAssetType(String itemType) {
    switch (itemType.toLowerCase()) {
      case 'image':
        return AssetType.image;
      case 'video':
        return AssetType.video;
      case 'audio':
        return AssetType.audio;
      default:
        return AssetType.other;
    }
  }

  /// 解析日期时间字符串
  DateTime? _parseDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) {
      return null;
    }
    try {
      return DateTime.parse(dateTimeStr).toLocal();
    } catch (e) {
      _logger.warning('解析日期时间失败: $dateTimeStr', e);
      return null;
    }
  }

  /// 保存服务端 checkpoint（通过 Dio 发送，与其它 API 共用认证与 401 重试）
  ///
  /// [userId] 用户 ID
  /// [syncType] 同步类型
  /// [ack] checkpoint ID
  Future<void> _saveServerCheckpoint(
    String userId,
    String syncType,
    String ack,
  ) async {
    try {
      final requestBody = {
        'checkpoints': [
          {
            'type': syncType,
            'ack': ack,
          }
        ]
      };

      final response = await _apiService.dio.post<dynamic>(
        '/api/v1/sync/checkpoint',
        data: requestBody,
      );

      if (response.statusCode == 204) {
        _logger.fine('服务端 checkpoint 保存成功: $syncType = $ack');
      } else {
        _logger.warning(
            '服务端 checkpoint 保存失败: status=${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _logger.warning('保存服务端 checkpoint 失败', e, stackTrace);
      // 不抛出异常，避免影响同步流程
    }
  }

  /// 取消同步（中止当前流式请求，由 Dio CancelToken 触发）
  void cancel() {
    _cancelToken?.cancel();
    _cancelToken = null;
    _logger.info('同步已取消');
  }
}

