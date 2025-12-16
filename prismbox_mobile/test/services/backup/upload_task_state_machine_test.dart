// test/services/backup/upload_task_state_machine_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/upload_task_status.dart';
import 'package:prismbox/data/database/enums/upload_task_type.dart';
import 'package:prismbox/services/backup/upload_task_state_machine.dart';

void main() {
  group('UploadTaskStateMachine', () {
    late AppDatabase database;
    late UploadTaskStateMachine stateMachine;

    setUp(() async {
      // 使用内存数据库进行测试
      database = AppDatabase(NativeDatabase.memory());
      stateMachine = UploadTaskStateMachine(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    group('canTransition', () {
      test('允许 pending -> queued', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.pending,
            UploadTaskStatus.queued,
          ),
          isTrue,
        );
      });

      test('允许 queued -> uploading', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.queued,
            UploadTaskStatus.uploading,
          ),
          isTrue,
        );
      });

      test('允许 uploading -> completed', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.uploading,
            UploadTaskStatus.completed,
          ),
          isTrue,
        );
      });

      test('允许 uploading -> failed', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.uploading,
            UploadTaskStatus.failed,
          ),
          isTrue,
        );
      });

      test('允许 failed -> uploading (重试)', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.failed,
            UploadTaskStatus.uploading,
          ),
          isTrue,
        );
      });

      test('允许 pending -> cancelled', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.pending,
            UploadTaskStatus.cancelled,
          ),
          isTrue,
        );
      });

      test('不允许 pending -> uploading (必须经过 queued)', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.pending,
            UploadTaskStatus.uploading,
          ),
          isFalse,
        );
      });

      test('不允许 completed -> uploading (终态)', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.completed,
            UploadTaskStatus.uploading,
          ),
          isFalse,
        );
      });

      test('不允许 cancelled -> uploading (终态)', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.cancelled,
            UploadTaskStatus.uploading,
          ),
          isFalse,
        );
      });

      test('相同状态允许（幂等操作）', () {
        expect(
          stateMachine.canTransition(
            UploadTaskStatus.uploading,
            UploadTaskStatus.uploading,
          ),
          isTrue,
        );
      });
    });

    group('getAllowedTransitions', () {
      test('pending 允许转换到 queued 和 cancelled', () {
        final allowed = stateMachine.getAllowedTransitions(
          UploadTaskStatus.pending,
        );
        expect(allowed, contains(UploadTaskStatus.queued));
        expect(allowed, contains(UploadTaskStatus.cancelled));
        expect(allowed.length, 2);
      });

      test('queued 允许转换到 uploading、failed 和 cancelled', () {
        final allowed = stateMachine.getAllowedTransitions(
          UploadTaskStatus.queued,
        );
        expect(allowed, contains(UploadTaskStatus.uploading));
        expect(allowed, contains(UploadTaskStatus.failed));
        expect(allowed, contains(UploadTaskStatus.cancelled));
        expect(allowed.length, 3);
      });

      test('completed 不允许转换（终态）', () {
        final allowed = stateMachine.getAllowedTransitions(
          UploadTaskStatus.completed,
        );
        expect(allowed, isEmpty);
      });

      test('cancelled 不允许转换（终态）', () {
        final allowed = stateMachine.getAllowedTransitions(
          UploadTaskStatus.cancelled,
        );
        expect(allowed, isEmpty);
      });
    });

    group('transition', () {
      test('pending -> queued 转换成功', () async {
        // 创建测试任务
        final task = UploadTaskEntityData(
          id: 'test-task-1',
          userId: 'test-user',
          assetId: 'test-asset',
          localPath: '/test/path',
          remotePath: '/api/upload',
          fileSize: 1024,
          taskType: UploadTaskType.manual,
          priority: 1,
          status: UploadTaskStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          errorMessage: null,
          uploadedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          progress: 0,
        );

        // 插入任务
        await database.uploadTaskDao.insertTask(task);

        // 执行状态转换
        final updated = await stateMachine.transition(
          task,
          UploadTaskStatus.queued,
        );

        // 验证状态已更新
        expect(updated.status, UploadTaskStatus.queued);

        // 验证数据库中的状态
        final dbTask = await database.uploadTaskDao.getTaskById(task.id);
        expect(dbTask?.status, UploadTaskStatus.queued);
      });

      test('queued -> uploading 转换成功', () async {
        // 创建测试任务
        final task = UploadTaskEntityData(
          id: 'test-task-2',
          userId: 'test-user',
          assetId: 'test-asset',
          localPath: '/test/path',
          remotePath: '/api/upload',
          fileSize: 1024,
          taskType: UploadTaskType.manual,
          priority: 1,
          status: UploadTaskStatus.queued,
          retryCount: 0,
          maxRetries: 3,
          errorMessage: null,
          uploadedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          progress: 0,
        );

        // 插入任务
        await database.uploadTaskDao.insertTask(task);

        // 执行状态转换
        final updated = await stateMachine.transition(
          task,
          UploadTaskStatus.uploading,
        );

        // 验证状态已更新
        expect(updated.status, UploadTaskStatus.uploading);
      });

      test('uploading -> completed 转换成功并设置 uploadedAt', () async {
        // 创建测试任务
        final task = UploadTaskEntityData(
          id: 'test-task-3',
          userId: 'test-user',
          assetId: 'test-asset',
          localPath: '/test/path',
          remotePath: '/api/upload',
          fileSize: 1024,
          taskType: UploadTaskType.manual,
          priority: 1,
          status: UploadTaskStatus.uploading,
          retryCount: 0,
          maxRetries: 3,
          errorMessage: null,
          uploadedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          progress: 100,
        );

        // 插入任务
        await database.uploadTaskDao.insertTask(task);

        // 执行状态转换
        final updated = await stateMachine.transition(
          task,
          UploadTaskStatus.completed,
        );

        // 验证状态已更新
        expect(updated.status, UploadTaskStatus.completed);
        expect(updated.uploadedAt, isNotNull);
      });

      test('uploading -> failed 转换成功并设置错误信息', () async {
        // 创建测试任务
        final task = UploadTaskEntityData(
          id: 'test-task-4',
          userId: 'test-user',
          assetId: 'test-asset',
          localPath: '/test/path',
          remotePath: '/api/upload',
          fileSize: 1024,
          taskType: UploadTaskType.manual,
          priority: 1,
          status: UploadTaskStatus.uploading,
          retryCount: 0,
          maxRetries: 3,
          errorMessage: null,
          uploadedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          progress: 50,
        );

        // 插入任务
        await database.uploadTaskDao.insertTask(task);

        // 执行状态转换
        final updated = await stateMachine.transition(
          task,
          UploadTaskStatus.failed,
          errorMessage: 'Network error',
        );

        // 验证状态已更新
        expect(updated.status, UploadTaskStatus.failed);
        expect(updated.errorMessage, 'Network error');
      });

      test('非法转换抛出异常', () async {
        // 创建测试任务
        final task = UploadTaskEntityData(
          id: 'test-task-5',
          userId: 'test-user',
          assetId: 'test-asset',
          localPath: '/test/path',
          remotePath: '/api/upload',
          fileSize: 1024,
          taskType: UploadTaskType.manual,
          priority: 1,
          status: UploadTaskStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          errorMessage: null,
          uploadedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          progress: 0,
        );

        // 插入任务
        await database.uploadTaskDao.insertTask(task);

        // 尝试非法转换（pending -> uploading，必须经过 queued）
        expect(
          () => stateMachine.transition(
            task,
            UploadTaskStatus.uploading,
          ),
          throwsStateError,
        );
      });

      test('相同状态转换不更新数据库（幂等）', () async {
        // 创建测试任务
        final task = UploadTaskEntityData(
          id: 'test-task-6',
          userId: 'test-user',
          assetId: 'test-asset',
          localPath: '/test/path',
          remotePath: '/api/upload',
          fileSize: 1024,
          taskType: UploadTaskType.manual,
          priority: 1,
          status: UploadTaskStatus.uploading,
          retryCount: 0,
          maxRetries: 3,
          errorMessage: null,
          uploadedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          progress: 50,
        );

        // 插入任务
        await database.uploadTaskDao.insertTask(task);

        // 执行相同状态转换
        final updated = await stateMachine.transition(
          task,
          UploadTaskStatus.uploading,
        );

        // 验证状态未改变
        expect(updated.status, UploadTaskStatus.uploading);
      });
    });

    group('transitionBatch', () {
      test('批量转换成功', () async {
        // 创建多个测试任务
        final tasks = List.generate(
          3,
          (index) => UploadTaskEntityData(
            id: 'test-task-batch-$index',
            userId: 'test-user',
            assetId: 'test-asset-$index',
            localPath: '/test/path-$index',
            remotePath: '/api/upload',
            fileSize: 1024,
            taskType: UploadTaskType.manual,
            priority: 1,
            status: UploadTaskStatus.pending,
            retryCount: 0,
            maxRetries: 3,
            errorMessage: null,
            uploadedAt: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            progress: 0,
          ),
        );

        // 插入任务
        for (final task in tasks) {
          await database.uploadTaskDao.insertTask(task);
        }

        // 批量转换
        final updated = await stateMachine.transitionBatch(
          tasks,
          UploadTaskStatus.queued,
        );

        // 验证所有任务都已更新
        expect(updated.length, 3);
        for (final task in updated) {
          expect(task.status, UploadTaskStatus.queued);
        }
      });

      test('批量转换时部分失败不影响其他任务', () async {
        // 创建多个测试任务
        final validTask = UploadTaskEntityData(
          id: 'test-task-valid',
          userId: 'test-user',
          assetId: 'test-asset-valid',
          localPath: '/test/path-valid',
          remotePath: '/api/upload',
          fileSize: 1024,
          taskType: UploadTaskType.manual,
          priority: 1,
          status: UploadTaskStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          errorMessage: null,
          uploadedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          progress: 0,
        );

        final invalidTask = UploadTaskEntityData(
          id: 'test-task-invalid',
          userId: 'test-user',
          assetId: 'test-asset-invalid',
          localPath: '/test/path-invalid',
          remotePath: '/api/upload',
          fileSize: 1024,
          taskType: UploadTaskType.manual,
          priority: 1,
          status: UploadTaskStatus.pending,
          retryCount: 0,
          maxRetries: 3,
          errorMessage: null,
          uploadedAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          progress: 0,
        );

        // 只插入有效任务
        await database.uploadTaskDao.insertTask(validTask);

        // 批量转换（包含未插入的任务）
        final updated = await stateMachine.transitionBatch(
          [validTask, invalidTask],
          UploadTaskStatus.queued,
        );

        // 验证只有有效任务被更新
        expect(updated.length, 1);
        expect(updated.first.id, validTask.id);
        expect(updated.first.status, UploadTaskStatus.queued);
      });
    });
  });
}

