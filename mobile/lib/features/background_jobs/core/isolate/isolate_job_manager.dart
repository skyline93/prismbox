import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/features/background_jobs/core/isolate/generic_isolate.dart';
import 'package:mobile/features/background_jobs/core/isolate/models.dart';
import 'package:uuid/uuid.dart';

/// 一个单例服务，管理应用内唯一的通用后台 Isolate。
@lazySingleton
class IsolateJobManager {
  final _log = Logger('IsolateJobManager');

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  final _mainReceivePort = ReceivePort();
  Completer<void> _isolateReadyCompleter = Completer<void>();
  bool _isStarting = false;

  // 暴露所有作业结果的广播流
  final _jobResultController = StreamController<IsolateJobResult>.broadcast();
  Stream<IsolateJobResult> get jobResultStream => _jobResultController.stream;

  /// 启动并初始化通用 Isolate。
  Future<void> start() async {
    if (_isolate != null) {
      return _isolateReadyCompleter.future;
    }
    if (_isStarting) {
      return _isolateReadyCompleter.future;
    }
    _isStarting = true;
    _log.info('Starting GenericIsolate...');

    if (_isolateReadyCompleter.isCompleted) {
      _isolateReadyCompleter = Completer<void>();
    }

    _mainReceivePort.listen(_handleMessagesFromIsolate);

    final token = RootIsolateToken.instance;
    if (token == null) {
      _log.severe('Failed to get RootIsolateToken.');
      _isStarting = false;
      return;
    }

    final isolateSetupData = {
      'port': _mainReceivePort.sendPort,
      'token': token,
    };

    try {
      _isolate = await Isolate.spawn(
        genericIsolateEntrypoint,
        isolateSetupData,
      );
      _log.info('Generic Isolate spawned successfully.');
    } catch (e, s) {
      _log.severe('Failed to spawn Generic Isolate.', e, s);
      _isolate = null;
    } finally {
      _isStarting = false;
    }

    return _isolateReadyCompleter.future;
  }

  /// 提交一个作业到 Isolate 执行。
  /// 返回一个唯一的 requestId。
  Future<String> submitJob(String taskName, {dynamic payload}) async {
    await start(); // 确保已启动
    await _isolateReadyCompleter.future; // 确保已就绪

    if (_isolateSendPort != null) {
      final requestId = const Uuid().v4();
      _log.info('Submitting job: $taskName, requestId: $requestId');
      _isolateSendPort!.send(
        IsolateJob(taskName, payload: payload, requestId: requestId),
      );
      return requestId;
    } else {
      _log.severe('Isolate communication channel is not available.');
      throw Exception('Isolate not connected');
    }
  }

  /// 便捷方法：提交作业并等待其完成，返回结果。
  Future<dynamic> executeJob(String taskName, {dynamic payload}) async {
    final requestId = await submitJob(taskName, payload: payload);

    // 监听结果流，找到对应 requestId 的成功或失败消息
    final result = await jobResultStream.firstWhere(
      (r) =>
          r.requestId == requestId &&
          (r.status == JobStatus.success || r.status == JobStatus.failure),
    );

    if (result.status == JobStatus.success) {
      return result.data;
    } else {
      throw Exception(result.data);
    }
  }

  /// 优雅地关闭 Isolate。
  @disposeMethod
  void dispose() {
    _log.info('Disposing IsolateJobManager...');
    if (_isolateSendPort != null) {
      _isolateSendPort!.send(IsolateCommand.dispose);
    }
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
    _jobResultController.close();
  }

  void _handleMessagesFromIsolate(dynamic message) {
    if (message is SendPort) {
      _isolateSendPort = message;
      if (!_isolateReadyCompleter.isCompleted) {
        _isolateReadyCompleter.complete();
      }
      _log.info(
        'Received SendPort from Generic Isolate. Communication established.',
      );
    } else if (message is IsolateJobResult) {
      _jobResultController.add(message);
      _log.fine(
        'Received job result: ${message.status.name}, requestId: ${message.requestId}',
      );
    } else {
      _log.warning('Received unknown message type from Isolate: $message');
    }
  }
}
