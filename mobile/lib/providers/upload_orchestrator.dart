// lib/providers/upload_orchestrator.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile/domain/entities/unified_media_entity.dart';
import 'package:mobile/providers/transfer_providers.dart';
import 'package:photo_manager/photo_manager.dart';

class UploadTaskPayload {
  final File file;
  final String assetId;

  UploadTaskPayload({required this.file, required this.assetId});
}

final uploadOrchestratorProvider = Provider((ref) {
  return UploadOrchestrator(ref);
});

class UploadOrchestrator {
  final Ref _ref;

  UploadOrchestrator(this._ref);

  void processAndEnqueueUploads(List<UnifiedMediaEntity> entities) {
    _runBackgroundTask(entities).catchError((error, stackTrace) {
      debugPrint("后台上传准备任务失败: $error\n$stackTrace");
    });
  }

  Future<void> _runBackgroundTask(List<UnifiedMediaEntity> entities) async {
    final List<UploadTaskPayload> uploadTasks =
        await _prepareUploadTasksInMainIsolate(entities);

    if (uploadTasks.isEmpty) {
      debugPrint("后台任务：没有找到可上传的文件。");
      return;
    }

    final transferManager = _ref.read(transferManagerProvider);
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
          return UploadTaskPayload(file: file, assetId: asset.id);
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
