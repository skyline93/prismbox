import 'dart:isolate';
import 'package:injectable/injectable.dart';
import 'package:logging/logging.dart';
import 'package:mobile/features/background_jobs/core/contracts/isolate_task_handler.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/domain/orchestrator.dart';
import 'package:mobile/features/background_jobs/impl/media_sync/models/sync_models.dart';

/// 在 Isolate 中处理媒体同步任务的处理器。
@injectable
class MediaSyncIsolateHandler implements IsolateTaskHandler {
  static const String taskName = 'mediaSync';
  final _log = Logger('MediaSyncIsolateHandler');
  final MediaSyncOrchestrator _orchestrator;

  MediaSyncIsolateHandler(this._orchestrator);

  @override
  Future<void> initialize(SendPort mainSendPort) async {
    _log.info('Initializing MediaSyncIsolateHandler...');
    // 将 mainSendPort 传递给 orchestrator，使其可以向主 Isolate 发送进度状态
    _orchestrator.setMainSendPort(mainSendPort);
  }

  @override
  Future<dynamic> handle(dynamic payload) async {
    _log.info('Handling media sync payload: $payload');
    if (payload is String) {
      final command = SyncCommand.values.firstWhere(
        (e) => e.name == payload,
        orElse: () => SyncCommand.triggerFullSync,
      );
      _orchestrator.handleCommand(command);
      return 'Command executed: ${command.name}';
    }
    return 'Unknown payload';
  }

  @override
  Future<void> dispose() async {
    // 清理逻辑
  }
}
