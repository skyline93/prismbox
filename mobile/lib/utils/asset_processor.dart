// lib/utils/asset_processor.dart

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// 一个并发任务处理器，用于并行处理资产。
class AssetProcessor {
  final Future<void> Function(String id) processFunction;
  final int workerCount;
  final Queue<String> _queue = Queue<String>();
  final List<Future<void>> _workers = [];
  bool _isDisposed = false;

  AssetProcessor({required this.processFunction, this.workerCount = 4}) {
    _startWorkers();
  }

  void _startWorkers() {
    for (int i = 0; i < workerCount; i++) {
      _workers.add(_runWorker(i));
    }
  }

  void add(String id) {
    if (!_isDisposed) {
      _queue.add(id);
    }
  }

  void addAll(Iterable<String> ids) {
    if (!_isDisposed) {
      _queue.addAll(ids);
    }
  }

  Future<void> _runWorker(int workerId) async {
    if (kDebugMode) {
      print('[AssetProcessor] Worker $workerId started.');
    }
    while (!_isDisposed) {
      if (_queue.isNotEmpty) {
        final String assetId = _queue.removeFirst();
        try {
          await processFunction(assetId);
        } catch (e, s) {
          if (kDebugMode) {
            print('[AssetProcessor] Worker $workerId failed to process $assetId: $e\n$s');
          }
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    if (kDebugMode) {
      print('[AssetProcessor] Worker $workerId stopped.');
    }
  }

  void dispose() {
    _isDisposed = true;
  }
}
