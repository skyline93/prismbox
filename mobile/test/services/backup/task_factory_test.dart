// test/services/backup/task_factory_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/asset_type.dart';
import 'package:prismbox/data/database/enums/migration_status.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/infrastructure/asset/asset_path_resolver.dart';
import 'package:prismbox/services/backup/file_metadata_extractor.dart';
import 'package:prismbox/services/backup/task_factory.dart';

// Mock classes
class MockAssetPathResolver implements AssetPathResolver {
  final Map<String, String?> _pathMap = {};
  final AppDatabase? database;

  MockAssetPathResolver({this.database});

  void setPath(String assetId, String? path) {
    _pathMap[assetId] = path;
  }

  @override
  Future<String?> resolveAssetPath(LocalAssetEntityData asset) async {
    return _pathMap[asset.id];
  }

  @override
  Future<bool> validateFileExists(String path) async {
    final file = File(path);
    return await file.exists();
  }
}

class MockFileMetadataExtractor implements FileMetadataExtractor {
  final Map<String, int> _sizeMap = {};

  void setSize(String path, int size) {
    _sizeMap[path] = size;
  }

  @override
  Future<int> extractFileSize(String filePath) async {
    return _sizeMap[filePath] ?? 0;
  }
}

void main() {
  group('TaskFactory', () {
    late MockAssetPathResolver mockPathResolver;
    late MockFileMetadataExtractor mockMetadataExtractor;
    late TaskFactory taskFactory;

    setUp(() {
      mockPathResolver = MockAssetPathResolver();
      mockMetadataExtractor = MockFileMetadataExtractor();
      taskFactory = TaskFactory(
        pathResolver: mockPathResolver,
        metadataExtractor: mockMetadataExtractor,
      );
    });

    group('createTask', () {
      test('应该成功创建手动备份任务', () async {
        // Arrange
        final asset = LocalAssetEntityData(
          id: 'test_asset_id',
          name: 'test.jpg',
          type: AssetType.image,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isUploaded: false,
          path: '/path/to/test.jpg',
          isFavorite: false,
          orientation: 0,
          isInPrivateSpace: false,
          migrationStatus: MigrationStatus.none,
        );
        const userId = 'test_user_id';
        const remotePath = 'https://api.example.com/upload';
        const fileSize = 1024;

        mockPathResolver.setPath(asset.id, '/path/to/test.jpg');
        mockMetadataExtractor.setSize('/path/to/test.jpg', fileSize);

        // Act
        final task = await taskFactory.createTask(
          asset: asset,
          userId: userId,
          remotePath: remotePath,
          taskType: UploadTaskType.manual,
          priority: 1,
        );

        // Assert
        expect(task, isNotNull);
        expect(task!.userId, equals(userId));
        expect(task.assetId, equals(asset.id));
        expect(task.localPath, equals('/path/to/test.jpg'));
        expect(task.remotePath, equals(remotePath));
        expect(task.fileSize, equals(fileSize));
        expect(task.taskType, equals(UploadTaskType.manual));
        expect(task.priority, equals(1));
        expect(task.status, equals(UploadTaskStatus.pending));
        expect(task.id, startsWith('manual_'));
        expect(task.id, contains(asset.id));
      });

      test('应该成功创建自动备份任务', () async {
        // Arrange
        final asset = LocalAssetEntityData(
          id: 'test_asset_id',
          name: 'test.jpg',
          type: AssetType.image,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isUploaded: false,
          path: '/path/to/test.jpg',
          isFavorite: false,
          orientation: 0,
          isInPrivateSpace: false,
          migrationStatus: MigrationStatus.none,
        );
        const userId = 'test_user_id';
        const remotePath = 'https://api.example.com/upload';
        const fileSize = 2048;

        mockPathResolver.setPath(asset.id, '/path/to/test.jpg');
        mockMetadataExtractor.setSize('/path/to/test.jpg', fileSize);

        // Act
        final task = await taskFactory.createTask(
          asset: asset,
          userId: userId,
          remotePath: remotePath,
          taskType: UploadTaskType.auto,
          priority: 5,
        );

        // Assert
        expect(task, isNotNull);
        expect(task!.taskType, equals(UploadTaskType.auto));
        expect(task.priority, equals(5));
        expect(task.id, startsWith('auto_'));
      });

      test('应该返回null当文件路径无法解析时', () async {
        // Arrange
        final asset = LocalAssetEntityData(
          id: 'test_asset_id',
          name: 'test.jpg',
          type: AssetType.image,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isUploaded: false,
          path: '/path/to/test.jpg',
          isFavorite: false,
          orientation: 0,
          isInPrivateSpace: false,
          migrationStatus: MigrationStatus.none,
        );

        mockPathResolver.setPath(asset.id, null);

        // Act
        final task = await taskFactory.createTask(
          asset: asset,
          userId: 'test_user_id',
          remotePath: 'https://api.example.com/upload',
          taskType: UploadTaskType.manual,
          priority: 1,
        );

        // Assert
        expect(task, isNull);
      });

      test('应该返回null当文件路径为空时', () async {
        // Arrange
        final asset = LocalAssetEntityData(
          id: 'test_asset_id',
          name: 'test.jpg',
          type: AssetType.image,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isUploaded: false,
          path: '/path/to/test.jpg',
          isFavorite: false,
          orientation: 0,
          isInPrivateSpace: false,
          migrationStatus: MigrationStatus.none,
        );

        mockPathResolver.setPath(asset.id, '');

        // Act
        final task = await taskFactory.createTask(
          asset: asset,
          userId: 'test_user_id',
          remotePath: 'https://api.example.com/upload',
          taskType: UploadTaskType.manual,
          priority: 1,
        );

        // Assert
        expect(task, isNull);
      });
    });

    group('createTasks', () {
      test('应该批量创建任务', () async {
        // Arrange
        final assets = [
          LocalAssetEntityData(isUploaded: false, 
            id: 'asset1',
            name: 'test1.jpg',
            type: AssetType.image,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            path: '/path/to/test1.jpg',
            isFavorite: false,
            orientation: 0,
            isInPrivateSpace: false,
            migrationStatus: MigrationStatus.none,
          ),
          LocalAssetEntityData(isUploaded: false, 
            id: 'asset2',
            name: 'test2.jpg',
            type: AssetType.image,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            path: '/path/to/test2.jpg',
            isFavorite: false,
            orientation: 0,
            isInPrivateSpace: false,
            migrationStatus: MigrationStatus.none,
          ),
        ];

        for (final asset in assets) {
          mockPathResolver.setPath(asset.id, asset.path);
          mockMetadataExtractor.setSize(asset.path, 1024);
        }

        // Act
        final tasks = await taskFactory.createTasks(
          assets: assets,
          userId: 'test_user_id',
          remotePath: 'https://api.example.com/upload',
          taskType: UploadTaskType.manual,
          priority: 1,
        );

        // Assert
        expect(tasks.length, equals(2));
        expect(tasks[0].assetId, equals('asset1'));
        expect(tasks[1].assetId, equals('asset2'));
      });

      test('应该跳过无法创建的任务', () async {
        // Arrange
        final assets = [
          LocalAssetEntityData(isUploaded: false, 
            id: 'asset1',
            name: 'test1.jpg',
            type: AssetType.image,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            path: '/path/to/test1.jpg',
            isFavorite: false,
            orientation: 0,
            isInPrivateSpace: false,
            migrationStatus: MigrationStatus.none,
          ),
          LocalAssetEntityData(isUploaded: false, 
            id: 'asset2',
            name: 'test2.jpg',
            type: AssetType.image,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            path: '/path/to/test2.jpg',
            isFavorite: false,
            orientation: 0,
            isInPrivateSpace: false,
            migrationStatus: MigrationStatus.none,
          ),
        ];

        mockPathResolver.setPath(assets[0].id, '/path/to/test1.jpg');
        mockPathResolver.setPath(assets[1].id, null); // 第二个资产无法解析路径
        mockMetadataExtractor.setSize('/path/to/test1.jpg', 1024);

        // Act
        final tasks = await taskFactory.createTasks(
          assets: assets,
          userId: 'test_user_id',
          remotePath: 'https://api.example.com/upload',
          taskType: UploadTaskType.manual,
          priority: 1,
        );

        // Assert
        expect(tasks.length, equals(1));
        expect(tasks[0].assetId, equals('asset1'));
      });
    });
  });
}

