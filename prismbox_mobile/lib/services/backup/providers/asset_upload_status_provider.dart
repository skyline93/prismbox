// lib/services/backup/providers/asset_upload_status_provider.dart

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:prismbox/features/backup/models/asset_upload_status.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/daos/upload_task_dao.dart';
import 'package:prismbox/data/database/daos/remote_asset_dao.dart';
import 'package:prismbox/data/database/daos/local_asset_dao.dart';
import 'package:prismbox/providers/infrastructure/database_provider.dart' as infra;

part 'asset_upload_status_provider.g.dart';

final _logger = Logger('AssetUploadStatusProvider');

/// 资产上传状态 Provider
/// 
/// **⚠️ 架构问题：此接口负担过重**
/// 
/// 此 Provider 承担了过多职责，包括：
/// 1. 查询上传任务状态（upload_task_entity 表）
/// 2. 查询远程资产表（remote_asset_entity 表）
/// 3. 查询本地资产表（local_asset_entity 表，用于获取 checksum）
/// 4. 同时监听多个数据源的变化
/// 5. 合并多个数据源的状态判断逻辑
/// 6. 处理状态去重和错误处理
/// 
/// **建议重构方向**：
/// - 将状态判断逻辑提取到独立的 Service 层
/// - 使用组合模式，将不同数据源的查询分离
/// - 考虑使用 StateNotifier 替代 StreamProvider，提供更细粒度的控制
/// - 将状态合并逻辑提取为独立的函数或类
/// 
/// **当前实现说明**：
/// 根据资产查询上传状态，结合数据库和任务状态
/// 使用唯一标识符（assetId）作为 family 参数，确保每个资产有独立的 Provider 实例
/// 使用 StreamProvider 实现实时状态更新，避免状态闪烁
/// 
/// **优化措施**：
/// - 使用唯一标识符作为 family 参数，避免对象相等性比较问题
/// - 先查询初始值，避免 Stream 先返回 null 导致的闪烁
/// - 状态去重，只在状态真正改变时才 yield
/// - 同时监听上传任务表和远程资产表，确保状态实时更新
/// 
/// **参数**：
/// - [assetId] - 资产的唯一标识符（localId 或 id）
/// - [hasRemote] - 资产是否有远程版本（用于快速判断已上传状态，但不作为唯一依据）
/// - [checksum] - 资产的 checksum（可选，用于查询远程资产表）
/// 
/// **状态判断逻辑（优先级顺序）**：
/// 1. 优先查询上传任务状态（最可靠的数据源）
/// 2. 如果没有任务记录，查询远程资产表（通过 checksum）
/// 3. 如果 hasRemote == true，也显示已上传（快速路径，但不作为唯一依据）
/// 4. 否则显示未上传
@riverpod
Stream<AssetUploadStatusInfo> assetUploadStatus(
  AssetUploadStatusRef ref,
  String assetId, // 使用唯一标识符作为 family 参数
  bool hasRemote, // 资产是否有远程版本
  String? checksum, // 资产的 checksum（用于查询远程资产表）
) async* {
  final database = await ref.watch(infra.databaseProvider.future);
  final uploadDao = UploadTaskDao(database);
  final remoteDao = RemoteAssetDao(database);
  final localDao = LocalAssetDao(database);
  
  // 1. 如果没有传入 checksum，从本地资产表查询
  String? assetChecksum = checksum;
  if (assetChecksum == null || assetChecksum.isEmpty) {
    final localAsset = await localDao.getAssetById(assetId);
    assetChecksum = localAsset?.checksum;
  }
  
  // 缓存 checksum 用于后续使用（避免重复检查 null）
  final hasChecksum = assetChecksum != null && assetChecksum.isNotEmpty;
  // 用于需要非空 String 的地方（仅在 hasChecksum 为 true 时使用）
  // 注意：当 hasChecksum 为 true 时，assetChecksum 一定不为 null
  final checksumValue = hasChecksum ? assetChecksum : '';
  
  // 2. 如果 hasRemote == true，先快速返回已上传状态
  // 但继续监听，以防状态变化
  // 注意：hasRemote 可能为 false，但远程资产表可能有数据，所以不能直接 return
  if (hasRemote) {
    yield const AssetUploadStatusInfo(
      status: AssetUploadStatus.uploaded,
    );
  }
  
  // 3. 查询初始状态
  AssetUploadStatusInfo? lastStatus;
  
  // 3.1 优先查询上传任务状态
  final initialTask = await uploadDao.getTaskByLocalAssetId(assetId);
  if (initialTask != null) {
    lastStatus = _getStatusFromTask(initialTask);
    yield lastStatus;
  } else {
    // 3.2 如果没有任务记录，检查远程资产表
    if (hasChecksum) {
      final remoteAsset = await remoteDao.getAssetByChecksum(checksumValue);
      if (remoteAsset != null) {
        lastStatus = const AssetUploadStatusInfo(
          status: AssetUploadStatus.uploaded,
        );
        yield lastStatus;
      } else if (hasRemote) {
        // 3.3 如果 hasRemote == true，显示已上传
        lastStatus = const AssetUploadStatusInfo(
          status: AssetUploadStatus.uploaded,
        );
        yield lastStatus;
      } else {
        lastStatus = const AssetUploadStatusInfo(
          status: AssetUploadStatus.notUploaded,
        );
        yield lastStatus;
      }
    } else if (hasRemote) {
      lastStatus = const AssetUploadStatusInfo(
        status: AssetUploadStatus.uploaded,
      );
      yield lastStatus;
    } else {
      lastStatus = const AssetUploadStatusInfo(
        status: AssetUploadStatus.notUploaded,
      );
      yield lastStatus;
    }
  }
  
  // 4. 同时监听上传任务和远程资产表的变化
  // 使用 StreamController 来合并两个流
  final statusController = StreamController<AssetUploadStatusInfo>();
  StreamSubscription? taskSubscription;
  StreamSubscription? remoteSubscription;
  
  // 4.1 监听上传任务变化
  taskSubscription = uploadDao.watchTaskByLocalAssetId(assetId).listen(
    (task) async {
      AssetUploadStatusInfo newStatus;
      
      if (task != null) {
        // 任务存在，使用任务状态
        newStatus = _getStatusFromTask(task);
      } else {
        // 任务不存在，检查远程资产表
        if (hasChecksum) {
          final remoteAsset = await remoteDao.getAssetByChecksum(checksumValue);
          if (remoteAsset != null) {
            newStatus = const AssetUploadStatusInfo(
              status: AssetUploadStatus.uploaded,
            );
          } else if (hasRemote) {
            newStatus = const AssetUploadStatusInfo(
              status: AssetUploadStatus.uploaded,
            );
          } else {
            newStatus = const AssetUploadStatusInfo(
              status: AssetUploadStatus.notUploaded,
            );
          }
        } else if (hasRemote) {
          newStatus = const AssetUploadStatusInfo(
            status: AssetUploadStatus.uploaded,
          );
        } else {
          newStatus = const AssetUploadStatusInfo(
            status: AssetUploadStatus.notUploaded,
          );
        }
      }
      
      if (!statusController.isClosed) {
        statusController.add(newStatus);
      }
    },
    onError: (error) {
      // 错误处理：如果监听失败，保持当前状态
      _logger.warning('监听上传任务状态失败: $assetId', error);
    },
  );
  
  // 4.2 监听远程资产表变化（仅在 checksum 存在时）
  if (hasChecksum) {
    remoteSubscription = remoteDao.watchAssetByChecksum(checksumValue).listen(
      (remoteAsset) async {
        AssetUploadStatusInfo newStatus;
        
        if (remoteAsset != null) {
          // 远程资产存在，检查任务状态
          final task = await uploadDao.getTaskByLocalAssetId(assetId);
          if (task != null) {
            // 优先使用任务状态
            newStatus = _getStatusFromTask(task);
          } else {
            // 任务不存在，但远程资产存在，显示已上传
            newStatus = const AssetUploadStatusInfo(
              status: AssetUploadStatus.uploaded,
            );
          }
        } else {
          // 远程资产不存在，检查任务状态
          final task = await uploadDao.getTaskByLocalAssetId(assetId);
          if (task != null) {
            newStatus = _getStatusFromTask(task);
          } else if (hasRemote) {
            newStatus = const AssetUploadStatusInfo(
              status: AssetUploadStatus.uploaded,
            );
          } else {
            newStatus = const AssetUploadStatusInfo(
              status: AssetUploadStatus.notUploaded,
            );
          }
        }
        
        if (!statusController.isClosed) {
          statusController.add(newStatus);
        }
      },
      onError: (error) {
        // 错误处理：如果监听失败，保持当前状态
        _logger.warning('监听远程资产状态失败: $assetId', error);
      },
    );
  }
  
  // 5. 监听合并后的状态流，并去重
  await for (final newStatus in statusController.stream) {
    // 只有在状态真正改变时才 yield（避免重复更新导致的抖动）
    if (lastStatus?.status != newStatus.status ||
        lastStatus?.progress != newStatus.progress) {
      lastStatus = newStatus;
      yield newStatus;
    }
  }
  
  // 6. 清理资源（当 provider 被销毁时）
  await taskSubscription.cancel();
  await remoteSubscription?.cancel();
  await statusController.close();
}

