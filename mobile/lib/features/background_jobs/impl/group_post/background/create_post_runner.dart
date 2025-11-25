import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/domain/repositories/group_repository.dart';
import 'package:mobile/services/transfer/backupground_upload_service.dart';

const String createPostTask = 'com.example.mobile.create_post';

class CreatePostRunner {
  static final _log = Logger('CreatePostRunner');

  static Future<List<String>> _waitForUuids({
    required MediaAssetDao mediaAssetDao,
    required List<String> assetIds,
    Duration timeout = const Duration(minutes: 20),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final uuids = <String>[];
      bool anyFailed = false;

      for (final id in assetIds) {
        final a = await mediaAssetDao.getAssetByLocalId(id);
        if (a == null) continue;
        if (a.syncStatus == SyncStatus.uploadFailed) {
          anyFailed = true;
          break;
        }
        if (a.cloudUuid != null && a.cloudUuid!.isNotEmpty && a.syncStatus == SyncStatus.synced) {
          uuids.add(a.cloudUuid!);
        }
      }

      if (anyFailed) throw Exception('部分媒体上传失败');
      if (uuids.length == assetIds.length) return uuids;
      await Future.delayed(interval);
    }
    throw Exception('等待媒体上传超时');
  }

  /// inputData: {
  ///   'groupUuid': String,
  ///   'content': String,
  ///   'assets': [ { localId, filePath, mediaType, mediaTakenAt(int ms) }, ... ],
  ///   'timeoutSeconds': int?
  /// }
  static Future<bool> run(Map<String, dynamic>? input) async {
    try {
      if (input == null) return false;

      final groupUuid = input['groupUuid'] as String;
      final content = (input['content'] as String?) ?? '';
      final jobId = (input['jobId'] as String?) ?? '';
      List rawAssets = const [];
      if (input['assets_json'] is String) {
        try {
          rawAssets = (jsonDecode(input['assets_json'] as String) as List?) ?? const [];
        } catch (e) {
          _log.warning('CreatePostRunner: decode assets_json failed: $e');
          rawAssets = const [];
        }
      } else if (input['assets'] is List) {
        // 兼容旧字段（若平台允许复杂类型）
        rawAssets = input['assets'] as List;
      }
      final timeoutSeconds = input['timeoutSeconds'] as int?;
      final timeout = Duration(seconds: timeoutSeconds ?? 1200);

      final db = getIt<AppDatabase>();
      final mediaAssetDao = db.mediaAssetDao;
      final postJobDao = db.postJobDao;
      final uploadService = getIt<BackupgroundUploadService>();
      final groupRepository = getIt<GroupRepository>();

      // 若无媒体，直接返回失败，避免请求400
      if (rawAssets.isEmpty) {
        _log.warning('CreatePostRunner: no assets provided, aborting');
        if (jobId.isNotEmpty) {
          await postJobDao.updateStatus(jobId, 'failed', message: '没有媒体资源');
        }
        return false;
      }

      if (jobId.isNotEmpty) {
        await postJobDao.updateStatus(jobId, 'preparing');
      }

      // 去重与入队
      final toUpload = <UploadFileInput>[];
      final waitIds = <String>[];
      final assetIdsAll = <String>[];

      for (final m in rawAssets) {
        final localId = (m['localId'] ?? '').toString();
        if (localId.isEmpty) continue;
        assetIdsAll.add(localId);

        final a = await mediaAssetDao.getAssetByLocalId(localId);
        if (a != null && a.cloudUuid != null && a.cloudUuid!.isNotEmpty && a.syncStatus == SyncStatus.synced) {
          // 已上传，直接复用
          continue;
        }

        if (a != null && a.syncStatus == SyncStatus.uploading) {
          waitIds.add(localId);
          continue;
        }

        final path = (m['filePath'] as String?) ?? '';
        final typeStr = (m['mediaType'] as String?) ?? 'image';
        final mediaType = MediaType.fromStringStrict(typeStr);
        final takenAtMs = (m['mediaTakenAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch;

        if (path.isEmpty) {
          throw Exception('资产缺少文件路径: $localId');
        }

        toUpload.add(UploadFileInput(
          file: File(path),
          assetId: localId,
          mediaType: mediaType,
          mediaTakenAt: DateTime.fromMillisecondsSinceEpoch(takenAtMs),
          source: UploadSource.post,
        ));
        waitIds.add(localId);
      }

      if (toUpload.isNotEmpty) {
        await uploadService.enqueueFromFiles(toUpload);
      }

      if (waitIds.isNotEmpty) {
        if (jobId.isNotEmpty) {
          await postJobDao.updateStatus(jobId, 'waiting_uploads');
        }
        await _waitForUuids(
          mediaAssetDao: mediaAssetDao,
          assetIds: waitIds,
          timeout: timeout,
        );
      }

      // 收集全部uuid
      final uuids = <String>[];
      for (final id in assetIdsAll) {
        final a = await mediaAssetDao.getAssetByLocalId(id);
        if (a?.cloudUuid == null || a!.cloudUuid!.isEmpty || a.syncStatus != SyncStatus.synced) {
          if (jobId.isNotEmpty) {
            await postJobDao.updateStatus(jobId, 'failed', message: '资源未就绪: $id');
          }
          throw Exception('资源未就绪: $id');
        }
        uuids.add(a.cloudUuid!);
      }

      if (jobId.isNotEmpty) {
        await postJobDao.updateStatus(jobId, 'creating_post');
      }
      await groupRepository.createPost(
        groupUuid: groupUuid,
        content: content,
        mediaUuids: uuids,
      );

      if (jobId.isNotEmpty) {
        await postJobDao.updateStatus(jobId, 'success', message: '发帖成功');
      }
      _log.info('CreatePostRunner: post created for group=$groupUuid');
      return true;
    } catch (e, s) {
      _log.severe('CreatePostRunner failed', e, s);
      final jobId = input?['jobId']?.toString() ?? '';
      if (jobId.isNotEmpty) {
        try {
          final db = getIt<AppDatabase>();
          final postJobDao = db.postJobDao;
          await postJobDao.updateStatus(jobId, 'failed', message: e.toString());
        } catch (_) {}
      }
      return false;
    }
  }
}


