// test/services/backup/upload_orchestrator_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/services/backup/models/live_photo_upload_metadata.dart';
import 'package:prismbox/services/backup/upload_orchestrator.dart';

void main() {
  group('UploadOrchestrator.applyLivePhotoVideoIdToFields', () {
    test('当任务为 Live Photo 图片任务且含 remoteVideoId 时，应在 fields 中写入 live_photo_video_id',
        () {
      final task = UploadTaskEntityData(
        id: 'task_1',
        userId: 'user_1',
        assetId: 'image_asset_1',
        localPath: '/path/to/image.jpg',
        remotePath: 'https://api/upload',
        fileSize: 1000,
        taskType: UploadTaskType.auto,
        priority: 5,
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        livePhotoMetadataJson: LivePhotoUploadMetadata(
          localAssetId: 'image_asset_1',
          isLivePhoto: true,
          part: LivePhotoTaskPart.image,
          remoteVideoId: 'remote-video-uuid-123',
        ).toJsonString(),
      );
      final fields = <String, String>{
        'item_type': 'image',
        'original_filename': 'photo.jpg',
      };

      UploadOrchestrator.applyLivePhotoVideoIdToFields(task, true, fields);

      expect(fields['live_photo_video_id'], equals('remote-video-uuid-123'));
    });

    test('当任务为视频部分或无 remoteVideoId 时，不应写入 live_photo_video_id', () {
      final task = UploadTaskEntityData(
        id: 'task_2',
        userId: 'user_1',
        assetId: 'video_asset_1',
        localPath: '/path/to/video.mov',
        remotePath: 'https://api/upload',
        fileSize: 2000,
        taskType: UploadTaskType.auto,
        priority: 5,
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        livePhotoMetadataJson: LivePhotoUploadMetadata(
          localAssetId: 'image_asset_1',
          isLivePhoto: true,
          part: LivePhotoTaskPart.video,
          remoteVideoId: null,
        ).toJsonString(),
      );
      final fields = <String, String>{'item_type': 'video'};

      UploadOrchestrator.applyLivePhotoVideoIdToFields(task, true, fields);

      expect(fields.containsKey('live_photo_video_id'), isFalse);
    });

    test('当 isImageAsset 为 false 时，不应写入 live_photo_video_id', () {
      final task = UploadTaskEntityData(
        id: 'task_3',
        userId: 'user_1',
        assetId: 'image_asset_1',
        localPath: '/path/to/image.jpg',
        remotePath: 'https://api/upload',
        fileSize: 1000,
        taskType: UploadTaskType.auto,
        priority: 5,
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        livePhotoMetadataJson: LivePhotoUploadMetadata(
          localAssetId: 'image_asset_1',
          isLivePhoto: true,
          part: LivePhotoTaskPart.image,
          remoteVideoId: 'remote-video-uuid-456',
        ).toJsonString(),
      );
      final fields = <String, String>{'item_type': 'image'};

      UploadOrchestrator.applyLivePhotoVideoIdToFields(task, false, fields);

      expect(fields.containsKey('live_photo_video_id'), isFalse);
    });

    test('当任务无 Live Photo 元数据时，不应写入 live_photo_video_id', () {
      final task = UploadTaskEntityData(
        id: 'task_4',
        userId: 'user_1',
        assetId: 'image_asset_1',
        localPath: '/path/to/image.jpg',
        remotePath: 'https://api/upload',
        fileSize: 1000,
        taskType: UploadTaskType.auto,
        priority: 5,
        status: UploadTaskStatus.pending,
        retryCount: 0,
        maxRetries: 3,
        progress: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        livePhotoMetadataJson: null,
      );
      final fields = <String, String>{'item_type': 'image'};

      UploadOrchestrator.applyLivePhotoVideoIdToFields(task, true, fields);

      expect(fields.containsKey('live_photo_video_id'), isFalse);
    });
  });

  group('UploadResult.displayAssetIdToUuid', () {
    test('UploadResult 可携带 displayAssetIdToUuid 映射', () {
      final displayAssetIdToUuid = <String, String>{
        'asset_1': 'uuid-1',
        'asset_2': 'uuid-2',
      };
      final result = UploadResult(
        successCount: 2,
        failedCount: 0,
        errors: [],
        mediaUuids: {'task_1': 'uuid-1', 'task_2': 'uuid-2'},
        displayAssetIdToUuid: displayAssetIdToUuid,
      );
      expect(result.displayAssetIdToUuid, isNotNull);
      expect(result.displayAssetIdToUuid!['asset_1'], equals('uuid-1'));
      expect(result.displayAssetIdToUuid!['asset_2'], equals('uuid-2'));
    });

    test('UploadResult 可不带 displayAssetIdToUuid', () {
      final result = UploadResult(
        successCount: 1,
        failedCount: 0,
        errors: [],
        mediaUuids: {'task_1': 'uuid-1'},
      );
      expect(result.displayAssetIdToUuid, isNull);
    });
  });
}