/// 根据任务状态转换为资产上传状态信息
/// 
/// **参数**：
/// - [task] - 上传任务实体（类型由 Drift 生成，在 app_database.g.dart 中定义）
/// 
/// **注意**：UploadTaskEntityData 类型由 Drift 代码生成器自动生成。
/// 如果遇到类型错误，请运行 `dart run build_runner build` 重新生成代码。
AssetUploadStatusInfo _getStatusFromTask(dynamic task) {
  // 类型安全：task 的实际类型是 UploadTaskEntityData（由 Drift 生成）
  // 但由于代码生成时机问题，暂时使用 dynamic
  switch (task.status) {
    case UploadTaskStatus.uploading:
      // 上传中，计算进度（0.0 - 1.0）
      final progress = task.progress / 100.0;
      return AssetUploadStatusInfo(
        status: AssetUploadStatus.uploading,
        progress: progress.clamp(0.0, 1.0),
      );
    case UploadTaskStatus.queued:
    case UploadTaskStatus.pending:
      // pending/queued 状态显示为上传中（但进度为0）
      // 这样用户可以看到任务已经创建并等待执行
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.uploading,
        progress: 0.0,
      );
    case UploadTaskStatus.failed:
    case UploadTaskStatus.permanentlyFailed:
      // 上传失败
      return AssetUploadStatusInfo(
        status: AssetUploadStatus.failed,
        errorMessage: task.errorMessage,
      );
    case UploadTaskStatus.completed:
      // 已完成但 remoteAssetId 为空，可能是数据不一致
      // 显示为已上传（后续需要修复数据）
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.uploaded,
      );
    case UploadTaskStatus.paused:
      // 暂停状态，显示为上传中（用户可能继续上传）
      final progress = task.progress / 100.0;
      return AssetUploadStatusInfo(
        status: AssetUploadStatus.uploading,
        progress: progress.clamp(0.0, 1.0),
      );
    case UploadTaskStatus.cancelled:
      // 已取消，显示为未上传
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.notUploaded,
      );
    default:
      // 未知状态，显示为未上传
      return const AssetUploadStatusInfo(
        status: AssetUploadStatus.notUploaded,
      );
  }
}

