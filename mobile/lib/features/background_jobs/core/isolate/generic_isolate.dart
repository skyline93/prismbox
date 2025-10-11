// lib/features/background_jobs/core/isolate/generic_isolate.dart

// ignore_for_file: avoid_print

import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/features/background_jobs/core/contracts/isolate_task_handler.dart';
import 'package:mobile/features/background_jobs/core/isolate/models.dart';
// IMPORT 您的具体业务 Handler
import 'package:mobile/features/background_jobs/impl/media_sync/domain/isolate_handler.dart';
import 'package:mobile/features/background_jobs/impl/auto_backup/domain/auto_backup_isolate_handler.dart';

final _log = Logger('GenericIsolate');

// ------------------- Isolate Entry Point -------------------
@pragma('vm:entry-point')
void genericIsolateEntrypoint(Map<String, dynamic> initialData) async {
  final mainSendPort = initialData['port'] as SendPort;
  final token = initialData['token'] as RootIsolateToken;

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print(
      '[Isolate:${record.level.name}] ${record.time}: ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      print('ERROR: ${record.error}');
    }
    if (record.stackTrace != null) {
      print('STACK TRACE: ${record.stackTrace}');
    }
  });

  final isolateReceivePort = ReceivePort();

  try {
    // 1. 初始化依赖注入
    await configureDependencies();
    _log.info('Dependencies configured inside GenericIsolate.');

    // 2. 注册所有可用的任务处理器
    // === [重要] 在这里注册您的新业务 Handler ===
    final Map<String, IsolateTaskHandler> handlers = {
      MediaSyncIsolateHandler.taskName: getIt<MediaSyncIsolateHandler>(),
      AutoBackupIsolateHandler.taskName: getIt<AutoBackupIsolateHandler>(),
      // 'videoTranscode': getIt<VideoTranscodeHandler>(), // 未来新增
    };

    // 3. 初始化所有 Handler
    for (final handler in handlers.values) {
      await handler.initialize(mainSendPort);
    }

    // 4. 设置命令监听器
    isolateReceivePort.listen((message) async {
      if (message is IsolateJob) {
        _log.info(
          'Received job: ${message.taskName}, requestId: ${message.requestId}',
        );
        final handler = handlers[message.taskName];

        if (handler != null) {
          try {
            // 发送 "正在运行" 状态 (可选)
            mainSendPort.send(
              IsolateJobResult(JobStatus.running, requestId: message.requestId),
            );

            // 执行任务
            final result = await handler.handle(message.payload);

            // 发送成功结果
            mainSendPort.send(
              IsolateJobResult(
                JobStatus.success,
                data: result,
                requestId: message.requestId,
              ),
            );
          } catch (e, s) {
            _log.severe('Error executing job ${message.taskName}', e, s);
            // 发送失败结果
            mainSendPort.send(
              IsolateJobResult(
                JobStatus.failure,
                data: e.toString(),
                requestId: message.requestId,
              ),
            );
          }
        } else {
          _log.warning('No handler found for task: ${message.taskName}');
          mainSendPort.send(
            IsolateJobResult(
              JobStatus.failure,
              data: 'Unknown task: ${message.taskName}',
              requestId: message.requestId,
            ),
          );
        }
      } else if (message == IsolateCommand.dispose) {
        _log.info('Received dispose command. Cleaning up...');
        for (final handler in handlers.values) {
          await handler.dispose();
        }
        isolateReceivePort.close();
      }
    });

    // 5. 准备就绪，向主 Isolate 发送 SendPort
    mainSendPort.send(isolateReceivePort.sendPort);
    _log.info('GenericIsolate is running and ready to receive jobs.');
  } catch (e, s) {
    _log.severe('Error during GenericIsolate initialization.', e, s);
    // 发生致命错误，无法继续
  }
}
