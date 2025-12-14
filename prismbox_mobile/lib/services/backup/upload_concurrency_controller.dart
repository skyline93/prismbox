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
    while (true) {
      Completer<void>? completer;
      bool acquired = false;
      
      await _lock.synchronized(() {
        if (_activeCount < maxConcurrency) {
          _activeCount++;
          acquired = true;
          return;
        }

        // 需要等待，创建 completer 并添加到等待队列
        completer = Completer<void>();
        _waitingQueue.add(completer!);
      });
      
      // 如果已经获取到许可，直接返回
      if (acquired) {
        return;
      }
      
      // 如果需要等待，在锁外部等待（避免死锁）
      // 注意：被唤醒时，_activeCount 已经在 release() 中增加了，所以不需要再次增加
      if (completer != null) {
        await completer!.future;
        // 被唤醒后，直接返回（_activeCount 已经在 release() 中增加了）
        return;
      }
    }
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
        // 注意：completer.complete() 会立即唤醒等待的 Future
        // 但是我们需要确保在锁释放后，等待的 Future 能够继续执行
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

