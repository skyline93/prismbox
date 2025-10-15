// lib/providers/upload_orchestrator.dart

import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/extensions/asset_type_extensions.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/services/transfer/transfer_manager.dart';

class UploadTaskPayload {
  final File file;
  final String assetId;
  final MediaType mediaType;

  UploadTaskPayload({
    required this.file,
    required this.assetId,
    required this.mediaType,
  });
}

@injectable
class UploadOrchestrator {
  UploadOrchestrator();

  Future<void> processAndEnqueueUploads(
    List<UnifiedMediaEntity> entities,
  ) async {
    try {
      await _runBackgroundTask(entities);
    } catch (error, stackTrace) {
      debugPrint("后台上传准备任务失败: $error\n$stackTrace");
      // 你可能希望在这里重新抛出异常，以便调用方可以捕获它
      rethrow;
    }
  }

  Future<void> _runBackgroundTask(List<UnifiedMediaEntity> entities) async {
    final List<UploadTaskPayload> uploadTasks =
        await _prepareUploadTasksInMainIsolate(entities);

    if (uploadTasks.isEmpty) {
      debugPrint("后台任务：没有找到可上传的文件。");
      return;
    }

    // final uploadService = getIt<UploadService>();
    final transferManager = getIt<TransferManager>();
    await transferManager.uploadService.enqueueMultipleJobs(uploadTasks);

    debugPrint("后台任务：${uploadTasks.length} 个文件已成功加入上传队列。");

    // 可选：在这里可以触发相关状态的刷新，例如通知传输列表有更新。
  }

  /// 在主 Isolate 中处理所有平台通道调用，以准备上传负载。
  /// 使用 `Future.wait` 来并发获取文件，提高效率。
  Future<List<UploadTaskPayload>> _prepareUploadTasksInMainIsolate(
    List<UnifiedMediaEntity> entities,
  ) async {
    final List<Future<UploadTaskPayload?>> futures = entities.map((
      entity,
    ) async {
      try {
        AssetEntity? asset;
        if (entity.assetEntity != null) {
          asset = entity.assetEntity;
        } else if (entity.localId != null) {
          asset = await AssetEntity.fromId(entity.localId!);
        }

        if (asset == null) {
          debugPrint('无法为实体 ${entity.id} 找到 AssetEntity，跳过上传。');
          return null;
        }

        final File? file = await asset.originFile;

        if (file != null) {
          return UploadTaskPayload(
            file: file,
            assetId: asset.id,
            mediaType: asset.type.toMediaType(),
          );
        } else {
          debugPrint('无法为 Asset ${asset.id} 获取文件，跳过上传。');
          return null;
        }
      } catch (e) {
        debugPrint('处理实体 ${entity.id} 时发生错误: $e');
        return null;
      }
    }).toList();

    final List<UploadTaskPayload?> results = await Future.wait(futures);

    return results.whereType<UploadTaskPayload>().toList();
  }
}
