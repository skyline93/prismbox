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


// 1. 创建一个 Provider 来全局访问我们的编排器服务
final uploadOrchestratorProvider = Provider((ref) {
  return UploadOrchestrator(ref);
});

// 2. 编排器服务类
class UploadOrchestrator {
  final Ref _ref;

  UploadOrchestrator(this._ref);

  /// UI层调用的唯一入口方法。
  /// 它会立即返回，并启动一个在后台运行的异步任务。
  void processAndEnqueueUploads(List<UnifiedMediaEntity> entities) {
    // 我们不在此处 `await`，而是让这个 Future 在后台独立运行。
    // 这就是实现“发射后不管”(fire-and-forget)的关键。
    _runBackgroundTask(entities).catchError((error, stackTrace) {
      // 集中处理后台任务中可能发生的任何未捕获的错误。
      // 在这里，你可以更新一个全局错误状态的Provider，或使用日志服务记录。
      debugPrint("后台上传准备任务失败: $error\n$stackTrace");
      // TODO: (可选) 向用户显示一个全局的、非阻塞的错误通知 (例如使用 toast/flushbar)。
    });
  }

  /// 真正的后台工作流在这里按顺序执行。
  Future<void> _runBackgroundTask(List<UnifiedMediaEntity> entities) async {
    // 步骤 1: 在主 Isolate 中并发地准备所有上传任务。
    // 我们不再使用 `compute`，而是利用 `Future.wait` 来高效处理 I/O 操作。
    final List<UploadTaskPayload> uploadTasks =
        await _prepareUploadTasksInMainIsolate(entities);

    // 如果没有找到有效的文件，则提前结束。
    if (uploadTasks.isEmpty) {
      debugPrint("后台任务：没有找到可上传的文件。");
      return;
    }

    // 步骤 2: 在主 Isolate 中执行数据库入队操作。
    final transferManager = _ref.read(transferManagerProvider);
    await transferManager.uploadService.enqueueMultipleJobs(uploadTasks);

    // 任务成功完成。
    debugPrint("后台任务：${uploadTasks.length} 个文件已成功加入上传队列。");

    // 可选：在这里可以触发相关状态的刷新，例如通知传输列表有更新。
  }

  /// 在主 Isolate 中处理所有平台通道调用，以准备上传负载。
  /// 使用 `Future.wait` 来并发获取文件，提高效率。
  Future<List<UploadTaskPayload>> _prepareUploadTasksInMainIsolate(
    List<UnifiedMediaEntity> entities,
  ) async {
    // 创建一个 Future 列表，每个 Future 负责处理一个实体。
    final List<Future<UploadTaskPayload?>> futures = entities.map((entity) async {
      try {
        AssetEntity? asset;
        if (entity.assetEntity != null) {
          asset = entity.assetEntity;
        } else if (entity.localId != null) {
          // 这个调用需要在主 Isolate 中进行
          asset = await AssetEntity.fromId(entity.localId!);
        }

        if (asset == null) {
          debugPrint('无法为实体 ${entity.id} 找到 AssetEntity，跳过上传。');
          return null;
        }

        // 这个调用也需要在主 Isolate 中进行
        final File? file = await asset.file;

        if (file != null) {
          return UploadTaskPayload(file: file, assetId: asset.id);
        } else {
          debugPrint('无法为 Asset ${asset.id} 获取文件，跳过上传。');
          return null;
        }
      } catch (e) {
        debugPrint('处理实体 ${entity.id} 时发生错误: $e');
        return null; // 确保即使有错误也能继续处理其他文件
      }
    }).toList();

    // 并发等待所有文件处理任务完成。
    final List<UploadTaskPayload?> results = await Future.wait(futures);

    // 过滤掉处理失败的（null）结果，并返回有效的任务列表。
    return results.whereType<UploadTaskPayload>().toList();
  }
}
