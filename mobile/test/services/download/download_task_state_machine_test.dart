// test/services/download/download_task_state_machine_test.dart

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prismbox/data/database/app_database.dart';
import 'package:prismbox/data/database/enums/download_task_status.dart';
import 'package:prismbox/data/database/enums/media_download_source_type.dart';
import 'package:prismbox/services/download/download_task_state_machine.dart';

void main() {
  group('DownloadTaskStateMachine', () {
    late AppDatabase database;
    late DownloadTaskStateMachine stateMachine;

    setUp(() async {
      database = AppDatabase(NativeDatabase.memory());
      stateMachine = DownloadTaskStateMachine(database: database);
    });

    tearDown(() async {
      await database.close();
    });

    group('canTransition', () {
      test('允许 pending -> queued', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.pending,
            DownloadTaskStatus.queued,
          ),
          isTrue,
        );
      });

      test('允许 queued -> downloading', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.queued,
            DownloadTaskStatus.downloading,
          ),
          isTrue,
        );
      });

      test('允许 downloading -> processing', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.downloading,
            DownloadTaskStatus.processing,
          ),
          isTrue,
        );
      });

      test('允许 processing -> completed', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.processing,
            DownloadTaskStatus.completed,
          ),
          isTrue,
        );
      });

      test('允许 downloading -> failed', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.downloading,
            DownloadTaskStatus.failed,
          ),
          isTrue,
        );
      });

      test('允许 failed -> queued (重试)', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.failed,
            DownloadTaskStatus.queued,
          ),
          isTrue,
        );
      });

      test('允许 pending -> cancelled', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.pending,
            DownloadTaskStatus.cancelled,
          ),
          isTrue,
        );
      });

      test('不允许 pending -> downloading (必须经过 queued)', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.pending,
            DownloadTaskStatus.downloading,
          ),
          isFalse,
        );
      });

      test('不允许 completed -> downloading (终态)', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.completed,
            DownloadTaskStatus.downloading,
          ),
          isFalse,
        );
      });

      test('相同状态允许（幂等操作）', () {
        expect(
          stateMachine.canTransition(
            DownloadTaskStatus.downloading,
            DownloadTaskStatus.downloading,
          ),
          isTrue,
        );
      });
    });

    group('transition', () {
      DownloadTaskEntityData createTask(DownloadTaskStatus status) {
        final now = DateTime.now();
        return DownloadTaskEntityData(
          id: 'test-dl-1',
          userId: 'test-user',
          sourceType: MediaDownloadSourceType.timeline_asset,
          sourceId: 'test-source',
          mediaUuid: 'media-uuid',
          livePhotoVideoUuid: null,
          filename: 'test.jpg',
          itemType: 'IMAGE',
          status: status,
          progress: 0,
          errorMessage: null,
          imageTempPath: null,
          videoTempPath: null,
          createdAt: now,
          updatedAt: now,
        );
      }

      test('pending -> queued 转换成功', () async {
        final task = createTask(DownloadTaskStatus.pending);
        await database.downloadTaskDao.insertTask(task);

        final updated = await stateMachine.transition(
          task,
          DownloadTaskStatus.queued,
        );

        expect(updated.status, DownloadTaskStatus.queued);
        final dbTask = await database.downloadTaskDao.getTaskById(task.id);
        expect(dbTask?.status, DownloadTaskStatus.queued);
      });

      test('processing -> completed 转换成功', () async {
        final task = createTask(DownloadTaskStatus.processing);
        await database.downloadTaskDao.insertTask(task);

        final updated = await stateMachine.transition(
          task,
          DownloadTaskStatus.completed,
        );

        expect(updated.status, DownloadTaskStatus.completed);
      });

      test('非法转换抛出 StateError', () async {
        final task = createTask(DownloadTaskStatus.pending);
        await database.downloadTaskDao.insertTask(task);

        expect(
          () => stateMachine.transition(task, DownloadTaskStatus.completed),
          throwsStateError,
        );
      });
    });
  });
}
