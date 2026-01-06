// lib/utils/async_mutex.dart

import 'dart:async';

/// Async mutex to guarantee actions are performed sequentially and do not interleave
/// 
/// 确保操作顺序执行，不会交错
/// 参考: Immich Mobile (immich_mobile/lib/utils/async_mutex.dart)
class AsyncMutex {
  /// 当前正在运行的任务链
  Future _running = Future.value(null);
  
  /// 队列中的任务数量（包括正在运行的）
  int _enqueued = 0;

  /// 获取队列中的任务数量
  int get enqueued => _enqueued;

  /// 执行操作（独占执行）
  /// 
  /// 如果有操作正在运行，会等待完成后执行
  /// 
  /// [operation] 要执行的操作
  /// 返回操作的结果
  Future<T> run<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _enqueued++;
    
    // 当前任务完成后，执行新任务
    _running.whenComplete(() {
      _enqueued--;
      completer.complete(Future<T>.sync(operation));
    });
    
    // 更新运行链
    return _running = completer.future;
  }
}

