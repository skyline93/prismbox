// lib/features/background_jobs/core/contracts/isolate_task_handler.dart

import 'dart:isolate';

/// 所有在通用 Isolate 中运行的具体业务处理器都必须实现的抽象接口。
abstract class IsolateTaskHandler {
  /// 初始化处理器。可以在这里获取服务定位器中的依赖。
  /// [mainSendPort] 是用于向主 Isolate 发送消息的端口，某些高级用例可能需要。
  Future<void> initialize(SendPort mainSendPort);

  /// 执行具体的任务。
  /// [payload] 是从主 Isolate 传递过来的可选数据。
  /// 返回的结果将被自动发送回主 Isolate。
  Future<dynamic> handle(dynamic payload);

  /// 释放资源
  Future<void> dispose();
}
