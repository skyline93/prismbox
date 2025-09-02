// lib/services/background_tasks/local_media_reconciliation.dart

import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

/// 用于在 Isolate 之间传输的相册数据模型。
class AlbumData {
  final String id;
  final String name;
  final int assetCount;

  AlbumData({required this.id, required this.name, required this.assetCount});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'assetCount': assetCount};

  factory AlbumData.fromJson(Map<String, dynamic> json) => AlbumData(
        id: json['id'] as String,
        name: json['name'] as String,
        assetCount: json['assetCount'] as int,
      );
}

/// 后台对账任务的结果。
class ReconciliationResult {
  final Set<String> newAssetIds;
  final Set<String> deletedAssetIds;
  final List<AlbumData> localAlbums;

  ReconciliationResult({
    required this.newAssetIds,
    required this.deletedAssetIds,
    required this.localAlbums,
  });

  Map<String, dynamic> toJson() => {
        'newAssetIds': newAssetIds.toList(),
        'deletedAssetIds': deletedAssetIds.toList(),
        'localAlbums': localAlbums.map((a) => a.toJson()).toList(),
      };

  factory ReconciliationResult.fromJson(Map<String, dynamic> json) =>
      ReconciliationResult(
        newAssetIds: (json['newAssetIds'] as List).cast<String>().toSet(),
        deletedAssetIds: (json['deletedAssetIds'] as List).cast<String>().toSet(),
        localAlbums: (json['localAlbums'] as List)
            .map((e) => AlbumData.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 在独立的 Isolate 中运行的后台对账函数。
@pragma('vm:entry-point')
Future<void> reconcileMediaInBackground(Map<String, dynamic> context) async {
  final SendPort port = context['port'];
  final Set<String> dbAssetIds =
      (context['dbAssetIds'] as List).cast<String>().toSet();

  if (kDebugMode) {
    print('[BackgroundReconcile] Starting background scan. Known assets from DB: ${dbAssetIds.length}');
  }

  final Set<String> deviceAssetIds = {};
  final List<AlbumData> albumList = [];

  try {
    final List<AssetPathEntity> paths =
        await PhotoManager.getAssetPathList(type: RequestType.common);

    if (kDebugMode) {
      print('[BackgroundReconcile] Found ${paths.length} asset paths (albums).');
    }

    for (final path in paths) {
      final int count = await path.assetCountAsync;
      if (kDebugMode) {
        print('[BackgroundReconcile] Scanning album "${path.name}" with $count assets.');
      }

      albumList.add(AlbumData(id: path.id, name: path.name, assetCount: count));

      if (count == 0) continue;

      const int pageSize = 200;
      final int pageCount = (count / pageSize).ceil();

      for (int i = 0; i < pageCount; i++) {
        final List<AssetEntity> assets =
            await path.getAssetListPaged(page: i, size: pageSize);
        for (final asset in assets) {
          deviceAssetIds.add(asset.id);
        }
      }
    }

    final newIds = deviceAssetIds.difference(dbAssetIds);
    final deletedIds = dbAssetIds.difference(deviceAssetIds);

    if (kDebugMode) {
      print('[BackgroundReconcile] Scan complete. Total device assets: ${deviceAssetIds.length}. New: ${newIds.length}, Deleted: ${deletedIds.length}.');
    }

    final result = ReconciliationResult(
      newAssetIds: newIds,
      deletedAssetIds: deletedIds,
      localAlbums: albumList,
    );

    port.send(result.toJson());
  } catch (e, s) {
    if (kDebugMode) {
      print('[BackgroundReconcile] CRITICAL ERROR during scan: $e\n$s');
    }
    port.send(ReconciliationResult(
      newAssetIds: {},
      deletedAssetIds: {},
      localAlbums: [],
    ).toJson());
  }
}
