// lib/services/backup/upload_concurrency_controller.dart

import 'dart:async';
import 'package:synchronized/synchronized.dart';

/// 上传并发控制器
/// 
/// **设计原则**：
/// - **优先使用 background_downloader 的内置并发控制**：底层网络请求的并发控制由 background_downloader 管理
/// - **自定义并发控制器仅用于业务层面的优先级调度**：控制哪些任务可以进入执行队列
/// - **避免重复实现底层并发控制**：不在业务层重复实现网络层的并发控制
class UploadConcurrencyController {
  final Lock _lock = Lock();
  final int maxConcurrency;
  int _activeCount = 0;
  final List<Completer<void>> _waitingQueue = [];

  UploadConcurrencyController({
    this.maxConcurrency = 6,
  });

  /// 获取并发许可
  Future<void> acquire() async {
    await _lock.synchronized(() async {
      if (_activeCount < maxConcurrency) {
        _activeCount++;
        return;
      }

      // 等待可用位置
      final completer = Completer<void>();
      _waitingQueue.add(completer);
      await completer.future;
    });
  }

  /// 释放并发许可
  void release() {
    _lock.synchronized(() {
      if (_activeCount > 0) {
        _activeCount--;
      }

      // 唤醒等待的任务
      if (_waitingQueue.isNotEmpty && _activeCount < maxConcurrency) {
        final completer = _waitingQueue.removeAt(0);
        _activeCount++;
        completer.complete();
      }
    });
  }

  /// 执行任务（业务层并发控制）
  /// 
  /// **注意**：此控制器仅控制任务进入执行队列，实际网络请求的并发由 background_downloader 管理
  /// 
  /// **参数**：
  /// - [task] - 要执行的任务
  /// 
  /// **返回**：任务执行结果
  Future<T> execute<T>(Future<T> Function() task) async {
    await acquire();
    try {
      // 任务进入执行队列后，由 background_downloader 管理实际的网络并发
      return await task();
    } finally {
      release();
    }
  }

  /// 获取当前可用并发数
  int get availableConcurrency => maxConcurrency - _activeCount;

  /// 获取当前正在执行的任务数
  int get activeCount => _activeCount;
}

