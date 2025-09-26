// lib/features/background_jobs/impl/media_sync/models/sync_models.dart

import 'package:mobile/data/datasources/local_db/app_database.dart';

enum SyncCommand {
  triggerFullSync,
  triggerCloudSync,
  triggerLocalMediaChangeSync,
  dispose,
}

enum SyncStatus { idle, syncingLocal, syncingCloud, error }

/// 从 Isolate 发送回来的特定业务进度更新
class SyncProgressUpdate {
  final SyncStatus status;
  final String? message;
  SyncProgressUpdate(this.status, {this.message});
}

/// 云端同步器返回的结构化结果
class CloudSyncResult {
  /// 需要在本地数据库中新增或更新的媒体资源列表
  final List<MediaAssetsCompanion> toUpsert;

  /// 需要从本地数据库中删除的媒体资源的云端 UUID 列表
  final List<String> uuidsToDelete;

  CloudSyncResult({required this.toUpsert, required this.uuidsToDelete});
}

/// 本地对账任务的结果
class LocalReconciliationResult {
  final Set<String> newAssetIds;
  final Set<String> deletedAssetIds;
  final List<AlbumData> localAlbums;

  LocalReconciliationResult({
    required this.newAssetIds,
    required this.deletedAssetIds,
    required this.localAlbums,
  });
}

/// 用于在 Isolate 之间或模块之间传输的相册数据模型
class AlbumData {
  final String id;
  final String name;
  final int assetCount;

  AlbumData({required this.id, required this.name, required this.assetCount});
}
