// lib/features/sync/synchronizers/cloud_media_synchronizer.dart

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/enums.dart';
import 'package:mobile/data/datasources/local_db/app_database.dart';
import 'package:mobile/data/datasources/remote_media_source.dart';
import 'package:mobile/data/models/media/media_model.dart';
import 'package:mobile/features/sync/models/sync_models.dart';

@injectable
class CloudMediaSynchronizer {
  final RemoteMediaDataSource _remoteApi;
  final _log = Logger('CloudMediaSynchronizer');

  CloudMediaSynchronizer(this._remoteApi);

  /// 执行云端同步检查。
  /// 从远程API获取变更，并将其转换为标准化的 `CloudSyncResult`。
  /// Logic migrated from `SyncJobProcessor._handleSyncCloudChangesJob`.
  Future<CloudSyncResult> run() async {
    _log.info('Fetching changes from remote API...');
    try {
      final MediaChangesResponse changes = await _remoteApi.getChanges();
      _log.info(
        'Received cloud changes: ${changes.created.length} created, ${changes.updated.length} updated, ${changes.deleted.length} deleted.',
      );

      final List<MediaAssetsCompanion> toUpsert = [];
      final allChangedMedia = [...changes.created, ...changes.updated];

      for (var media in allChangedMedia) {
        toUpsert.add(
          MediaAssetsCompanion(
            cloudUuid: Value(media.uuid),
            fileName: Value(media.originalFilename),
            assetType: Value(
              media.itemType.toUpperCase() == 'IMAGE'
                  ? MediaType.image
                  : MediaType.video,
            ),
            contentHash: Value(media.hash),
            createdAt: Value(DateTime.parse(media.createdAt)),
            updatedAt: Value(DateTime.parse(media.updatedAt)),
            // 默认为 cloudOnly，后续由 ActionHandler 的 applyCloudChanges 逻辑决定最终状态
            syncStatus: const Value(SyncStatus.cloudOnly),
          ),
        );
      }

      return CloudSyncResult(
        toUpsert: toUpsert,
        uuidsToDelete: changes.deleted,
      );
    } catch (e, s) {
      _log.severe('Failed to fetch or process cloud changes.', e, s);
      // 返回空结果以避免错误操作
      return CloudSyncResult(toUpsert: [], uuidsToDelete: []);
    }
  }
}
